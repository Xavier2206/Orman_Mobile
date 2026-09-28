import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extensions.dart';
import '../../../app/theme/orman_semantic_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/contracts/models/tenant_installment.dart';
import '../../../shared/widgets/orman_buttons.dart';
import '../../../shared/widgets/orman_card.dart';
import '../../../shared/widgets/orman_page_background.dart';
import '../../../shared/widgets/orman_status_badge.dart';
import '../data/payment_api.dart';
import '../models/payment_amount_policy.dart';
import '../models/payment_submission.dart';

class PaymentFormPage extends StatefulWidget {
  const PaymentFormPage({
    required this.apiClient,
    required this.installment,
    super.key,
  });

  final ApiClient apiClient;
  final TenantInstallment installment;

  @override
  State<PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends State<PaymentFormPage> {
  static const _uuid = Uuid();

  late final PaymentApi _api = PaymentApi(widget.apiClient);
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late DateTime _paymentDate;
  PaymentProof? _proof;
  String? _idempotencyKey;
  String? _error;
  bool _submitting = false;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _paymentDate = DateTime(now.year, now.month, now.day);
    _amountController.addListener(_clearRetryKeyOnAmountChange);
  }

  @override
  void dispose() {
    _amountController
      ..removeListener(_clearRetryKeyOnAmountChange)
      ..dispose();
    super.dispose();
  }

  void _clearRetryKeyOnAmountChange() {
    _idempotencyKey = null;
  }

