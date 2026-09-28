import 'package:flutter_test/flutter_test.dart';
import 'package:orman/app/theme/orman_semantic_colors.dart';
import 'package:orman/core/utils/formatters.dart';
import 'package:orman/features/contracts/data/contract_api.dart';
import 'package:orman/features/contracts/models/portal_status.dart';
import 'package:orman/features/contracts/models/tenant_contract.dart';

import '../../support/fake_portal_api.dart';

void main() {
  test(
    'contract pages parse the exact backend fields and pagination',
    () async {
      final api = ContractApi(createFakePortalApi());
      final page = await api.listContracts(page: 0, size: 20);

      expect(page.content, hasLength(1));
      expect(page.page, 0);
      expect(page.totalElements, 1);
      expect(page.last, isTrue);
      expect(page.content.single.code, 12);
      expect(page.content.single.propertyName, 'Edificio ORMAN');
      expect(page.content.single.unitName, 'A-3');
      expect(page.content.single.startDate, DateTime(2026, 1, 1));
      expect(page.content.single.monthlyAmount, 2500);
    },
  );

  test('contract DTO keeps optional rescission values nullable', () {
    final contract = TenantContract.fromJson(contractJson());
    expect(contract.rescissionDate, isNull);
    expect(contract.rescissionReason, isNull);
  });

  test('all contract states map to the ORMAN semantic role', () {
    expect(contractStatusRole('VIGENTE'), OrmanSemanticRole.success);
    expect(contractStatusRole('PROGRAMADO'), OrmanSemanticRole.info);
    expect(contractStatusRole('FINALIZADO'), OrmanSemanticRole.neutral);
    expect(contractStatusRole('RESCINDIDO'), OrmanSemanticRole.warning);
  });

  test(
    'installment fields preserve backend balance and review amount',
    () async {
      final api = ContractApi(createFakePortalApi());
      final values = await api.listInstallments(12);
      final installment = values.single;

      expect(installment.code, 88);
      expect(installment.period, DateTime(2026, 9, 1));
      expect(installment.amount, 2500);
      expect(installment.confirmedAmount, 500);
      expect(installment.pendingReviewAmount, 500);
      expect(installment.balance, 1500);
      expect(installment.dueSituation, 'VENCIDA');
    },
  );

  test('all installment states map to semantic roles', () {
    expect(installmentStatusRole('PENDIENTE'), OrmanSemanticRole.warning);
    expect(installmentStatusRole('PARCIAL'), OrmanSemanticRole.info);
    expect(installmentStatusRole('PAGADA'), OrmanSemanticRole.success);
    expect(installmentStatusRole('ANULADA'), OrmanSemanticRole.danger);
  });

  test(
    'Spanish amounts, dates, periods, and balances are formatted centrally',
    () {
      expect(Formatters.currency(2500), 'Bs 2.500,00');
      expect(Formatters.currency(500.5), 'Bs 500,50');
      expect(Formatters.date(DateTime(2026, 9, 1)), '01/09/2026');
      expect(Formatters.period(DateTime(2026, 9, 1)), 'Septiembre 2026');
      expect(Formatters.amountToCents('500,50'), 50050);
      expect(Formatters.amountToCents('500.50'), 50050);
      expect(Formatters.amountToCents('1.000,00'), isNull);
      expect(Formatters.amountToCents('10,234'), isNull);
    },
  );
}
