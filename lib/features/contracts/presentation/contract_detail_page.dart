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
import '../data/contract_api.dart';
import '../models/tenant_contract.dart';
import '../models/tenant_installment.dart';
import '../models/portal_status.dart';
import 'installment_card.dart';

class ContractDetailPage extends StatefulWidget {
  const ContractDetailPage({
    required this.apiClient,
    required this.contractCode,
    super.key,
  });

  final ApiClient apiClient;
  final int contractCode;

  @override
  State<ContractDetailPage> createState() => _ContractDetailPageState();
}

class _ContractDetailPageState extends State<ContractDetailPage> {
  late final ContractApi _api = ContractApi(widget.apiClient);
  TenantContract? _contract;
  List<TenantInstallment> _installments = const [];
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
      final contractFuture = _api.getContract(widget.contractCode);
      final installmentsFuture = _api.listInstallments(widget.contractCode);
      final contract = await contractFuture;
      final installments = await installmentsFuture;
      if (!mounted) return;
      setState(() {
        _contract = contract;
        _installments = installments;
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openInstallment(TenantInstallment installment) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => InstallmentDetailPage(
          apiClient: widget.apiClient,
          installmentCode: installment.code,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.ormanColors;
    final contract = _contract;
    return OrmanPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Detalle del contrato'),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            key: const Key('contract-detail-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x4,
              AppSpacing.x2,
              AppSpacing.x4,
              AppSpacing.x6,
            ),
            children: [
              if (_loading && contract == null)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.x8),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              else if (_error != null && contract == null)
                _LoadError(message: _error!, onRetry: _load)
              else if (contract != null) ...[
                OrmanCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              contract.propertyName ?? 'Propiedad',
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          _ContractBadge(contract.status),
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
                      _DetailLine(
                        label: 'Fecha de inicio',
                        value: Formatters.date(contract.startDate),
                      ),
                      _DetailLine(
                        label: 'Fecha de fin',
                        value: Formatters.date(contract.endDate),
                      ),
                      if (contract.rescissionDate != null)
                        _DetailLine(
                          label: 'Fecha de rescisión',
                          value: Formatters.date(contract.rescissionDate),
                        ),
                      if (contract.rescissionReason?.isNotEmpty == true)
                        _DetailLine(
                          label: 'Motivo de rescisión',
                          value: contract.rescissionReason!,
                        ),
                      if (contract.monthlyAmount != null)
                        _DetailLine(
                          label: 'Monto mensual',
                          value: Formatters.currency(contract.monthlyAmount),
                        ),
                      if (contract.deposit != null)
                        _DetailLine(
                          label: 'Garantía',
                          value: Formatters.currency(contract.deposit),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x5),
                Text('Cuotas', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.x3),
                if (_loading && _installments.isEmpty)
                  const Center(child: CircularProgressIndicator.adaptive())
                else if (_installments.isEmpty)
                  OrmanCard(
                    child: Text(
                      'Este contrato no tiene cuotas registradas.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                else
                  for (final installment in _installments) ...[
                    InstallmentCard(
                      installment: installment,
                      onTap: () => _openInstallment(installment),
                    ),
                    const SizedBox(height: AppSpacing.x3),
                  ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.x2),
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textFor(OrmanSemanticRole.danger),
                      ),
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

class _ContractBadge extends StatelessWidget {
  const _ContractBadge(this.status);
  final String status;

  @override
  Widget build(BuildContext context) =>
      OrmanStatusBadge(label: status, role: contractStatusRole(status));
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.ormanColors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => OrmanCard(
    child: Column(
      children: [
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

String _friendlyError(Object error) => error is ApiException
    ? error.detail
    : error is FormatException
    ? error.message
    : 'No se pudo cargar el contrato. Inténtalo nuevamente.';
