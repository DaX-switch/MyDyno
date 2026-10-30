import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../services/backup_service.dart';
import '../services/gemini_service.dart';
import '../services/prefs_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _key = TextEditingController();
  bool _hide = true, _busy = false;

  @override
  void initState() {
    super.initState();
    GeminiService.key().then((k) => setState(() => _key.text = k ?? ''));
  }

  void _snack(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> _link(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      _snack('Nie można otworzyć linku.');
    }
  }

  Future<String?> _pickFile({List<String>? ext}) async {
    final r = await FilePicker.pickFiles(type: FileType.any);
    final path = r.single.path;
    if (path == null) return null;
    if (ext != null && !ext.any((e) => path.toLowerCase().endsWith(e))) {
      _snack('Wybierz plik: ${ext.join(' / ')}');
      return null;
    }
    return path;
  }

  Future<void> _run(Future<String> Function() job) async {
    setState(() => _busy = true);
    try {
      _snack(await job());
    } catch (e) {
      _snack('Błąd: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String msg) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Potwierdź'),
          content: Text(msg),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Anuluj')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Kontynuuj')),
          ],
        ),
      ) ??
      false;

  Widget _h(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(t, style: Theme.of(context).textTheme.titleMedium),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: Stack(children: [
        ListView(children: [
          _h('Wersja'),
          const ListTile(title: Text(kVersion)),

          _h('Konfiguracja modułów warsztatu'),
          SwitchListTile(
            title: const Text('Pokaż zakładkę Hamownia'),
            value: Prefs.showDyno,
            onChanged: (b) async {
              await Prefs.setShowDyno(b);
              setState(() {});
            },
          ),
          SwitchListTile(
            title: const Text('Uwzględniaj sekcję Hamownia Drogowa'),
            value: Prefs.roadDyno,
            onChanged: (b) async {
              await Prefs.setRoadDyno(b);
              setState(() {});
            },
          ),
          SwitchListTile(
            title: const Text('Tryb Slave (Pokaż koszt Mastera / pliku)'),
            value: Prefs.slaveMode,
            onChanged: (b) async {
              await Prefs.setSlaveMode(b);
              setState(() {});
            },
          ),

          _h('Changelog / O projekcie'),
          const ListTile(
            title: Text('Aplikacja powstała na potrzeby mojej słabej pamięci i będę ją '
                'rozbudowywał o moje wizje i potrzeby.'),
          ),
          const ListTile(
            title: Text('Zdjęcia są bardzo mocno kompresowane, aby nie zapychać pamięci '
                'urządzenia i zachować lekki backup – używaj ich z rozwagą (jako '
                'schematy/notatki poglądowe, a nie archiwum w wysokiej rozdzielczości).'),
          ),

          _h('O autorze'),
          Center(
            child: Image.asset('assets/images/logo.png',
                height: 96,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.car_repair, size: 72)),
          ),
          const ListTile(title: Text('DaX Chiptuning')),
          ListTile(
            leading: const Icon(Icons.facebook),
            title: const Text('FB.com/zapomnienie'),
            onTap: () => _link(kFbUrl),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.icon(
              icon: const Icon(Icons.coffee),
              label: const Text('Postaw kawę (Buy Me a Coffee)'),
              onPressed: () => _link(kCoffeeUrl),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text('Aplikacja całkowicie darmowa, ale jeśli ułatwia Ci pracę – '
                'możesz postawić kawę ;)'),
          ),

          _h('Klucz API Gemini'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              TextField(
                controller: _key,
                obscureText: _hide,
                decoration: InputDecoration(
                  labelText: 'Klucz API Gemini (BYOK)',
                  suffixIcon: IconButton(
                    icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: () async {
                    await GeminiService.setKey(_key.text);
                    _snack('Klucz zapisany bezpiecznie.');
                  },
                  child: const Text('Zapisz klucz'),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Darmowy klucz: wejdź na aistudio.google.com, zaloguj się kontem '
                  'Google, wybierz „Get API key” → „Create API key” i wklej go powyżej. '
                  'Klucz jest przechowywany tylko na tym telefonie.'),
              TextButton(
                  onPressed: () => _link('https://aistudio.google.com/apikey'),
                  child: const Text('Otwórz aistudio.google.com')),
            ]),
          ),

          _h('Kopia zapasowa i Wymiana baz'),
          ListTile(
            leading: const Icon(Icons.archive),
            title: const Text('Eksportuj pełny backup do ZIP'),
            onTap: () => _run(() async {
              await BackupService.exportFull();
              return 'Backup gotowy.';
            }),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Przywróć z ZIP (Zastąp)'),
            onTap: () async {
              final p = await _pickFile(ext: ['.zip']);
              if (p == null) return;
              if (!await _confirm('Cała obecna baza i zdjęcia zostaną ZASTĄPIONE. '
                  '(Kopia bezpieczeństwa zostanie zrobiona automatycznie.)')) return;
              _run(() async {
                await BackupService.restoreFull(p);
                return 'Baza przywrócona.';
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.merge),
            title: const Text('Scal z pliku ZIP / .mydyno (Merge)'),
            onTap: () async {
              final p = await _pickFile(ext: ['.zip', '.mydyno']);
              if (p == null) return;
              _run(() async {
                final n = await BackupService.merge(p);
                return 'Zaimportowano modeli: $n (oznaczone [Import]).';
              });
            },
          ),
          const SizedBox(height: 32),
        ]),
        if (_busy)
          const ColoredBox(
              color: Colors.black38, child: Center(child: CircularProgressIndicator())),
      ]),
    );
  }
}
