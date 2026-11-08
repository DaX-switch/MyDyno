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
  final TextEditingController _searchCtrl = TextEditingController();
  List<Vehicle> _all = [];
  String _q = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final l = await Repo.all();
    if (mounted) {
      setState(() {
        _all = l;
        _loading = false;
      });
    }
  }

  Future<void> _open(Widget w) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    _load();
  }

  List<Vehicle> get _filtered {
    final q = _q.trim().toLowerCase();
    if (q.isEmpty) return _all;

    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    return _all.where((v) {
      final mainInfo = '${v.brand} ${v.model} ${v.engineCode} ${v.year} ${v.stockPower} ${v.ecuFamily}'.toLowerCase();
      final extraData = v.data.values.map((val) => val.toString()).join(' ').toLowerCase();
      final fullSearchString = '$mainInfo $extraData';

      return tokens.every(fullSearchString.contains);
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Marka, model, silnik, rocznik, ECU…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_q.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Wyczyść',
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _q = '');
                    },
                  ),
              ],
              onChanged: (s) => setState(() => _q = s),
            ),
          ),
          if (_q.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Znaleziono: ${list.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? Center(
                        child: Text(
                          _all.isEmpty ? 'Brak modeli – dodaj pierwszy (+)' : 'Brak wyników dla „$_q”',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: list.length,
                        itemBuilder: (_, i) => _card(list[i]),
                      ),
          ),
        ],
      ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${v.brand} ${v.model}${v.year.isEmpty ? '' : ' · ${v.year}'}',
                style: tt.titleMedium,
              ),
              const SizedBox(height: 4),
              Text('${v.engineCode.isEmpty ? '–' : v.engineCode} · ${v.stockPower.isEmpty ? '–' : v.stockPower}'),
              Text('ECU: ${v.ecuFamily.isEmpty ? '–' : v.ecuFamily}'),
              Text('Ostatnia aktualizacja: ${fmtDate(v.updatedAt)}', style: tt.bodySmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}