import '../../../core/network/api_client.dart';
import '../../../core/network/json_readers.dart';
import '../models/tenant_contract.dart';
import '../models/tenant_installment.dart';

class ContractApi {
  const ContractApi(this._http);

  final ApiClient _http;

  Future<TenantContractPage> listContracts({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _http.getJson(
      'api/v1/inquilino/contratos',
      queryParameters: {'page': page, 'size': size},
    );
    return TenantContractPage.fromJson(response);
  }

  Future<TenantContract> getContract(int code) async {
    final response = await _http.getJson('api/v1/inquilino/contratos/$code');
    final json = jsonMap(response);
    if (json == null) {
      throw const FormatException('La respuesta del contrato no es válida.');
    }
    return TenantContract.fromJson(json);
  }

  Future<List<TenantInstallment>> listInstallments(int contractCode) async {
    final response = await _http.getJson(
      'api/v1/inquilino/contratos/$contractCode/cuotas',
    );
    return jsonMapList(
      response,
    ).map(TenantInstallment.fromJson).toList(growable: false);
  }

  Future<TenantInstallment> getInstallment(int code) async {
    final response = await _http.getJson('api/v1/inquilino/cuotas/$code');
    final json = jsonMap(response);
    if (json == null) {
      throw const FormatException('La respuesta de la cuota no es válida.');
    }
    return TenantInstallment.fromJson(json);
  }
}
