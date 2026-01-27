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

  @override
  Widget build(BuildContext context) {
    final repo = FirebaseRepository();
    final authRepo = AuthRepository();

    final user = FirebaseAuth.instance.currentUser;
    final logged = _isLogged(user);

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
                const Text('Metadane są dostępne tylko po zalogowaniu.', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen(authRepository: authRepo)));
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
        // ✅ Edycja/Usuwanie dla wszystkich zalogowanych użytkowników
        actions: [
          if (logged)
            IconButton(
              tooltip: 'Edytuj',
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => EditItemScreen(item: item)));
              },
            ),
          if (logged)
            IconButton(
              tooltip: 'Usuń',
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Usunąć metadane?'),
                    content: const Text('To usunie wpis z Firestore (metadane). Plik w Storage zostanie.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Anuluj')),
                      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Usuń')),
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
            // 🔴 Infected warning banner
            if (item.status.toLowerCase().trim() == 'infected')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  border: Border.all(color: Colors.red.shade800, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade800, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚠️ PLIK ZAINFEKOWANY',
                            style: TextStyle(color: Colors.red.shade800, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ten plik został oznaczony jako zainfekowany.',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            const Text(
              'Metadane (zalogowany użytkownik: możesz edytować)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _kvWithDesc('fileName', item.fileName, item.fileNameDescription),
            _kvWithDesc('format', _safe(item.format), item.formatDescription),
            _kvWithDesc('platform', _safe(item.platform), item.platformDescription),
            _kvWithDesc('source', _safe(item.source), item.sourceDescription),
            _kvWithDesc('status', _safe(item.status), item.statusDescription),
            _kvWithDesc('storagePath', _safe(item.storagePath), item.storagePathDescription),

            // --- NOWA SEKCJA: STATUS BEZPIECZEŃSTWA (MD5) ---
            const Divider(),
            const SizedBox(height: 12),
            const Text('Status Bezpieczeństwa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                item.md5 != null ? Icons.verified : Icons.warning,
                color: item.md5 != null ? Colors.green : Colors.orange,
                size: 32,
              ),
              title: SelectableText(
                item.md5 ?? 'Brak weryfikacji MD5',
                style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                item.lastVerified != null ? 'Zweryfikowano: ${item.lastVerified}' : 'Awaiting verification',
              ),
            ),

            // --- KONIEC NOWEJ SEKCJI ---
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            const Text('Link do pliku (Firebase Storage)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            FutureBuilder<String>(
              future: repo.getDownloadUrl(item.storagePath),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: CircularProgressIndicator());
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
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Skopiowano URL')));
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
    final isInfectedStatus = key == 'status' && value.toLowerCase().trim() == 'infected';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: isInfectedStatus ? const EdgeInsets.all(12) : null,
        decoration: isInfectedStatus
            ? BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade300),
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              key,
              style: TextStyle(fontWeight: FontWeight.bold, color: isInfectedStatus ? Colors.red.shade800 : null),
            ),
            const SizedBox(height: 4),
            Text(
              'Wartość: $value',
              style: isInfectedStatus ? TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold) : null,
            ),
            const SizedBox(height: 2),
            Text('Opis: $d', style: TextStyle(color: isInfectedStatus ? Colors.red.shade600 : Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _maybePreview(String url, String format) {
    final f = format.trim().toLowerCase();
    final isImage = f == 'jpg' || f == 'jpeg' || f == 'png' || f == 'gif' || f == 'webp';

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
            errorBuilder: (context, error, stack) => Text('Nie udało się wczytać obrazu: $error'),
          ),
        ),
      ],
    );
  }
}
