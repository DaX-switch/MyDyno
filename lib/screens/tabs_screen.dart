import 'package:flutter/material.dart';
import '../constants.dart';
import '../db/repo.dart';
import '../models/vehicle.dart';
import '../services/prefs_service.dart';
import '../widgets/price_box.dart';
import '../widgets/share_dialog.dart';
import '../widgets/tab_view.dart';
import '../widgets/tabs_spec.dart';
import 'edit_screen.dart';

class TabsScreen extends StatefulWidget {
  final String vehicleId;
  const TabsScreen({super.key, required this.vehicleId});
  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  bool _deleted = false;
  Vehicle? _v;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await Repo.get(widget.vehicleId);
    if (mounted) {
      setState(() {
        _v = v;
        _gen++;
      });
    }
  }

  /// Dopisuje ostatnią cenę do historii (jeśli się zmieniła) i zapisuje rekord.
  Future<void> _save() async {
    if (_deleted) return;
    final v = _v;
    if (v == null) return;
    for (final e in v.data.entries) {
      final t = e.value;
      if (t is Map<String, dynamic>) {
        final cur = parsePrice(t['price_last']);
        if (cur != null) {
          final h = ((t['price_history'] as List?) ?? []).toList();
          if (h.isEmpty || (h.last as num).toDouble() != cur) h.add(cur);
          t['price_history'] = h;
        }
      }
    }
    await Repo.save(v);
  }

  @override
  Widget build(BuildContext context) {
    final v = _v;
    if (v == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final tabs = kTabs.where((t) => !t.dyno || Prefs.showDyno).toList();
    return DefaultTabController(
      length: tabs.length,
      child: PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) _save();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('${v.brand} ${v.model}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edytuj dane modelu',
                onPressed: () async {
                  await _save();
                  if (!mounted) return;
                  final r = await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => EditScreen(vehicleId: v.id, fromTabs: true)));
                  if (r == true) _load();
                },
              ),
              PopupMenuButton<String>(
                onSelected: (s) async {
                  if (s == 'share') {
                    await _save();
                    if (mounted) shareVehicle(context, v);
                  } else if (s == 'delete') {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Usunąć model?'),
                        content: const Text('Operacji nie można cofnąć.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Anuluj')),
                          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Usuń')),
                        ],
                      ),
                    );
                    if (ok == true) {
                      _deleted = true;
                      try {
                        await Repo.delete(v.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Usunięto pomyślnie')),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Błąd usuwania: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'share', child: Text('Udostępnij / Eksportuj ten model')),
                  PopupMenuItem(value: 'delete', child: Text('Usuń model')),
                ],
              ),
            ],
          ),
          body: Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                '${v.year} · ${v.engineCode} · ${v.stockPower} · ECU: ${v.ecuFamily}\n'
                'Ostatnia aktualizacja: ${fmtDate(v.updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TabBar(isScrollable: true, tabs: [for (final t in tabs) Tab(text: t.title)]),
            Expanded(
              child: TabBarView(children: [
                for (final t in tabs) TabView(key: ValueKey('${t.key}-$_gen'), v: v, spec: t),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
