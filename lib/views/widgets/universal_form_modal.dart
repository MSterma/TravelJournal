import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class UniversalFormModal extends StatefulWidget {
  const UniversalFormModal({super.key, required this.title, required this.label, required this.onSubmit});
  final String title;
  final String label;
  final Function(String) onSubmit;

  static void show(BuildContext context, {required String title, required String label, required Function(String) onSubmit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: UniversalFormModal(title: title, label: label, onSubmit: (val) {
            Navigator.pop(ctx);
            onSubmit(val);
          }),
        ),
      ),
    );
  }

  @override
  State<UniversalFormModal> createState() => _UniversalFormModalState();
}

class _UniversalFormModalState extends State<UniversalFormModal> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          decoration: InputDecoration(labelText: widget.label, border: const OutlineInputBorder()),
          autofocus: true,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onSubmit(_controller.text);
            }
          },
          child: Text(l10n.save.toUpperCase()),
        ),
      ],
    );
  }
}