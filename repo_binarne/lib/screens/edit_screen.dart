import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  late final TextEditingController _fileName,
      _fileNameDesc,
      _format,
      _formatDesc,
      _platform,
      _platformDesc,
      _source,
      _sourceDesc,
      _status,
      _statusDesc,
      _storagePath,
      _storagePathDesc;

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
    _storagePathDesc = TextEditingController(
      text: it?.storagePathDescription ?? '',
    );
  }

  Future<void> _verifyMd5() async {
    if (widget.item == null) {
      _showMsg("Zapisz dokument przed weryfikacją.");
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await _repo.triggerMd5Check(
        _storagePath.text,
        widget.item!.id,
      );
      if (mounted) _showDialog("Sukces", "Suma MD5: ${res['md5']}");
    } catch (e) {
      if (mounted) _showDialog("Błąd", "Weryfikacja nieudana: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showDialog(String t, String c) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(t),
      content: Text(c),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );
  void _showMsg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item != null ? 'Edytuj metadane' : 'Dodaj metadane'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildField("fileName", _fileName, _fileNameDesc),
            _buildField("format", _format, _formatDesc),
            _buildField("platform", _platform, _platformDesc),
            _buildField("source", _source, _sourceDesc),
            _buildField("status", _status, _statusDesc),
            _buildField("storagePath", _storagePath, _storagePathDesc),
            const SizedBox(height: 10),
            if (widget.item != null)
              OutlinedButton.icon(
                onPressed: _saving ? null : _verifyMd5,
                icon: const Icon(Icons.security),
                label: const Text("Weryfikuj MD5 na serwerze"),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? "Czekaj..." : "Zapisz"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController val,
    TextEditingController desc,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        TextFormField(
          controller: val,
          decoration: const InputDecoration(hintText: "Wartość"),
        ),
        TextFormField(
          controller: desc,
          decoration: const InputDecoration(hintText: "Opis"),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _save() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null || u.isAnonymous) {
      _showMsg('Tylko zalogowani mogą edytować/dodawać metadane');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final isEdit = widget.item != null;

      final item = BinaryItem(
        id: widget.item?.id ?? '',
        fileName: _fileName.text.trim(),
        fileNameDescription: _fileNameDesc.text.trim(),
        format: _format.text.trim().toLowerCase(),
        formatDescription: _formatDesc.text.trim(),
        platform: _platform.text.trim(),
        platformDescription: _platformDesc.text.trim(),
        source: _source.text.trim(),
        sourceDescription: _sourceDesc.text.trim(),
        status: _status.text.trim(),
        statusDescription: _statusDesc.text.trim(),
        storagePath: _storagePath.text.trim(),
        storagePathDescription: _storagePathDesc.text.trim(),
        md5: widget.item?.md5,
        lastVerified: widget.item?.lastVerified,
      );

      if (isEdit) {
        await _repo.updateItem(item);
      } else {
        await _repo.addItem(item);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _showMsg('Błąd zapisu: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _fileName.dispose();
    _fileNameDesc.dispose();
    _format.dispose();
    _formatDesc.dispose();
    _platform.dispose();
    _platformDesc.dispose();
    _source.dispose();
    _sourceDesc.dispose();
    _status.dispose();
    _statusDesc.dispose();
    _storagePath.dispose();
    _storagePathDesc.dispose();
    super.dispose();
  }
}
