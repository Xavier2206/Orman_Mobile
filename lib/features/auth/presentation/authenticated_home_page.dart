import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extensions.dart';
import '../../../app/theme/orman_theme_controller.dart';
import '../../../core/auth/session_manager.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/contracts/data/contract_api.dart';
import '../../../features/contracts/models/tenant_contract.dart';
import '../../../features/contracts/models/portal_status.dart';
import '../../../features/contracts/presentation/contract_detail_page.dart';
import '../../../features/notifications/data/notification_api.dart';
import '../../../features/notifications/presentation/notifications_page.dart';
import '../../../features/auth/data/models/auth_context.dart';
import '../../../shared/widgets/orman_buttons.dart';
import '../../../shared/widgets/orman_card.dart';
import '../../../shared/widgets/orman_page_background.dart';
import '../../../shared/widgets/orman_status_badge.dart';
import '../../../shared/widgets/orman_theme_selector.dart';

class AuthenticatedHomePage extends StatefulWidget {
  const AuthenticatedHomePage({
    required this.sessionManager,
    required this.themeController,
    required this.apiClient,
    required this.contextData,
    super.key,
  });

  final SessionManager sessionManager;
  final OrmanThemeController themeController;
  final ApiClient apiClient;
  final AuthContext contextData;

  @override
  State<AuthenticatedHomePage> createState() => _AuthenticatedHomePageState();
}

class _AuthenticatedHomePageState extends State<AuthenticatedHomePage> {
  late final ContractApi _contracts = ContractApi(widget.apiClient);
  late final NotificationApi _notifications = NotificationApi(widget.apiClient);

