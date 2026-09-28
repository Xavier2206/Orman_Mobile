import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extensions.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/orman_buttons.dart';
import '../../../shared/widgets/orman_card.dart';
import '../data/payment_api.dart';
import '../data/qr_gallery_saver.dart';
import '../models/qr_collection.dart';

class QrCollectionSheet extends StatefulWidget {
  const QrCollectionSheet({
    required this.apiClient,
    required this.installmentCode,
    this.gallerySaver,
    super.key,
  });

  final ApiClient apiClient;
  final int installmentCode;
  final QrGallerySaver? gallerySaver;

  @override
  State<QrCollectionSheet> createState() => _QrCollectionSheetState();
}

class _QrCollectionSheetState extends State<QrCollectionSheet> {
  late final PaymentApi _api = PaymentApi(widget.apiClient);
  QrCollection? _qr;
  Uint8List? _image;
  bool _loading = true;
  bool _saving = false;
  bool _unavailable = false;
  String? _error;

  QrGallerySaver get _gallerySaver =>
      widget.gallerySaver ?? const GalQrGallerySaver();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final qr = await _api.getCurrentQr(widget.installmentCode);
      if (!qr.hasImage) {
        if (mounted) setState(() => _unavailable = true);
        return;
      }
      final image = await _api.getCurrentQrImage(widget.installmentCode);
      if (mounted) {
        setState(() {
          _qr = qr;
          _image = image;
          _unavailable = image.isEmpty;
        });
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 404 ||
          error.detail.toLowerCase().contains('qr de cobro vigente')) {
        setState(() => _unavailable = true);
      } else {
        setState(() => _error = error.detail);
      }
    } on Object {
      if (mounted) setState(() => _error = 'No se pudo cargar el QR.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveQr() async {
    final image = _image;
    if (_saving || image == null) return;
    setState(() => _saving = true);
    try {
      await _gallerySaver.save(
        bytes: image,
        name: qrGalleryFileName(
          installmentCode: widget.installmentCode,
          date: DateTime.now(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR guardado correctamente.')),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar el QR.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.ormanColors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x4,
          AppSpacing.x5,
          AppSpacing.x4,
          AppSpacing.x4,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('QR de cobro', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.x3),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.x8),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              else if (_unavailable)
                OrmanCard(
                  child: Text(
                    'La propietaria no tiene un QR de cobro vigente.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else if (_error != null)
                OrmanCard(
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.text,
                    ),
                  ),
                )
              else if (_qr != null && _image != null) ...[
                OrmanCard(
                  padding: const EdgeInsets.all(AppSpacing.x3),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.memory(
                      _image!,
                      fit: BoxFit.contain,
                      semanticLabel: 'Código QR de cobro',
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          'No se pudo mostrar la imagen del QR.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                _QrDateLine(
                  label: 'Vigente desde',
                  value: Formatters.date(_qr!.startDate),
                ),
                _QrDateLine(
                  label: 'Vigente hasta',
                  value: Formatters.date(_qr!.endDate),
                ),
                const SizedBox(height: AppSpacing.x3),
                Text(
                  'Realiza el pago desde la aplicación de tu banco.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
              if (_image != null) ...[
                const SizedBox(height: AppSpacing.x4),
                OrmanPrimaryButton(
                  label: _saving ? 'Guardando…' : 'Descargar QR',
                  icon: Icons.download_rounded,
                  isLoading: _saving,
                  onPressed: _saving ? null : _saveQr,
                ),
              ],
              const SizedBox(height: AppSpacing.x2),
              OrmanSecondaryButton(
                label: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrDateLine extends StatelessWidget {
  const _QrDateLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.ormanColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x1),
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
          Text(value, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
