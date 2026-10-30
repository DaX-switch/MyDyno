import 'dart:convert';
import 'package:flutter/material.dart';
import '../db/repo.dart';
import '../models/vehicle.dart';
import '../services/gemini_service.dart';
import 'tabs_screen.dart';

const _brands = [
  'Audi', 'BMW', 'Citroën', 'Dacia', 'Fiat', 'Ford', 'Honda', 'Hyundai', 'Kia',
  'Mazda', 'Mercedes-Benz', 'Mitsubishi', 'Nissan', 'Opel', 'Peugeot', 'Renault',
  'Seat', 'Škoda', 'Toyota', 'Volkswagen', 'Volvo',
];

class EditScreen extends StatefulWidget {
  final String? vehicleId;
  final bool fromTabs;
  const EditScreen({super.key, this.vehicleId, this.fromTabs = false});
  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  Vehicle? _v;
  List<String> _dbBrands = [], _dbModels = [];
  String _brand = '', _model = '';
  final _year = TextEditingController();
  final _engine = TextEditingController();
  final _power = TextEditingController();
  final _ecu = TextEditingController();
  bool _ready = false, _ai = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _dbBrands = await Repo.distinct('brand');
    _dbModels = await Repo.distinct('model');
    if (widget.vehicleId != null) {
      final v = await Repo.get(widget.vehicleId!);
      if (v != null) {
        _v = v;
        _brand = v.brand;
        _model = v.model;
        _year.text = v.year;
        _engine.text = v.engineCode;
        _power.text = v.stockPower;
        _ecu.text = v.ecuFamily;
      }
    }
    if (mounted) setState(() => _ready = true);
  }

  Widget _auto(String label, String init, List<String> opts, void Function(String) set) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: init),
      optionsBuilder: (t) => t.text.isEmpty
          ? const Iterable<String>.empty()
          : opts.where((o) => o.toLowerCase().contains(t.text.toLowerCase())),
      onSelected: set,
      fieldViewBuilder: (c, ctrl, focus, _) => TextField(
        controller: ctrl,
        focusNode: focus,
        decoration: InputDecoration(labelText: label),
        onChanged: set,
      ),
    );
  }

  Future<void> _autofill() async {
    if (_brand.trim().isEmpty || _model.trim().isEmpty) {
      _snack('Najpierw wpisz markę i model.');
      return;
    }
    setState(() => _ai = true);
    try {
      final r = await GeminiService.ask(
          'Pojazd: $_brand $_model ${_year.text}. Zwróć WYŁĄCZNIE JSON: '
          '{"engine_code":"","power_hp":"","torque_nm":"","ecu_family":""}. '
          'Podaj najbardziej prawdopodobny silnik (przy kilku – kody po przecinku). '
          'Nie znasz – zostaw puste. Bez komentarzy.');
      final m = RegExp(r'\{[\s\S]*\}').firstMatch(r);
      if (m == null) throw 'Niepoprawna odpowiedź AI.';
      final j = jsonDecode(m.group(0)!) as Map<String, dynamic>;
      setState(() {
        if ('${j['engine_code']}'.isNotEmpty) _engine.text = '${j['engine_code']}';
        final hp = '${j['power_hp'] ?? ''}', nm = '${j['torque_nm'] ?? ''}';
        if (hp.isNotEmpty || nm.isNotEmpty) {
          _power.text = '${hp.isEmpty ? '?' : hp} KM / ${nm.isEmpty ? '?' : nm} Nm';
        }
        if ('${j['ecu_family']}'.isNotEmpty) _ecu.text = '${j['ecu_family']}';
      });
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _ai = false);
    }
  }

  void _snack(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> _save() async {
    if (_brand.trim().isEmpty || _model.trim().isEmpty) {
      _snack('Marka i model są wymagane.');
      return;
    }
    final v = _v ?? Vehicle(id: Repo.newId());
    v
      ..brand = _brand.trim()
      ..model = _model.trim()
      ..year = _year.text.trim()
      ..engineCode = _engine.text.trim()
      ..stockPower = _power.text.trim()
      ..ecuFamily = _ecu.text.trim();
    await Repo.save(v);
    if (!mounted) return;
    if (widget.fromTabs) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => TabsScreen(vehicleId: v.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final brands = {..._brands, ..._dbBrands}.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: Text(_v == null ? 'Nowy model' : 'Edycja modelu')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _auto('Marka', _brand, brands, (s) => _brand = s),
        const SizedBox(height: 8),
        _auto('Model', _model, _dbModels, (s) => _model = s),
        const SizedBox(height: 8),
        TextField(controller: _year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rocznik')),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _ai ? null : _autofill,
          icon: _ai
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.auto_awesome),
          label: const Text('Autouzupełnij przez AI'),
        ),
        const SizedBox(height: 8),
        TextField(controller: _engine, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Kod silnika')),
        const SizedBox(height: 8),
        TextField(controller: _power, decoration: const InputDecoration(labelText: 'Moc seryjna KM / Nm')),
        const SizedBox(height: 8),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Zapisz i przejdź do zakładek'),
        ),
      ]),
    );
  }
}
