import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/firebase_repository.dart';
import '../data/auth_repository.dart';
import '../models/binary_item.dart';
import 'login_screen.dart';

class DetailScreen extends StatelessWidget {
  final BinaryItem item;
  const DetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final repo = FirebaseRepository();
    final auth = AuthRepository();
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null && !user.isAnonymous;

    
    if (!isLoggedIn) {
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
                        builder: (_) => LoginScreen(authRepository: auth),
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
      appBar: AppBar(title: Text(item.fileName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Metadane',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _kv('Nazwa pliku', item.fileName),
            _kv('Format', _safe(item.format)),
            _kv('Platforma', _safe(item.platform)),
            _kv('Źródło', _safe(item.source)),
            _kv('Status', _safe(item.status)),
            _kv('Storage path', _safe(item.storagePath)),
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
                if (snap.hasError) {
                  return Text('Błąd pobierania URL: ${snap.error}');
                }

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

  String _safe(String v) => v.trim().isEmpty ? '—' : v;

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$k:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(v)),
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
