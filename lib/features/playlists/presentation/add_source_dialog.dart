import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/network/xtream_client.dart';
import '../../../platform_channels/tv_provider.dart';
import '../playlist_providers.dart';

Future<void> showAddSourceDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const AddSourceDialog());

class AddSourceDialog extends ConsumerStatefulWidget {
  const AddSourceDialog({super.key});

  @override
  ConsumerState<AddSourceDialog> createState() => _AddSourceDialogState();
}

class _AddSourceDialogState extends ConsumerState<AddSourceDialog> {
  final _url = TextEditingController();
  final _host = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  String? _error;

  @override
  void dispose() {
    for (final c in [_url, _host, _user, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  void _done(void Function(PlaylistController) load) {
    load(ref.read(playlistProvider.notifier));
    Navigator.of(context).pop();
  }

  void _submitUrl() {
    final v = _url.text.trim();
    if (!(Uri.tryParse(v)?.hasScheme ?? false)) {
      setState(() => _error = AppLocalizations.of(context).errUrlInvalid);
      return;
    }
    _done((n) => n.loadUrl(v));
  }

  Future<void> _pickFile() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['m3u', 'm3u8', 'txt'],
    );
    final path = r?.files.single.path;
    if (path == null || !mounted) return;
    _done((n) => n.loadFile(path));
  }

  void _submitXtream() {
    if ([_host, _user, _pass].any((c) => c.text.trim().isEmpty)) {
      setState(() => _error = AppLocalizations.of(context).errFillXtream);
      return;
    }
    final creds = XtreamCredentials(
        host: _host.text, username: _user.text.trim(), password: _pass.text);
    _done((n) => n.loadXtream(creds));
  }

  @override
  Widget build(BuildContext context) {
    // En TV (mando, sin gestor de archivos) no se ofrece "Archivo".
    final tv = ref.watch(isTelevisionProvider).valueOrNull ?? false;
    return DefaultTabController(
      length: tv ? 2 : 3,
      child: AlertDialog(
        title: Text(AppLocalizations.of(context).addSource),
        content: SizedBox(
          width: 460,
          height: 340,
          child: Column(
            children: [
              TabBar(tabs: [
                Tab(text: AppLocalizations.of(context).tabUrl),
                if (!tv) Tab(text: AppLocalizations.of(context).tabFile),
                const Tab(text: 'Xtream Codes'),
              ]),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(children: [
                  _Pane(children: [
                    TextField(
                      controller: _url,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).fieldListUrl, border: const OutlineInputBorder()),
                      onSubmitted: (_) => _submitUrl(),
                    ),
                    FilledButton(onPressed: _submitUrl, child: Text(AppLocalizations.of(context).addList)),
                  ]),
                  if (!tv)
                    _Pane(children: [
                      Text(AppLocalizations.of(context).pickFileHint),
                      FilledButton.icon(
                        icon: const Icon(Icons.folder_open),
                        label: Text(AppLocalizations.of(context).pickFile),
                        onPressed: _pickFile,
                      ),
                    ]),
                  _Pane(children: [
                    // textInputAction: con el mando, "Siguiente" en el teclado de pantalla
                    // pasa al campo siguiente y "Listo" envía el formulario.
                    TextField(
                      controller: _host,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).fieldServer,
                          border: const OutlineInputBorder()),
                    ),
                    TextField(
                      controller: _user,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).fieldUser, border: const OutlineInputBorder()),
                    ),
                    TextField(
                      controller: _pass,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).fieldPassword, border: const OutlineInputBorder()),
                      onSubmitted: (_) => _submitXtream(),
                    ),
                    FilledButton(onPressed: _submitXtream, child: Text(AppLocalizations.of(context).connect)),
                  ]),
                ]),
              ),
              if (_error != null)
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(AppLocalizations.of(context).commonCancel)),
        ],
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final w in children) Padding(padding: const EdgeInsets.only(bottom: 12), child: w),
          ],
        ),
      );
}
