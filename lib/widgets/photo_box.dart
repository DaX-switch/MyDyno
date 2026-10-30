import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../db/repo.dart';
import '../models/vehicle.dart';
import '../services/photo_service.dart';

class PhotoBox extends StatefulWidget {
  final String vehicleId, tab;
  const PhotoBox({super.key, required this.vehicleId, required this.tab});
  @override
  State<PhotoBox> createState() => _PhotoBoxState();
}

class _PhotoBoxState extends State<PhotoBox> {
  List<PhotoRec> _ph = [];
  final Map<String, String> _paths = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = await Repo.photos(widget.vehicleId, widget.tab);
    for (final p in l) {
      _paths[p.fileName] = await PhotoService.pathFor(p.fileName);
    }
    if (mounted) setState(() => _ph = l);
  }

  Future<void> _add(ImageSource s) async {
    final x = await ImagePicker().pickImage(source: s);
    if (x == null) return;
    setState(() => _busy = true);
    try {
      final name = await PhotoService.saveCompressed(x.path, tab: widget.tab);
      await Repo.addPhoto(widget.vehicleId, widget.tab, name);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd zdjęcia: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _pick() {
    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Aparat'),
              onTap: () {
                Navigator.pop(c);
                _add(ImageSource.camera);
              }),
          ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(c);
                _add(ImageSource.gallery);
              }),
        ]),
      ),
    );
  }

  void _view(PhotoRec ph) {
    showDialog(
      context: context,
      builder: (c) => Dialog(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: InteractiveViewer(
                maxScale: 5, child: Image.file(File(_paths[ph.fileName]!))),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Usuń'),
              onPressed: () async {
                Navigator.pop(c);
                await Repo.removePhoto(ph);
                _load();
              },
            ),
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Zamknij')),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final p in _ph)
          GestureDetector(
            onTap: () => _view(p),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(_paths[p.fileName]!),
                  width: 96, height: 96, fit: BoxFit.cover, cacheWidth: 200),
            ),
          ),
        if (_ph.length < 3)
          InkWell(
            onTap: _busy ? null : _pick,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8)),
              child: _busy
                  ? const Center(child: CircularProgressIndicator())
                  : const Icon(Icons.add_a_photo_outlined),
            ),
          ),
      ]),
      const SizedBox(height: 4),
      Text('${_ph.length}/3 – zdjęcia są mocno kompresowane (podgląd/schemat).',
          style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
