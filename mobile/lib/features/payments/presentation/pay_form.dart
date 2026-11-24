// NEW 11.3: the pay form. Words come from the ARB files (English and Afrikaans)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/core/money/money_parse.dart';
import 'package:ronditrack/features/payments/application/pay_action.dart';
import 'package:ronditrack/l10n/app_localizations.dart';

class PayForm extends ConsumerStatefulWidget {
  const new({required this.stokvelId, required this.cycleId, super.key});

  final String stokvelId;
  final String cycleId;

  @override
  ConsumerState<PayForm> createState() => _PayFormState();
}

class _PayFormState extends ConsumerState<PayForm> {
  final _amount = TextEditingController();
  String? _error;
  String? _message;
  bool _busy = false; // while true the button is off: a second tap cannot make a second payment
  bool _done = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  String _words(AppLocalizations t, PayOutcome o) => switch (o.kind) {
    PayKind.paid => t.payDone,
    PayKind.queued => t.payQueued,
    PayKind.waiting => t.payWaiting(o.waitFor?.inSeconds ?? 0),
    PayKind.refused => o.message ?? t.payRefusedGeneric,
    PayKind.expired => t.payExpired,
  };

  Future<void> _pay() async {
    final t = AppLocalizations.of(context);
    final parsed = parseRands(_amount.text);
    switch (parsed) {
      case MoneyRejected(:final reason):
        // The error sits under the field; what was typed stays
        setState(() {
          _message = null;
          _error = switch (reason) {
            MoneyParseFailure.empty => t.payErrorEmpty,
            MoneyParseFailure.tooManyDecimals => t.payErrorTooManyDecimals,
            MoneyParseFailure.invalid => t.payErrorInvalid,
          };
        });
      case MoneyParsed(:final amount):
        setState(() {
          _error = null;
          _busy = true;
        });
        final outcome = await ref
            .read(payActionProvider)
            .pay(
              stokvelId: widget.stokvelId,
              cycleId: widget.cycleId,
              // Cents is an int underneath; the phone never turns it into a double
              cents: amount as int,
            );
        if (!mounted) return;
        setState(() {
          _busy = false;
          _message = _words(t, outcome);
          _done =
              outcome.kind != PayKind.refused &&
              outcome.kind != PayKind.waiting;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(t.payTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('pay-amount'),
              controller: _amount,
              enabled: !_busy && !_done,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: t.payAmountLabel,
                hintText: t.payAmountHint,
                errorText: _error,
              ),
              onSubmitted: (_) => _busy || _done ? null : _pay(),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(_message!, key: const Key('pay-message')),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.payClose),
        ),
        FilledButton(
          key: const Key('pay-button'),
          onPressed: _busy || _done ? null : _pay,
          child: Text(t.payButton),
        ),
      ],
    );
  }
}
