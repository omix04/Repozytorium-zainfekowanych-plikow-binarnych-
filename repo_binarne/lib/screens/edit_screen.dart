import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/firebase_repository.dart';
import '../models/binary_item.dart';

class EditItemScreen extends StatefulWidget {
  final BinaryItem? item; // null = dodawanie, != null = edycja
  const EditItemScreen({super.key, this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = FirebaseRepository();

  late final TextEditingController _fileName;
  late final TextEditingController _fileNameDesc;

  late final TextEditingController _format;
  late final TextEditingController _formatDesc;

  late final TextEditingController _platform;
  late final TextEditingController _platformDesc;

  late final TextEditingController _source;
  late final TextEditingController _sourceDesc;

  late final TextEditingController _status;
  late final TextEditingController _statusDesc;

  late final TextEditingController _storagePath;
  late final TextEditingController _storagePathDesc;

  bool _saving = false;

  bool get _isAdmin {
    final u = FirebaseAuth.instance.currentUser;
    return u != null && !u.isAnonymous && u.email == 'omix041@gmail.com';
  }

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
    _storagePathDesc =
        TextEditingController(text: it?.storagePathDescription ?? '');
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

  Future<void> _save() async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tylko admin (omix041@gmail.com) może modyfikować dane.'),
        ),
      );
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
      );

      if (isEdit) {
        await _repo.updateItem(item);
      } else {
        await _repo.addItem(item);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd zapisu: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edytuj (ADMIN)' : 'Dodaj (ADMIN)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _title('fileName'),
              TextFormField(
                controller: _fileName,
                decoration: const InputDecoration(labelText: 'Wartość (np. sample.exe)'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wymagane' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fileNameDesc,
                decoration: const InputDecoration(labelText: 'Opis znaczenia'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              _title('format'),
              TextFormField(
                controller: _format,
                decoration: const InputDecoration(labelText: 'Wartość (exe/jpg/png)'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wymagane' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _formatDesc,
                decoration: const InputDecoration(labelText: 'Opis znaczenia'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              _title('platform'),
              TextFormField(
                controller: _platform,
                decoration: const InputDecoration(labelText: 'Wartość (np. Windows)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _platformDesc,
                decoration: const InputDecoration(labelText: 'Opis znaczenia'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              _title('source'),
              TextFormField(
                controller: _source,
                decoration: const InputDecoration(labelText: 'Wartość (np. paczka)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _sourceDesc,
                decoration: const InputDecoration(labelText: 'Opis znaczenia'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              _title('status'),
              TextFormField(
                controller: _status,
                decoration: const InputDecoration(labelText: 'Wartość (to analysis/infected)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _statusDesc,
                decoration: const InputDecoration(labelText: 'Opis znaczenia'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              _title('storagePath'),
              TextFormField(
                controller: _storagePath,
                decoration: const InputDecoration(labelText: 'Wartość (binaries/sample.exe)'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wymagane' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _storagePathDesc,
                decoration: const InputDecoration(labelText: 'Opis znaczenia'),
                maxLines: 2,
              ),
              const SizedBox(height: 22),

              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save),
                label: Text(_saving ? 'Zapisywanie...' : 'Zapisz'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(String name) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );
}
