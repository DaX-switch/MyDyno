import 'package:flutter/material.dart';
import '../constants.dart';
import '../db/repo.dart';
import '../models/vehicle.dart';
import '../widgets/share_dialog.dart';
import 'edit_screen.dart';
import 'settings_screen.dart';
import 'tabs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Vehicle> _all = [];
  String _q = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = await Repo.all();
    if (mounted) setState(() {
      _all = l;
      _loading = false;
    });
  }

  Future<void> _open(Widget w) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    _load();
  }

  List<Vehicle> get _filtered {
    final q = _q.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((v) {
      final s = '${v.brand} ${v.model} ${v.engineCode} ${v.year} ${v.stockPower} ${v.ecuFamily}'
          .toLowerCase();
      return q.split(RegExp(r'\s+')).every(s.contains);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: Text('My Dyno $kVersion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ustawienia',
            onPressed: () => _open(const SettingsScreen()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _open(const EditScreen()),
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SearchBar(
            hintText: 'Marka, model, silnik, rocznik, moc, ECU…',
            leading: const Icon(Icons.search),
            onChanged: (s) => setState(() => _q = s),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : list.isEmpty
                  ? Center(child: Text(_all.isEmpty ? 'Brak modeli – dodaj pierwszy (+)' : 'Brak wyników'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _card(list[i]),
                    ),
        ),
      ]),
    );
  }

  Widget _card(Vehicle v) {
    final tt = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () => _open(TabsScreen(vehicleId: v.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${v.brand} ${v.model}${v.year.isEmpty ? '' : ' · ${v.year}'}', style: tt.titleMedium),
            const SizedBox(height: 4),
            Text('${v.engineCode.isEmpty ? '–' : v.engineCode} · ${v.stockPower.isEmpty ? '–' : v.stockPower}'),
            Text('ECU: ${v.ecuFamily.isEmpty ? '–' : v.ecuFamily}'),
            Text('Ostatnia aktualizacja: ${fmtDate(v.updatedAt)}', style: tt.bodySmall),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Klonuj'),
                onPressed: () async {
                  await Repo.clone(v.id);
                  _load();
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Udostępnij'),
                onPressed: () => shareVehicle(context, v),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
