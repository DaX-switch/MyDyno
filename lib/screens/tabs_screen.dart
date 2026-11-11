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
  final bool embedded;
  final VoidCallback? onUpdated;

  const TabsScreen({
    super.key,
    required this.vehicleId,
    this.embedded = false,
    this.onUpdated,
  });

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

  @override
  void didUpdateWidget(covariant TabsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicleId != widget.vehicleId) {
      _save();
      _load();
    }
  }

  @override
  void dispose() {
    _save();
    super.dispose();
  }

  Future<void> _load() async {
    final v = await Repo.get(widget.vehicleId);
    if (!mounted) return;
    setState(() {
      _v = v;
      _gen++;
    });
  }

  Future<void> _save() async {
    if (_deleted) return;
    final v = _v;
    if (v == null) return;

    String? foundEcu;
    for (final e in v.data.entries) {
      final t = e.value;
      if (t is Map<String, dynamic>) {
        if (t.containsKey('ecu_family') && t['ecu_family'] != null) {
          final val = t['ecu_family'].toString().trim();
          if (val.isNotEmpty) {
            foundEcu = val;
            break;
          }
        }
      }
    }

    if (foundEcu == null && v.data.containsKey('ecu_family')) {
      final val = v.data['ecu_family'].toString().trim();
      if (val.isNotEmpty) foundEcu = val;
    }

    if (foundEcu != null && foundEcu.isNotEmpty && v.ecuFamily != foundEcu) {
      v.ecuFamily = foundEcu;
      if (mounted) setState(() {});
    }

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
    widget.onUpdated?.call();
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
            automaticallyImplyLeading: !widget.embedded,
            title: Text('${v.brand} ${v.model}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edytuj dane modelu',
                onPressed: () async {
                  await _save();
                  if (!context.mounted) return;
                  final r = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditScreen(vehicleId: v.id, fromTabs: true)),
                  );
                  if (r == true) _load();
                },
              ),
              PopupMenuButton<String>(
                onSelected: (s) async {
                  if (s == 'share') {
                    await _save();
                    if (context.mounted) shareVehicle(context, v);
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
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Usunięto pomyślnie')),
                          );
                          if (!widget.embedded) {
                            Navigator.pop(context);
                          } else {
                            widget.onUpdated?.call();
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
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
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  '${v.year} · ${v.engineCode} · ${v.stockPower} · ECU: ${v.ecuFamily.isEmpty ? '–' : v.ecuFamily}\n'
                  'Ostatnia aktualizacja: ${fmtDate(v.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TabBar(isScrollable: true, tabs: [for (final t in tabs) Tab(text: t.title)]),
              Expanded(
                child: TabBarView(
                  children: [
                    for (final t in tabs) TabView(key: ValueKey('${t.key}-$_gen'), v: v, spec: t),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
