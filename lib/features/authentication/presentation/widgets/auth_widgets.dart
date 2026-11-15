import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n_ext.dart';

class FailureBox extends StatelessWidget {
  const FailureBox(this.code, {super.key});
  final FailureCode code;

  @override
  Widget build(BuildContext context) {
    final s = StatusColors.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: s.errorBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: s.error),
        ),
        child: Row(children: [
          Icon(Icons.error_outline_rounded, color: s.error),
          const SizedBox(width: 10),
          Expanded(child: Text(code.message(context.l10n), style: TextStyle(color: s.error, fontWeight: FontWeight.w600))),
        ]),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({super.key, required this.controller, required this.label, this.onSubmitted, this.autofillHints});
  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => TextField(
        controller: widget.controller,
        obscureText: _obscure,
        enableSuggestions: false,
        autocorrect: false,
        autofillHints: widget.autofillHints,
        textInputAction: TextInputAction.done,
        onSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            tooltip: _obscure ? context.l10n.showPassword : context.l10n.hidePassword,
            icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      );
}
