import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orman/app/theme/app_theme.dart';
import 'package:orman/app/theme/orman_theme_kind.dart';
import 'package:orman/core/network/api_client.dart';
import 'package:orman/features/payments/data/qr_gallery_saver.dart';
import 'package:orman/features/payments/presentation/qr_collection_sheet.dart';

import '../../support/fake_http_adapter.dart';
import '../../support/fake_portal_api.dart';

const _qrBytes = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

void main() {
  test('gallery filename includes quota code and a compact date', () {
    expect(
      qrGalleryFileName(installmentCode: 88, date: DateTime(2027, 6, 3)),
      'ORMAN_QR_COBRO_88_20270603',
    );
  });

  testWidgets('downloads the authenticated QR bytes and confirms success', (
    tester,
  ) async {
    final saver = _FakeQrGallerySaver();
    final api = _qrImageApi();
    await _openQrSheet(tester, api, saver);

    await tester.ensureVisible(find.text('Descargar QR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descargar QR'));
    await tester.pumpAndSettle();

    expect(saver.bytes, Uint8List.fromList(_qrBytes));
    expect(saver.name, startsWith('ORMAN_QR_COBRO_88_'));
    expect(find.text('QR guardado correctamente.'), findsOneWidget);
    expect(find.text('QR de cobro'), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);
  });

  testWidgets('shows save error and leaves the QR sheet open', (tester) async {
    final saver = _FakeQrGallerySaver()..error = StateError('gallery failed');
    await _openQrSheet(tester, _qrImageApi(), saver);

    await tester.ensureVisible(find.text('Descargar QR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descargar QR'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo guardar el QR.'), findsOneWidget);
    expect(find.text('QR de cobro'), findsOneWidget);
  });

  testWidgets('QR sheet scrolls at phone widths for every theme', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final kind in OrmanThemeKind.values) {
      for (final width in [360.0, 390.0, 412.0]) {
        tester.view.physicalSize = Size(width, 640);
        await _openQrSheet(
          tester,
          _qrImageApi(),
          _FakeQrGallerySaver(),
          themeKind: kind,
        );
        final downloadButton = find.text('Descargar QR');
        await tester.ensureVisible(downloadButton);
        expect(downloadButton, findsOneWidget, reason: '${kind.label} $width');
        expect(tester.takeException(), isNull, reason: '${kind.label} $width');
        await tester.tap(find.text('Cerrar'));
        await tester.pumpAndSettle();
      }
    }
  });
}

Future<void> _openQrSheet(
  WidgetTester tester,
  ApiClient api,
  QrGallerySaver saver, {
  OrmanThemeKind themeKind = OrmanThemeKind.orman,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.forKind(themeKind),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              key: const Key('open-qr-sheet'),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (context) => QrCollectionSheet(
                  apiClient: api,
                  installmentCode: 88,
                  gallerySaver: saver,
                ),
              ),
              child: const Text('Abrir QR'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open-qr-sheet')));
  await tester.pumpAndSettle();
}

ApiClient _qrImageApi() => createFakePortalApi(
  onRequest: (options, requestStream) async {
    if (options.path.endsWith('/qr-cobro/imagen')) {
      return ResponseBody.fromBytes(
        _qrBytes,
        200,
        headers: {
          Headers.contentTypeHeader: ['image/png'],
        },
      );
    }
    if (options.path.endsWith('/qr-cobro')) {
      return jsonResponse(qrJson(tieneImagen: true));
    }
    return jsonResponse({});
  },
);

class _FakeQrGallerySaver implements QrGallerySaver {
  Uint8List? bytes;
  String? name;
  Object? error;

  @override
  Future<void> save({required Uint8List bytes, required String name}) async {
    if (error case final saveError?) throw saveError;
    this.bytes = bytes;
    this.name = name;
  }
}
