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
  late final TextEditingController _format;
  late final TextEditingController _platform;
  late final TextEditingController _source;
  late final TextEditingController _status;
  late final TextEditingController _storagePath;

  bool _saving = false;

  bool get _isLoggedIn {
    final u = FirebaseAuth.instance.currentUser;
    return u != null && !u.isAnonymous;
  }

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _fileName = TextEditingController(text: it?.fileName ?? '');
    _format = TextEditingController(text: it?.format ?? '');
    _platform = TextEditingController(text: it?.platform ?? '');
    _source = TextEditingController(text: it?.source ?? '');
    _status = TextEditingController(text: it?.status ?? '');
    _storagePath = TextEditingController(text: it?.storagePath ?? '');
  }

  @override
  void dispose() {
    _fileName.dispose();
    _format.dispose();
    _platform.dispose();
    _source.dispose();
    _status.dispose();
    _storagePath.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tylko zalogowani mogą edytować/dodawać metadane'),
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
  fileNameDescription: widget.item?.fileNameDescription ?? '',

  format: _format.text.trim().toLowerCase(),
  formatDescription: widget.item?.formatDescription ?? '',

  platform: _platform.text.trim(),
  platformDescription: widget.item?.platformDescription ?? '',

  source: _source.text.trim(),
  sourceDescription: widget.item?.sourceDescription ?? '',

  status: _status.text.trim(),
  statusDescription: widget.item?.statusDescription ?? '',

  storagePath: _storagePath.text.trim(),
  storagePathDescription: widget.item?.storagePathDescription ?? '',
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
      appBar: AppBar(
        title: Text(isEdit ? 'Edytuj metadane' : 'Dodaj metadane'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _fileName,
                decoration: const InputDecoration(
                  labelText: 'fileName (np. sample.exe)',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wymagane' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _format,
                decoration: const InputDecoration(
                  labelText: 'format (exe / jpg / png)',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wymagane' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _platform,
                decoration: const InputDecoration(
                  labelText: 'platform (np. Windows)',
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _source,
                decoration: const InputDecoration(
                  labelText: 'source (np. paczka)',
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _status,
                decoration: const InputDecoration(
                  labelText: 'status (to analysis / infected)',
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _storagePath,
                decoration: const InputDecoration(
                  labelText: 'storagePath (binaries/sample.exe)',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wymagane' : null,
              ),
              const SizedBox(height: 20),

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
}
