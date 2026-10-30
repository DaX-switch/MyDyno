import 'package:flutter/material.dart';

double? parsePrice(Object? s) =>
    s == null ? null : double.tryParse(s.toString().replaceAll(',', '.').trim());

/// Mini-moduł cenowy: cena klienta (ostatnia) + średnia, opcjonalnie koszt Mastera + marża.
class PriceBox extends StatefulWidget {
  final Map<String, dynamic> tab;
  final bool slave;
  const PriceBox({super.key, required this.tab, required this.slave});
  @override
  State<PriceBox> createState() => _PriceBoxState();
}

class _PriceBoxState extends State<PriceBox> {
  @override
  Widget build(BuildContext context) {
    final t = widget.tab;
    final hist = ((t['price_history'] as List?) ?? []).map((e) => (e as num).toDouble()).toList();
    final cur = parsePrice(t['price_last']);
    final all = [...hist];
    if (cur != null && (hist.isEmpty || hist.last != cur)) all.add(cur);
    final avg = all.isEmpty ? null : all.reduce((a, b) => a + b) / all.length;
    final master = parsePrice(t['master_cost']);
    final margin = (cur != null && master != null) ? cur - master : null;
    String z(double? v) => v == null ? '–' : '${v.toStringAsFixed(2)} zł';

    return Column(children: [
      TextFormField(
        initialValue: (t['price_last'] ?? '').toString(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Cena dla klienta (ostatnia) zł'),
        onChanged: (s) => setState(() => t['price_last'] = s),
      ),
      Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text('Średnia cena: ${z(avg)}  (${all.length} wycen)'),
          )),
      if (widget.slave) ...[
        TextFormField(
          initialValue: (t['master_cost'] ?? '').toString(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Koszt u Mastera / za plik (zł)'),
          onChanged: (s) => setState(() => t['master_cost'] = s),
        ),
        Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('Marża na czysto: ${z(margin)}'),
            )),
      ],
    ]);
  }
}
