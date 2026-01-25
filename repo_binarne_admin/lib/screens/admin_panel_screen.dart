import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../data/admin_repository.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _adminRepo = AdminRepository();
  File? _selectedFile;
  bool _isLoading = false;

  // Kontrolery dla pól wymaganych przez użytkownika
  final Map<String, TextEditingController> _controllers = {
    'platform': TextEditingController(text: 'Windows'),
    'platformDescription': TextEditingController(),
    'source': TextEditingController(),
    'sourceDescription': TextEditingController(),
    'storagePathDescription': TextEditingController(),
    'fileNameDescription': TextEditingController(),
    'statusDescription': TextEditingController(),
  };

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedFile = File(result.files.single.path!));
    }
  }

  Future<void> _startProcess() async {
    if (_selectedFile == null) return;
    setState(() => _isLoading = true);

    try {
      final meta = _controllers.map((key, controller) => MapEntry(key, controller.text));
      await _adminRepo.uploadFullEntry(file: _selectedFile!, metadataFields: meta);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pomyślnie dodano plik i metadane!")));
        setState(() => _selectedFile = null);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Błąd: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Panel Admina - Repozytorium")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.file_open),
            label: const Text("Wybierz plik malware"),
          ),
          if (_selectedFile != null) Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text("Wybrano: ${_selectedFile!.path}", style: const TextStyle(color: Colors.green)),
          ),
          const Divider(),
          ..._controllers.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: entry.value,
              decoration: InputDecoration(labelText: entry.key, border: const OutlineInputBorder()),
            ),
          )),
          const SizedBox(height: 20),
          _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : ElevatedButton(
                onPressed: _selectedFile == null ? null : _startProcess,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
                child: const Text("WYŚLIJ DO REPOZYTORIUM"),
              ),
        ],
      ),
    );
  }
}