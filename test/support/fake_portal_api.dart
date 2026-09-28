import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:orman/core/network/api_client.dart';

import 'fake_http_adapter.dart';

ApiClient createFakePortalApi({
  Future<ResponseBody> Function(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
  )?
  onRequest,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://orman.test/'));
  dio.httpClientAdapter = CallbackHttpAdapter.withRequestBody(
    onRequest ?? _defaultPortalResponse,
  );
  return ApiClient(dio);
}

Future<ResponseBody> _defaultPortalResponse(
  RequestOptions options,
  Stream<Uint8List>? requestStream,
) async {
  final path = options.path;
  if (path.endsWith('/notificaciones/resumen')) {
    return jsonResponse({'noLeidas': 2});
  }
  if (path.endsWith('/notificaciones') && options.method == 'GET') {
    return jsonResponse({
      'content': [notificationJson()],
      'page': 0,
      'size': 20,
      'totalElements': 1,
      'totalPages': 1,
      'first': true,
      'last': true,
    });
  }
  if (path.endsWith('/leer')) {
    return jsonResponse(notificationJson(leida: true));
  }
  if (path.contains('/notificaciones/')) {
    return jsonResponse(notificationJson());
  }
  if (path.endsWith('/inquilino/contratos') && options.method == 'GET') {
    return jsonResponse({
      'content': [contractJson()],
      'page': 0,
      'size': 20,
      'totalElements': 1,
      'totalPages': 1,
      'first': true,
      'last': true,
    });
  }
  if (path.endsWith('/contratos/12/cuotas')) {
    return jsonResponse([installmentJson()]);
  }
  if (path.endsWith('/contratos/12')) {
    return jsonResponse(contractJson());
  }
  if (path.endsWith('/qr-cobro')) {
    return jsonResponse(qrJson(tieneImagen: false));
  }
  if (path.endsWith('/qr-cobro/imagen')) {
    return ResponseBody.fromString(
      jsonEncode({'detail': 'No existe imagen'}),
      404,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
  if (path.endsWith('/pagos') && options.method == 'POST') {
    return jsonResponse(paymentJson(), statusCode: 201);
  }
  if (path.contains('/inquilino/cuotas/')) {
    return jsonResponse(installmentJson());
  }
  return jsonResponse({});
}

Map<String, Object?> contractJson({
  int codcon = 12,
  String estado = 'VIGENTE',
}) => {
  'codcon': codcon,
  'estado': estado,
  'fechaInicio': '2026-01-01',
  'fechaFin': '2026-12-31',
  'fechaRescision': null,
  'motivoRescision': null,
  'montoMensual': 2500,
  'moneda': 'BOB',
  'garantia': 2500,
  'codprop': 4,
  'nombrePropiedad': 'Edificio ORMAN',
  'coduni': 7,
  'nombreUnidad': 'A-3',
};

Map<String, Object?> installmentJson({
  int codcuo = 88,
  String estado = 'PARCIAL',
  double saldo = 1500,
  double montoPendienteRevision = 500,
}) => {
  'codcuo': codcuo,
  'codcon': 12,
  'periodo': '2026-09-01',
  'fechaVencimiento': '2026-09-01',
  'monto': 2500,
  'montoConfirmado': 500,
  'montoPendienteRevision': montoPendienteRevision,
  'saldo': saldo,
  'estado': estado,
  'situacionVencimiento': 'VENCIDA',
};

Map<String, Object?> notificationJson({bool leida = false}) => {
  'codnot': 5,
  'tipo': 'CUOTA_VENCIDA',
  'titulo': 'Cuota pendiente',
  'mensaje': 'La cuota de septiembre está vencida.',
  'referenciaTipo': 'CUOTA',
  'referenciaId': 88,
  'fechaCreacion': '2026-09-12T10:30:00',
  'leida': leida,
  'fechaLectura': leida ? '2026-09-12T10:31:00' : null,
};

Map<String, Object?> qrJson({bool tieneImagen = true}) => {
  'codqr': 18,
  'fechaInicio': '2026-09-01',
  'fechaFin': '2026-09-30',
  'estado': 'ACTIVO',
  'tieneImagen': tieneImagen,
  'nombreArchivo': 'qr.png',
  'tipoContenido': 'image/png',
  'fechaRegistro': '2026-09-01T10:00:00',
};

Map<String, Object?> paymentJson({String estado = 'PENDIENTE_REVISION'}) => {
  'codpag': 300,
  'codcuo': 88,
  'codqr': 18,
  'monto': 500,
  'metodo': 'QR',
  'fechaPago': '2026-09-12T00:00:00',
  'fechaRegistro': '2026-09-12T14:00:00',
  'estado': estado,
  'origenRegistro': 'INQUILINO',
  'registradoPor': 'inquilino.demo',
  'revisadoPor': null,
  'fechaRevision': null,
  'motivoRechazo': null,
  'motivoAnulacion': null,
};
