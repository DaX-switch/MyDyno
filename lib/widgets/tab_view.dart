import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/gemini_service.dart';
import '../services/prefs_service.dart';
import 'photo_box.dart';
import 'price_box.dart';
import 'tabs_spec.dart';

class TabView extends StatefulWidget {
  final Vehicle v;
  final TabSpec spec;
  const TabView({super.key, required this.v, required this.spec});
  @override
  State<TabView> createState() => _TabViewState();
}

class _TabViewState extends State<TabView> {
  bool _loading = false;
  Map<String, dynamic> get t => widget.v.tab(widget.spec.key);

  Widget _field(F f) {
    switch (f.type) {
      case FT.check:
        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(f.label),
          value: t[f.key] == true,
          onChanged: (b) => setState(() => t[f.key] = b ?? false),
        );
      case FT.choice:
        final cur = t[f.key];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: DropdownButtonFormField<String>(
            value: f.opts.contains(cur) ? cur as String : null,
            decoration: InputDecoration(labelText: f.label),
            items: [for (final o in f.opts) DropdownMenuItem(value: o, child: Text(o))],
            onChanged: (s) => setState(() => t[f.key] = s),
          ),
        );
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: TextFormField(
            initialValue: (t[f.key] ?? '').toString(),
            minLines: f.type == FT.multi ? 2 : 1,
            maxLines: f.type == FT.multi ? 6 : 1,
            decoration: InputDecoration(labelText: f.label),
            onChanged: (s) => t[f.key] = s,
          ),
        );
    }
  }

  String _prompt() {
    final v = widget.v;
    final b = StringBuffer(
        'Jesteś doświadczonym chiptunerem. Pojazd: ${v.brand} ${v.model} ${v.year}, '
        'silnik ${v.engineCode}, ${v.stockPower}, ECU ${v.ecuFamily}.\n'
        'Temat: ${widget.spec.aiTopic}.\n');
    for (final s in widget.spec.secs) {
      for (final f in s.fields) {
        final val = t[f.key];
        if (val != null && val.toString().isNotEmpty && val != false) {
          b.writeln('${f.label}: $val');
        }
      }
    }
    b.write('Odpowiedz po polsku, maksymalnie 1–3 krótkie hasła, bez wstępu i bez wyjaśnień.');
    return b.toString();
  }

  Future<void> _ai() async {
    setState(() => _loading = true);
    try {
      final r = await GeminiService.ask(_prompt());
      setState(() => t['ai_hint'] = r);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final secs = spec.secs.where((s) => !s.road || Prefs.roadDyno).toList();
    final hint = (t['ai_hint'] ?? '').toString();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
      children: [
        for (var i = 0; i < secs.length; i++)
          Card(
            child: ExpansionTile(
              initiallyExpanded: i == 0,
              title: Text(secs[i].title),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              children: [for (final f in secs[i].fields) _field(f)],
            ),
          ),
        Card(
          child: ExpansionTile(
            title: const Text('Zdjęcia'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: PhotoBox(vehicleId: widget.v.id, tab: spec.key)),
            ],
          ),
        ),
        Card(
          child: ExpansionTile(
            title: const Text('Wycena'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [PriceBox(tab: t, slave: Prefs.slaveMode)],
          ),
        ),
        if (spec.ai) ...[
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _loading ? null : _ai,
            icon: _loading
                ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            label: const Text('Podpowiedź AI'),
          ),
          if (hint.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(hint),
            ),
        ],
      ],
    );
  }
}
