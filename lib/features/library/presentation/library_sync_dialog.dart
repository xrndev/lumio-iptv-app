import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../library_providers.dart';

Future<void> showLibrarySyncDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const LibrarySyncDialog());

/// Pasar favoritos, recientes y progreso a otro dispositivo con un código de texto.
///
/// En el dispositivo origen: "Copiar código". En el destino (con la misma cuenta añadida):
/// pegarlo y pulsar "Importar". Se fusiona: no se pierde nada de lo que ya hubiera.
class LibrarySyncDialog extends ConsumerStatefulWidget {
  const LibrarySyncDialog({super.key});

  @override
  ConsumerState<LibrarySyncDialog> createState() => _LibrarySyncDialogState();
}

class _LibrarySyncDialogState extends ConsumerState<LibrarySyncDialog> {
  final _input = TextEditingController();
  String? _message;
  bool _ok = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final code = await ref.read(libraryProvider.notifier).exportCode();
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() {
      _ok = true;
      _message = AppLocalizations.of(context).syncCodeCopied;
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) _input.text = data!.text!;
  }

  Future<void> _import() async {
    final result = await ref.read(libraryProvider.notifier).importCode(_input.text);
    if (!mounted) return;
    setState(() {
      _ok = result == ImportResult.merged;
      _message = switch (result) {
        ImportResult.merged => AppLocalizations.of(context).syncMerged,
        ImportResult.otherSource => AppLocalizations.of(context).syncOtherAccount,
        ImportResult.invalidCode => AppLocalizations.of(context).syncInvalidCode,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(AppLocalizations.of(context).syncTitle),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(AppLocalizations.of(context).syncStep1,
                  style: TextStyle(fontWeight: FontWeight.w700, color: s.onSurface)),
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context).syncStep1Desc,
                  style: TextStyle(color: s.onSurfaceVariant)),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(AppLocalizations.of(context).syncCopyCode),
                ),
              ),
              const Divider(height: 32),
              Text(AppLocalizations.of(context).syncStep2,
                  style: TextStyle(fontWeight: FontWeight.w700, color: s.onSurface)),
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context).syncStep2Desc,
                  style: TextStyle(color: s.onSurfaceVariant)),
              const SizedBox(height: 8),
              TextField(
                controller: _input,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'LUMIO1.…',
                  suffixIcon: IconButton(
                    tooltip: AppLocalizations.of(context).syncPaste,
                    icon: const Icon(Icons.content_paste_rounded),
                    onPressed: _paste,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(onPressed: _import, child: Text(AppLocalizations.of(context).syncImport)),
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(_message!, style: TextStyle(color: _ok ? s.secondary : s.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(AppLocalizations.of(context).commonClose)),
      ],
    );
  }
}
