import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/xtream_client.dart';
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
      setState(() => _error = 'Introduce una URL completa (http:// o https://)');
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
      setState(() => _error = 'Rellena servidor, usuario y contraseña');
      return;
    }
    final creds = XtreamCredentials(
        host: _host.text, username: _user.text.trim(), password: _pass.text);
    _done((n) => n.loadXtream(creds));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: AlertDialog(
        title: const Text('Añadir fuente'),
        content: SizedBox(
          width: 460,
          height: 340,
          child: Column(
            children: [
              const TabBar(tabs: [
                Tab(text: 'URL M3U'),
                Tab(text: 'Archivo'),
                Tab(text: 'Xtream Codes'),
              ]),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(children: [
                  _Pane(children: [
                    TextField(
                      controller: _url,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                          labelText: 'URL de la lista', border: OutlineInputBorder()),
                      onSubmitted: (_) => _submitUrl(),
                    ),
                    FilledButton(onPressed: _submitUrl, child: const Text('Añadir lista')),
                  ]),
                  _Pane(children: [
                    const Text('Selecciona un archivo .m3u / .m3u8 de tu equipo.'),
                    FilledButton.icon(
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Elegir archivo'),
                      onPressed: _pickFile,
                    ),
                  ]),
                  _Pane(children: [
                    TextField(
                      controller: _host,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                          labelText: 'Servidor (http://host:puerto)',
                          border: OutlineInputBorder()),
                    ),
                    TextField(
                      controller: _user,
                      decoration: const InputDecoration(
                          labelText: 'Usuario', border: OutlineInputBorder()),
                    ),
                    TextField(
                      controller: _pass,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Contraseña', border: OutlineInputBorder()),
                      onSubmitted: (_) => _submitXtream(),
                    ),
                    FilledButton(onPressed: _submitXtream, child: const Text('Conectar')),
                  ]),
                ]),
              ),
              if (_error != null)
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
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
