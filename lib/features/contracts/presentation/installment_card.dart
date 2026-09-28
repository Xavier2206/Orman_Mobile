import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extensions.dart';
import '../../../app/theme/orman_semantic_colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/tenant_installment.dart';
import '../models/portal_status.dart';
import '../../../shared/widgets/orman_card.dart';
import '../../../shared/widgets/orman_status_badge.dart';

class InstallmentCard extends StatelessWidget {
  const InstallmentCard({
    required this.installment,
    required this.onTap,
    super.key,
  });

  final TenantInstallment installment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.ormanColors;
    final role = installmentStatusRole(installment.status);
    final pending = installment.pendingReviewAmount ?? 0;

    return OrmanCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      Formatters.period(installment.period),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  OrmanStatusBadge(label: installment.status, role: role),
                ],
              ),
              const SizedBox(height: AppSpacing.x2),
              _AmountLine(
                label: 'Vence',
                value: Formatters.date(installment.dueDate),
              ),
              _AmountLine(
                label: 'Monto',
                value: Formatters.currency(installment.amount),
              ),
              _AmountLine(
                label: 'Confirmado',
                value: Formatters.currency(installment.confirmedAmount),
              ),
              if (pending > 0)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.x1),
                  child: Text(
                    'En revisión: ${Formatters.currency(pending)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textFor(OrmanSemanticRole.warning),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              _AmountLine(
                label: 'Saldo',
                value: Formatters.currency(installment.balance),
                emphasize: true,
              ),
              if (installment.dueSituation?.isNotEmpty == true) ...[
                const SizedBox(height: AppSpacing.x1),
                Text(
                  installment.dueSituation!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
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

class _AmountLine extends StatelessWidget {
  const _AmountLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.ormanColors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.x1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: emphasize ? FontWeight.w700 : null,
            ),
          ),
        ],
      ),
    );
  }
}
