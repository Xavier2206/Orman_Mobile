import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extensions.dart';
import '../../../app/theme/orman_semantic_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/payments/presentation/installment_detail_page.dart';
import '../../../shared/widgets/orman_buttons.dart';
import '../../../shared/widgets/orman_card.dart';
import '../../../shared/widgets/orman_page_background.dart';
import '../../../shared/widgets/orman_status_badge.dart';
import '../data/notification_api.dart';
import '../data/notification_refresh_signal.dart';
import '../models/tenant_notification.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    required this.apiClient,
    required this.onUnreadCountChanged,
    this.refreshSignal,
    super.key,
  });

  final ApiClient apiClient;
  final ValueChanged<int> onUnreadCountChanged;
  final NotificationRefreshSignal? refreshSignal;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationApi _api = NotificationApi(widget.apiClient);
  final List<TenantNotification> _items = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _nextPage = 0;
  String? _error;
  bool _refreshing = false;
  bool _refreshPending = false;

  @override
  void initState() {
    super.initState();
    widget.refreshSignal?.addListener(_onRefreshRequested);
    unawaited(_load(reset: true));
    unawaited(_refreshSummary());
  }

  @override
  void didUpdateWidget(covariant NotificationsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      oldWidget.refreshSignal?.removeListener(_onRefreshRequested);
      widget.refreshSignal?.addListener(_onRefreshRequested);
    }
  }

  Future<void> _load({required bool reset}) async {
    if (_loadingMore || _loading) {
      if (reset) _refreshPending = true;
      return;
    }
    final page = reset ? 0 : _nextPage;
    setState(() {
      if (reset && _items.isEmpty) _loading = true;
      if (!reset) _loadingMore = true;
      if (reset) _error = null;
    });
    try {
      final result = await _api.list(page: page);
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(result.content);
        _hasMore = !result.last;
        _nextPage = result.page + 1;
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() {
          if (reset) _loading = false;
          _loadingMore = false;
        });
        _runPendingRefreshIfReady();
      }
    }
  }

  void _onRefreshRequested() {
    if (widget.refreshSignal?.isAuthenticated != true || !mounted) return;
    unawaited(_refreshFromBackend());
  }

  Future<void> _refreshFromBackend() async {
    if (!mounted || widget.refreshSignal?.isAuthenticated != true) return;
    if (_refreshing) {
      _refreshPending = true;
      return;
    }

    _refreshing = true;
    if (_loading || _loadingMore) {
      _refreshPending = true;
    } else {
      await _load(reset: true);
    }
    await _refreshSummary();
    _refreshing = false;
    _runPendingRefreshIfReady();
  }

  void _runPendingRefreshIfReady() {
    if (!_refreshPending ||
        _refreshing ||
        _loading ||
        _loadingMore ||
        !mounted ||
        widget.refreshSignal?.isAuthenticated != true) {
      return;
    }
    _refreshPending = false;
    unawaited(_refreshFromBackend());
  }

  Future<void> _refreshSummary() async {
    if (widget.refreshSignal != null &&
        !widget.refreshSignal!.isAuthenticated) {
      return;
    }
    try {
      final summary = await _api.getSummary();
      if (mounted &&
          (widget.refreshSignal == null ||
              widget.refreshSignal!.isAuthenticated)) {
        widget.onUnreadCountChanged(summary.unreadCount);
      }
    } on Object {
      // Mantiene el contador anterior si el resumen no está disponible.
    }
  }

  Future<void> _openNotification(TenantNotification item) async {
    TenantNotification current = item;
    try {
      current = await _api.get(item.code);
      if (!current.isRead) {
        current = await _api.markRead(item.code);
        _replace(current);
        await _refreshSummary();
      }
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      return;
    }

    if (!mounted) return;
    if (current.referenceType?.toUpperCase() == 'CUOTA' &&
        current.referenceId != null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => InstallmentDetailPage(
            apiClient: widget.apiClient,
            installmentCode: current.referenceId!,
          ),
        ),
      );
      await _load(reset: true);
      await _refreshSummary();
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(current.title),
        content: SingleChildScrollView(child: Text(current.message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _replace(TenantNotification notification) {
    final index = _items.indexWhere((item) => item.code == notification.code);
    if (index < 0 || !mounted) return;
    setState(() => _items[index] = notification);
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_onRefreshRequested);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.ormanColors;
    return OrmanPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Notificaciones'),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            if (widget.refreshSignal?.isAuthenticated == true) {
              await _refreshFromBackend();
            } else {
              await Future.wait([_load(reset: true), _refreshSummary()]);
            }
          },
          child: ListView(
            key: const Key('tenant-notification-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x4,
              AppSpacing.x2,
              AppSpacing.x4,
              AppSpacing.x6,
            ),
            children: [
              if (_loading && _items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.x8),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              else if (_error != null && _items.isEmpty)
                OrmanCard(
                  child: Column(
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.x3),
                      OrmanSecondaryButton(
                        label: 'Reintentar',
                        icon: Icons.refresh,
                        onPressed: () => _load(reset: true),
                      ),
                    ],
                  ),
                )
              else if (_items.isEmpty)
                OrmanCard(
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 36,
                        color: colors.textMuted,
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      Text(
                        'No tienes notificaciones.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                )
              else ...[
                for (final item in _items) ...[
                  _NotificationCard(
                    item: item,
                    onTap: () => _openNotification(item),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.x2,
                    ),
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textFor(OrmanSemanticRole.danger),
                      ),
                    ),
                  ),
                if (_hasMore)
                  Center(
                    child: TextButton.icon(
                      onPressed: _loadingMore
                          ? null
                          : () => _load(reset: false),
                      icon: _loadingMore
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.expand_more),
                      label: Text(_loadingMore ? 'Cargando…' : 'Cargar más'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final TenantNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.ormanColors;
    return Semantics(
      button: true,
      label: '${item.isRead ? 'Leída' : 'No leída'}: ${item.title}',
      child: OrmanCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.x1),
                  child: Icon(
                    item.isRead
                        ? Icons.mark_email_read_outlined
                        : Icons.mark_email_unread_outlined,
                    color: item.isRead ? colors.textMuted : colors.info,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: item.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w800,
                              ),
                            ),
                          ),
                          if (!item.isRead)
                            const OrmanStatusBadge(
                              label: 'Nueva',
                              role: OrmanSemanticRole.info,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Text(item.message, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: AppSpacing.x2),
                      Text(
                        Formatters.dateTime(item.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                      if (item.referenceType?.toUpperCase() == 'CUOTA') ...[
                        const SizedBox(height: AppSpacing.x1),
                        Text(
                          'Ver cuota',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _friendlyError(Object error) => error is ApiException
    ? error.detail
    : error is FormatException
    ? error.message
    : 'No se pudo cargar la información. Inténtalo nuevamente.';
