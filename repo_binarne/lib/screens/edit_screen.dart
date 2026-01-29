import 'package:flutter/material.dart';
import '../data/firebase_repository.dart';
import '../models/binary_item.dart';

class EditItemScreen extends StatefulWidget {
  final BinaryItem? item;
  const EditItemScreen({super.key, this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = FirebaseRepository();

  late final TextEditingController _fileName, _fileNameDesc, _format, _formatDesc,
      _platform, _platformDesc, _source, _sourceDesc, _status, _statusDesc,
      _storagePath, _storagePathDesc;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _fileName = TextEditingController(text: it?.fileName ?? '');
    _fileNameDesc = TextEditingController(text: it?.fileNameDescription ?? '');
    _format = TextEditingController(text: it?.format ?? '');
    _formatDesc = TextEditingController(text: it?.formatDescription ?? '');
    _platform = TextEditingController(text: it?.platform ?? '');
    _platformDesc = TextEditingController(text: it?.platformDescription ?? '');
    _source = TextEditingController(text: it?.source ?? '');
    _sourceDesc = TextEditingController(text: it?.sourceDescription ?? '');
    _status = TextEditingController(text: it?.status ?? '');
    _statusDesc = TextEditingController(text: it?.statusDescription ?? '');
    _storagePath = TextEditingController(text: it?.storagePath ?? '');
    _storagePathDesc = TextEditingController(text: it?.storagePathDescription ?? '');
  }

  Future<void> _verifyMd5() async {
    if (widget.item == null) {
      _showMsg("Zapisz dokument przed weryfikacją.");
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await _repo.triggerMd5Check(_storagePath.text, widget.item!.id);
      if (mounted) _showDialog("Sukces", "Suma MD5: ${res['md5']}");
    } catch (e) {
      if (mounted) _showDialog("Błąd", "Weryfikacja nieudana: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showDialog(String t, String c) => showDialog(context: context, builder: (_) => AlertDialog(title: Text(t), content: Text(c), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))]));
  void _showMsg(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item != null ? 'Edytuj (ADMIN)' : 'Dodaj (ADMIN)')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildField("fileName", _fileName, _fileNameDesc),
            _buildField("storagePath", _storagePath, _storagePathDesc),
            const SizedBox(height: 10),
            if (widget.item != null)
              OutlinedButton.icon(
                onPressed: _saving ? null : _verifyMd5,
                icon: const Icon(Icons.security),
                label: const Text("Weryfikuj MD5 na serwerze"),
              ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saving ? null : _save, child: Text(_saving ? "Czekaj..." : "Zapisz")),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController val, TextEditingController desc) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      TextFormField(controller: val, decoration: const InputDecoration(hintText: "Wartość")),
      TextFormField(controller: desc, decoration: const InputDecoration(hintText: "Opis"), maxLines: 2),
      const SizedBox(height: 16),
    ]);
  }

  Future<void> _save() async {}
}