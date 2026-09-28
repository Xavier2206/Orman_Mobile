import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extensions.dart';
import '../../../app/theme/orman_semantic_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/contracts/data/contract_api.dart';
import '../../../features/contracts/models/tenant_installment.dart';
import '../../../features/contracts/models/portal_status.dart';
import '../models/payment_amount_policy.dart';
import '../../../shared/widgets/orman_buttons.dart';
import '../../../shared/widgets/orman_card.dart';
import '../../../shared/widgets/orman_page_background.dart';
import '../../../shared/widgets/orman_status_badge.dart';
import 'payment_form_page.dart';
import 'qr_collection_sheet.dart';

class InstallmentDetailPage extends StatefulWidget {
  const InstallmentDetailPage({
    required this.apiClient,
    required this.installmentCode,
    super.key,
  });

  final ApiClient apiClient;
  final int installmentCode;

  @override
  State<InstallmentDetailPage> createState() => _InstallmentDetailPageState();
}

class _InstallmentDetailPageState extends State<InstallmentDetailPage> {
  late final ContractApi _api = ContractApi(widget.apiClient);
  TenantInstallment? _installment;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final installment = await _api.getInstallment(widget.installmentCode);
      if (mounted) setState(() => _installment = installment);
    } on Object catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showQr() async {
    final colors = context.ormanColors;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      showDragHandle: true,
      builder: (context) => QrCollectionSheet(
        apiClient: widget.apiClient,
        installmentCode: widget.installmentCode,
      ),
    );
  }

  Future<void> _showPaymentHistoryNotice() async {
    final colors = context.ormanColors;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      showDragHandle: true,
      builder: (context) => const _PaymentHistoryUnavailableSheet(),
    );
  }

  Future<void> _registerPayment(TenantInstallment installment) async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => PaymentFormPage(
          apiClient: widget.apiClient,
          installment: installment,
        ),
      ),
    );
    if (submitted == true && mounted) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comprobante enviado correctamente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.ormanColors;
    final installment = _installment;
    final status = installment?.status.toUpperCase();
    final maximumRegistrableCents = PaymentAmountPolicy.maximumRegistrableCents(
      balance: installment?.balance,
      pendingReviewAmount: installment?.pendingReviewAmount,
    );
    final paymentBlocked =
        status == 'PAGADA' ||
        status == 'ANULADA' ||
        maximumRegistrableCents <= 0;
    final reviewCoversRemainingBalance =
        status != 'PAGADA' &&
        status != 'ANULADA' &&
        maximumRegistrableCents == 0 &&
        (installment?.pendingReviewAmount ?? 0) > 0 &&
        (installment?.balance ?? 0) > 0;
    final statusRole = installment == null
        ? OrmanSemanticRole.neutral
        : installmentStatusRole(installment.status);

    return OrmanPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Detalle de cuota'),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            key: const Key('installment-detail-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x4,
              AppSpacing.x2,
              AppSpacing.x4,
              AppSpacing.x6,
            ),
            children: [
              if (_loading && installment == null)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.x8),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              else if (_error != null && installment == null)
                OrmanCard(
                  child: Column(
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.x3),
                      OrmanSecondaryButton(
                        label: 'Reintentar',
                        icon: Icons.refresh,
                        onPressed: _load,
                      ),
                    ],
                  ),
                )
              else if (installment != null) ...[
                OrmanCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              Formatters.period(installment.period),
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          OrmanStatusBadge(
                            label: installment.status,
                            role: statusRole,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      _BalanceRow(
                        label: 'Monto de la cuota',
                        value: Formatters.currency(installment.amount),
                      ),
                      _BalanceRow(
                        label: 'Pagado confirmado',
                        value: Formatters.currency(installment.confirmedAmount),
                      ),
                      if ((installment.pendingReviewAmount ?? 0) > 0)
                        _BalanceRow(
                          label: 'Pendiente de revisión',
                          value: Formatters.currency(
                            installment.pendingReviewAmount,
                          ),
                          role: OrmanSemanticRole.warning,
                        ),
                      _BalanceRow(
                        label: 'Saldo',
                        value: Formatters.currency(installment.balance),
                        emphasize: true,
                      ),
                      const SizedBox(height: AppSpacing.x3),
                      _BalanceRow(
                        label: 'Vencimiento',
                        value: Formatters.date(installment.dueDate),
                      ),
                      if (installment.dueSituation?.isNotEmpty == true)
                        _BalanceRow(
                          label: 'Situación',
                          value: installment.dueSituation!,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                OrmanSecondaryButton(
                  label: 'Ver QR de cobro',
                  icon: Icons.qr_code_2_rounded,
                  onPressed: _showQr,
                ),
                const SizedBox(height: AppSpacing.x2),
                OrmanSecondaryButton(
                  label: 'Historial de pagos',
                  icon: Icons.history_rounded,
                  onPressed: _showPaymentHistoryNotice,
                ),
                if (!paymentBlocked) ...[
                  const SizedBox(height: AppSpacing.x2),
                  OrmanPrimaryButton(
                    label: 'Registrar pago',
                    icon: Icons.receipt_long_outlined,
                    onPressed: () => _registerPayment(installment),
                  ),
                ],
                if (reviewCoversRemainingBalance) ...[
                  const SizedBox(height: AppSpacing.x3),
                  OrmanCard(
                    child: Text(
                      'Tienes un pago pendiente de revisión que cubre el saldo restante.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textFor(OrmanSemanticRole.warning),
                      ),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.x3),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textFor(OrmanSemanticRole.danger),
                    ),
                  ),
                ],
                if (_loading) ...[
                  const SizedBox(height: AppSpacing.x3),
                  const LinearProgressIndicator(),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentHistoryUnavailableSheet extends StatelessWidget {
  const _PaymentHistoryUnavailableSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.ormanColors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x4,
          AppSpacing.x3,
          AppSpacing.x4,
          AppSpacing.x5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Historial de pagos', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.x3),
            OrmanCard(
              child: Text(
                'El historial de pagos todavía no está disponible para inquilinos.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            OrmanSecondaryButton(
              label: 'Cerrar',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.role,
  });

  final String label;
  final String value;
  final bool emphasize;
  final OrmanSemanticRole? role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.ormanColors;
    final valueColor = role == null ? colors.text : colors.textFor(role!);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _friendlyError(Object error) => error is ApiException
    ? error.detail
    : error is FormatException
    ? error.message
    : 'No se pudo cargar la cuota. Inténtalo nuevamente.';