  Future<void> _selectDate() async {
    if (_submitting) return;
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _paymentDate.isAfter(today) ? today : _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year, today.month, today.day),
      helpText: 'Fecha en que realizaste el pago',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (selected != null && mounted) {
      setState(() {
        _paymentDate = DateTime(selected.year, selected.month, selected.day);
        _idempotencyKey = null;
        _error = null;
      });
    }
  }

  Future<void> _pickProof() async {
    if (_submitting || _picking) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final selected = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (selected == null || !mounted) return;
      final size = await selected.length();
      if (size > PaymentProofValidator.maxSizeInBytes) {
        setState(() => _error = 'El comprobante no puede superar 5 MiB.');
        return;
      }
      final extension = selected.name.split('.').last.toLowerCase();
      final contentType =
          selected.mimeType ??
          switch (extension) {
            'png' => 'image/png',
            'jpg' || 'jpeg' => 'image/jpeg',
            _ => 'application/octet-stream',
          };
      final candidate = PaymentProof(
        bytes: Uint8List.fromList(await selected.readAsBytes()),
        fileName: selected.name,
        contentType: contentType,
      );
      final validation = PaymentProofValidator.validate(candidate);
      if (validation != null) {
        setState(() => _error = validation);
        return;
      }
      setState(() {
        _proof = candidate;
        _idempotencyKey = null;
      });
    } on Object {
      if (mounted) setState(() => _error = 'No se pudo abrir la galería.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  int get _maximumRegistrableCents =>
      PaymentAmountPolicy.maximumRegistrableCents(
        balance: widget.installment.balance,
        pendingReviewAmount: widget.installment.pendingReviewAmount,
      );

  PaymentAmountValidation _validateAmountValue(String? value) =>
      PaymentAmountPolicy.validateInput(
        value,
        maximumCents: _maximumRegistrableCents,
      );

  String? _validateAmount(String? value) =>
      _validateAmountValue(value).messageFor(_maximumRegistrableCents);

  Future<void> _submit() async {
    if (_submitting) return;
    final formValid = _formKey.currentState?.validate() ?? false;
    final amountValidation = _validateAmountValue(_amountController.text);
    if (!formValid || !amountValidation.isValid) return;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (_paymentDate.isAfter(todayDate)) {
      setState(() => _error = 'La fecha del pago no puede ser futura.');
      return;
    }
    final proofValidation = PaymentProofValidator.validate(_proof);
    if (proofValidation != null) {
      setState(() => _error = proofValidation);
      return;
    }
    final cents = amountValidation.amountCents!;

    setState(() {
      _submitting = true;
      _error = null;
      _idempotencyKey ??= _uuid.v4();
    });
    try {
      final result = await _api.submitPayment(
        installmentCode: widget.installment.code,
        submission: PaymentSubmission(
          amountCents: cents,
          paymentDate: _paymentDate,
          idempotencyKey: _idempotencyKey!,
        ),
        proof: _proof!,
      );
      if (!mounted) return;
      if (result.status != 'PENDIENTE_REVISION') {
        setState(
          () => _error =
              'El pago fue recibido con estado ${result.status}. Actualiza la cuota para ver su estado.',
        );
        return;
      }
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.detail);
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ArgumentError
              ? error.message.toString()
              : 'No se pudo enviar el comprobante. Revisa tu conexión e inténtalo nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.ormanColors;
    final balance = widget.installment.balance;
    final pendingReviewAmount = widget.installment.pendingReviewAmount ?? 0;
    final maximumRegistrableCents = _maximumRegistrableCents;
    final canRegisterPayment = maximumRegistrableCents > 0;
    return OrmanPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Registrar pago QR'),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              key: const Key('payment-form-scroll'),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x4,
                AppSpacing.x2,
                AppSpacing.x4,
                AppSpacing.x6,
              ),
              children: [
                OrmanCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        Formatters.period(widget.installment.period),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      Text(
                        'Saldo pendiente',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                      Text(
                        Formatters.currency(balance),
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      Text(
                        'En revisión',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                      Text(
                        Formatters.currency(pendingReviewAmount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.textFor(OrmanSemanticRole.warning),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      const OrmanStatusBadge(
                        label: 'Método QR',
                        role: OrmanSemanticRole.info,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                Text('Monto pagado', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.x1),
                TextFormField(
                  key: const Key('payment-amount-field'),
                  controller: _amountController,
                  enabled: !_submitting && canRegisterPayment,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [LengthLimitingTextInputFormatter(16)],
                  decoration: const InputDecoration(
                    prefixText: 'Bs ',
                    hintText: '0,00',
                  ),
                  validator: _validateAmount,
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  'Puedes registrar hasta '
                  '${Formatters.currencyFromCents(maximumRegistrableCents)}. '
                  'Se permiten pagos parciales.',
                  key: const Key('payment-maximum-help'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                if (!canRegisterPayment) ...[
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'Tienes un pago pendiente de revisión que cubre el saldo restante.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textFor(OrmanSemanticRole.warning),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.x4),
                Text('Fecha del pago', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.x1),
                OutlinedButton.icon(
                  key: const Key('payment-date-button'),
                  onPressed: _submitting || !canRegisterPayment
                      ? null
                      : _selectDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(Formatters.date(_paymentDate)),
                ),
                const SizedBox(height: AppSpacing.x4),
                Text('Comprobante', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.x1),
                if (_proof == null)
                  OrmanSecondaryButton(
                    label: _picking
                        ? 'Abriendo galería…'
                        : 'Seleccionar imagen',
                    icon: Icons.add_photo_alternate_outlined,
                    isLoading: _picking,
                    onPressed: _submitting || _picking ? null : _pickProof,
                  )
                else
                  OrmanCard(
                    padding: const EdgeInsets.all(AppSpacing.x3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: Image.memory(
                              _proof!.bytes,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox(
                                    height: 100,
                                    child: Center(
                                      child: Icon(Icons.broken_image_outlined),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        Text(
                          _proof!.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          Formatters.fileSize(_proof!.sizeInBytes),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        OrmanSecondaryButton(
                          label: _picking
                              ? 'Abriendo galería…'
                              : 'Cambiar imagen',
                          icon: Icons.swap_horiz,
                          isLoading: _picking,
                          onPressed: _submitting || _picking
                              ? null
                              : _pickProof,
                        ),
                      ],
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.x3),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      key: const Key('payment-form-error'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textFor(OrmanSemanticRole.danger),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.x5),
                OrmanPrimaryButton(
                  label: 'Enviar comprobante',
                  icon: Icons.upload_file_outlined,
                  isLoading: _submitting,
                  onPressed: _submitting || !canRegisterPayment
                      ? null
                      : _submit,
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  'ORMAN no procesa el dinero. Paga desde tu banco y registra aquí el comprobante.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
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