  final List<TenantContract> _contractItems = [];
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _contractsError;
  int _nextPage = 0;
  int _unreadCount = 0;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadContracts(reset: true));
    unawaited(_refreshUnreadCount());
  }

  Future<void> _loadContracts({required bool reset}) async {
    if (_loadingMore || (_initialLoading && !reset)) return;
    final requestPage = reset ? 0 : _nextPage;
    setState(() {
      if (reset && _contractItems.isEmpty) _initialLoading = true;
      if (!reset) _loadingMore = true;
      if (reset) _contractsError = null;
    });
    try {
      final response = await _contracts.listContracts(page: requestPage);
      if (!mounted) return;
      setState(() {
        if (reset) _contractItems.clear();
        _contractItems.addAll(response.content);
        _hasMore = !response.last;
        _nextPage = response.page + 1;
        _contractsError = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _contractsError = _errorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          if (reset) _initialLoading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final summary = await _notifications.getSummary();
      if (mounted) setState(() => _unreadCount = summary.unreadCount);
    } on Object {
      // La campana no bloquea el portal si el resumen falla.
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadContracts(reset: true), _refreshUnreadCount()]);
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => NotificationsPage(
          apiClient: widget.apiClient,
          onUnreadCountChanged: (count) {
            if (mounted) setState(() => _unreadCount = count);
          },
        ),
      ),
    );
    await _refreshUnreadCount();
  }

  Future<void> _openContract(TenantContract contract) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ContractDetailPage(
          apiClient: widget.apiClient,
          contractCode: contract.code,
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await widget.sessionManager.signOut();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La sesión local se cerró. Vuelve a iniciar sesión.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.ormanColors;
    final name = widget.contextData.nombreCompleto;
    final shortName = name.trim().split(RegExp(r'\s+')).first;

    return OrmanPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  AppSpacing.x3,
                  AppSpacing.x4,
                  AppSpacing.x2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/branding/logo/orman-logo.svg',
                          width: 32,
                          height: 36,
                          fit: BoxFit.contain,
                          semanticsLabel: 'Logo ORMAN',
                        ),
                        const SizedBox(width: AppSpacing.x2),
                        Text(
                          'ORMAN',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          key: const Key('tenant-notifications-button'),
                          tooltip: 'Notificaciones',
                          onPressed: _openNotifications,
                          icon: Semantics(
                            label: _unreadCount == 0
                                ? 'Notificaciones'
                                : '$_unreadCount notificaciones sin leer',
                            child: SizedBox(
                              width: 38,
                              height: 38,
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  const Icon(Icons.notifications_none_rounded),
                                  if (_unreadCount > 0)
                                    Positioned(
                                      top: -2,
                                      right: -6,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: colors.danger,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: colors.page,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1,
                                          ),
                                          child: Text(
                                            _unreadCount >= 9
                                                ? '9+'
                                                : '$_unreadCount',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: colors.accentText,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 10,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      'Hola, $shortName',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      'Consulta tus contratos y pagos de alquiler.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OrmanThemeSelector(
                        controller: widget.themeController,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshAll,
                  child: ListView(
                    key: const Key('tenant-contract-list'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.x4,
                      AppSpacing.x2,
                      AppSpacing.x4,
                      AppSpacing.x6,
                    ),
                    children: [
                      Text('Mis contratos', style: theme.textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.x3),
                      if (_initialLoading && _contractItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.x8),
                          child: Center(
                            child: CircularProgressIndicator.adaptive(),
                          ),
                        )
                      else if (_contractsError != null &&
                          _contractItems.isEmpty)
                        _PortalError(
                          message: _contractsError!,
                          onRetry: () => _loadContracts(reset: true),
                        )
                      else if (_contractItems.isEmpty)
                        OrmanCard(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.x2),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.home_work_outlined,
                                  size: 38,
                                  color: colors.textMuted,
                                ),
                                const SizedBox(height: AppSpacing.x3),
                                Text(
                                  'No tienes contratos registrados.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        for (final contract in _contractItems) ...[
                          _ContractCard(
                            contract: contract,
                            onTap: () => _openContract(contract),
                          ),
                          const SizedBox(height: AppSpacing.x3),
                        ],
                        if (_contractsError != null)
                          _PortalError(
                            message: _contractsError!,
                            onRetry: () => _loadContracts(reset: false),
                          ),
                        if (_hasMore)
                          Center(
                            child: TextButton.icon(
                              onPressed: _loadingMore
                                  ? null
                                  : () => _loadContracts(reset: false),
                              icon: _loadingMore
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.expand_more),
                              label: Text(
                                _loadingMore ? 'Cargando…' : 'Cargar más',
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: AppSpacing.x5),
                      OrmanSecondaryButton(
                        label: 'Cerrar sesión',
                        icon: Icons.logout,
                        isLoading: _isSigningOut,
                        onPressed: _isSigningOut ? null : _signOut,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({required this.contract, required this.onTap});

  final TenantContract contract;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.ormanColors;
    final role = contractStatusRole(contract.status);

    return Semantics(
      button: true,
      label:
          'Contrato ${contract.propertyName ?? 'sin propiedad'}, ${contract.status}',
      child: OrmanCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        contract.propertyName ?? 'Propiedad',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    OrmanStatusBadge(label: contract.status, role: role),
                  ],
                ),
                if (contract.unitName?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    'Unidad ${contract.unitName}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.x3),
                _ContractDateRow(
                  label: 'Inicio',
                  value: Formatters.date(contract.startDate),
                ),
                const SizedBox(height: AppSpacing.x1),
                _ContractDateRow(
                  label: 'Fin',
                  value: Formatters.date(contract.endDate),
                ),
                if (contract.monthlyAmount != null) ...[
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'Mensualidad · ${Formatters.currency(contract.monthlyAmount)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: AppSpacing.x2),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: colors.textMuted,
                    size: 20,
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

class _ContractDateRow extends StatelessWidget {
  const _ContractDateRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.ormanColors;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
        ),
        Text(value, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _PortalError extends StatelessWidget {
  const _PortalError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.ormanColors;
    return OrmanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.cloud_off_outlined, color: colors.danger, size: 28),
          const SizedBox(height: AppSpacing.x2),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.x3),
          OrmanSecondaryButton(
            label: 'Reintentar',
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

String _errorMessage(Object error) => error is ApiException
    ? error.detail
    : error is FormatException
    ? error.message
    : 'No se pudo cargar la información. Inténtalo nuevamente.';
