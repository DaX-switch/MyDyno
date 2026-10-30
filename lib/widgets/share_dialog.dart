import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/backup_service.dart';

/// Dialog eksportu .mydyno – domyślnie zaznaczone "Usuń dane cenowe z eksportu".
Future<void> shareVehicle(BuildContext context, Vehicle v) async {
  var strip = true;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setS) => AlertDialog(
        title: const Text('Udostępnij / Eksportuj ten model'),
        content: CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: strip,
          title: const Text('Usuń dane cenowe z eksportu'),
          subtitle: const Text('Czyści historię cen, ceny klienta i koszty Mastera.'),
          onChanged: (b) => setS(() => strip = b ?? true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Eksportuj')),
        ],
      ),
    ),
  );
  if (ok != true) return;
  try {
    await BackupService.exportVehicle(v, stripPrices: strip);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd eksportu: $e')));
    }
  }
}
