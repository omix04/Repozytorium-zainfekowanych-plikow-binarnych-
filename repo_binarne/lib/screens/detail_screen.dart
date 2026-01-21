import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/auth_repository.dart';
import '../data/firebase_repository.dart';
import '../models/binary_item.dart';
import 'edit_screen.dart';
import 'login_screen.dart';

class DetailScreen extends StatelessWidget {
  final BinaryItem item;
  const DetailScreen({super.key, required this.item});

  bool _isLogged(User? user) => user != null && !user.isAnonymous;
  bool _isAdmin(User? user) =>
      user != null && !user.isAnonymous && user.email == 'omix041@gmail.com';

  @override
  Widget build(BuildContext context) {
    final repo = FirebaseRepository();
    final authRepo = AuthRepository();

    final user = FirebaseAuth.instance.currentUser;
    final logged = _isLogged(user);
    final admin = _isAdmin(user);

    // 🔒 Gość nie widzi metadanych
    if (!logged) {
      return Scaffold(
        appBar: AppBar(title: Text(item.fileName)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Metadane są dostępne tylko po zalogowaniu.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(authRepository: authRepo),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Zaloguj'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(item.fileName),

        // ✅ Edycja/Usuwanie TYLKO dla admina
        actions: [
          if (admin)
            IconButton(
              tooltip: 'Edytuj',
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditItemScreen(item: item)),
                );
              },
            ),
          if (admin)
            IconButton(
              tooltip: 'Usuń',
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Usunąć metadane?'),
                    content: const Text(
                      'To usunie wpis z Firestore (metadane). Plik w Storage zostanie.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Anuluj'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Usuń'),
                      ),
                    ],
                  ),
                );

                if (ok == true) {
                  await repo.deleteItem(item.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              admin
                  ? 'Metadane (ADMIN: możesz edytować)'
                  : 'Metadane (USER: tylko podgląd)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _kvWithDesc('fileName', item.fileName, item.fileNameDescription),
            _kvWithDesc('format', _safe(item.format), item.formatDescription),
            _kvWithDesc('platform', _safe(item.platform), item.platformDescription),
            _kvWithDesc('source', _safe(item.source), item.sourceDescription),
            _kvWithDesc('status', _safe(item.status), item.statusDescription),
            _kvWithDesc(
              'storagePath',
              _safe(item.storagePath),
              item.storagePathDescription,
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            const Text(
              'Link do pliku (Firebase Storage)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            FutureBuilder<String>(
              future: repo.getDownloadUrl(item.storagePath),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(),
                  );
                }
                if (snap.hasError) return Text('Błąd URL: ${snap.error}');

                final url = snap.data ?? '';
                if (url.isEmpty) return const Text('Brak URL.');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(url),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: url));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Skopiowano URL')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Kopiuj URL'),
                    ),
                    const SizedBox(height: 16),
                    _maybePreview(url, item.format),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _safe(String v) => v.trim().isEmpty ? '—' : v.trim();

  Widget _kvWithDesc(String key, String value, String desc) {
    final d = desc.trim().isEmpty ? '—' : desc.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Wartość: $value'),
          const SizedBox(height: 2),
          Text('Opis: $d', style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _maybePreview(String url, String format) {
    final f = format.trim().toLowerCase();
    final isImage =
        f == 'jpg' || f == 'jpeg' || f == 'png' || f == 'gif' || f == 'webp';

    if (!isImage) {
      return const Text('Podgląd dostępny tylko dla obrazów (jpg/png/webp).');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Podgląd', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) =>
                Text('Nie udało się wczytać obrazu: $error'),
          ),
        ),
      ],
    );
  }
}
