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
  late final TextEditingController _fileNameDescription;
  late final TextEditingController _format;
  late final TextEditingController _formatDescription;
  late final TextEditingController _platform;
  late final TextEditingController _platformDescription;
  late final TextEditingController _source;
  late final TextEditingController _sourceDescription;
  late final TextEditingController _status;
  late final TextEditingController _statusDescription;
  late final TextEditingController _storagePath;
  late final TextEditingController _storagePathDescription;

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
    _fileNameDescription = TextEditingController(text: it?.fileNameDescription ?? '');
    _format = TextEditingController(text: it?.format ?? '');
    _formatDescription = TextEditingController(text: it?.formatDescription ?? '');
    _platform = TextEditingController(text: it?.platform ?? '');
    _platformDescription = TextEditingController(text: it?.platformDescription ?? '');
    _source = TextEditingController(text: it?.source ?? '');
    _sourceDescription = TextEditingController(text: it?.sourceDescription ?? '');
    _status = TextEditingController(text: it?.status ?? '');
    _statusDescription = TextEditingController(text: it?.statusDescription ?? '');
    _storagePath = TextEditingController(text: it?.storagePath ?? '');
    _storagePathDescription = TextEditingController(text: it?.storagePathDescription ?? '');
  }

  @override
  void dispose() {
    _fileName.dispose();
    _fileNameDescription.dispose();
    _format.dispose();
    _formatDescription.dispose();
    _platform.dispose();
    _platformDescription.dispose();
    _source.dispose();
    _sourceDescription.dispose();
    _status.dispose();
    _statusDescription.dispose();
    _storagePath.dispose();
    _storagePathDescription.dispose();
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
        fileNameDescription: _fileNameDescription.text.trim(),
        format: _format.text.trim().toLowerCase(),
        formatDescription: _formatDescription.text.trim(),
        platform: _platform.text.trim(),
        platformDescription: _platformDescription.text.trim(),
        source: _source.text.trim(),
        sourceDescription: _sourceDescription.text.trim(),
        status: _status.text.trim(),
        statusDescription: _statusDescription.text.trim(),
        storagePath: _storagePath.text.trim(),
        storagePathDescription: _storagePathDescription.text.trim(),
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
                  labelText: 'Nazwa pliku',
                  hintText: 'np. sample.exe',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wymagane' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fileNameDescription,
                decoration: const InputDecoration(
                  labelText: 'Opis nazwy pliku',
                  hintText: 'Dodatkowe informacje o nazwie',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _format,
                decoration: const InputDecoration(
                  labelText: 'Format',
                  hintText: 'exe / jpg / png',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wymagane' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _formatDescription,
                decoration: const InputDecoration(
                  labelText: 'Opis formatu',
                  hintText: 'Dodatkowe informacje o formacie',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _platform,
                decoration: const InputDecoration(
                  labelText: 'Platforma',
                  hintText: 'np. Windows, Linux, Android',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _platformDescription,
                decoration: const InputDecoration(
                  labelText: 'Opis platformy',
                  hintText: 'Dodatkowe informacje o platformie',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _source,
                decoration: const InputDecoration(
                  labelText: 'Źródło',
                  hintText: 'np. email, paczka, download',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _sourceDescription,
                decoration: const InputDecoration(
                  labelText: 'Opis źródła',
                  hintText: 'Dodatkowe informacje o źródle',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  hintText: 'to analysis / infected / clean',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _statusDescription,
                decoration: const InputDecoration(
                  labelText: 'Opis statusu',
                  hintText: 'Dodatkowe informacje o statusie',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _storagePath,
                decoration: const InputDecoration(
                  labelText: 'Ścieżka w Storage',
                  hintText: 'binaries/sample.exe',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wymagane' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _storagePathDescription,
                decoration: const InputDecoration(
                  labelText: 'Opis ścieżki',
                  hintText: 'Dodatkowe informacje o lokalizacji',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

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
