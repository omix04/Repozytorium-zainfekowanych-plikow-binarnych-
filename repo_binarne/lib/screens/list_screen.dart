import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/firebase_repository.dart';
import '../data/auth_repository.dart';
import '../models/binary_item.dart';
import 'detail_screen.dart';
import 'login_screen.dart';

class ListScreen extends StatelessWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = FirebaseRepository();
    final auth = AuthRepository();

    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, authSnap) {
        final user = authSnap.data;
        final isLoggedIn = user != null && !user.isAnonymous;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Repozytorium binariów'),
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.deepPurple),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Repozytorium binariów',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isLoggedIn ? (user.displayName ?? user.email ?? '') : 'Gość',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isLoggedIn
                            ? 'Masz dostęp do metadanych'
                            : 'Tylko podgląd listy (bez metadanych)',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                if (!isLoggedIn)
                  ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('Zaloguj'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoginScreen(authRepository: auth),
                        ),
                      );
                    },
                  ),

                if (isLoggedIn)
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Wyloguj'),
                    onTap: () async {
                      Navigator.pop(context);
                      await auth.signOut();
                    },
                  ),
              ],
            ),
          ),
          body: StreamBuilder<List<BinaryItem>>(
            stream: repo.watchItems(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Błąd: ${snapshot.error}'));
              }

              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(child: Text('Brak plików w repozytorium.'));
              }

              // Grupowanie po formacie
              final Map<String, List<BinaryItem>> groups = {};
              for (final item in items) {
                final format = item.format.trim().toLowerCase().isEmpty
                    ? 'unknown'
                    : item.format.trim().toLowerCase();
                groups.putIfAbsent(format, () => []).add(item);
              }

              final formats = groups.keys.toList()..sort();
              for (final f in formats) {
                groups[f]!.sort((a, b) => a.fileName.compareTo(b.fileName));
              }

              return ListView(
                children: formats.map((format) {
                  final groupItems = groups[format]!;

                  return ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(
                      '${format.toUpperCase()} (${groupItems.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: groupItems.map((item) {
                      final platform =
                          item.platform.trim().isEmpty ? 'unknown' : item.platform;
                      final status =
                          item.status.trim().isEmpty ? 'unknown' : item.status;

                      final s = status.trim().toLowerCase();
                      final isInfected = s == 'infected' || s == 'zainfekowany';
                      final isSuspicious =
                          s == 'suspicious' || s == 'podejrzany' || s == 'to analysis';

                      final titleStyle = TextStyle(
                        color: isInfected
                            ? Colors.red.shade800
                            : isSuspicious
                                ? Colors.orange.shade800
                                : null,
                      );

                      final subtitleStyle = TextStyle(
                        color: isInfected
                            ? Colors.red.shade700
                            : isSuspicious
                                ? Colors.orange.shade700
                                : null,
                        fontSize: 13,
                      );

                      return ListTile(
                        leading: IconTheme(
                          data: IconThemeData(
            color: isInfected
                ? Colors.red
                : isSuspicious
                    ? Colors.orange
                    : null,
                          ),
                          child: _iconForFormat(item.format),
                        ),
                        title: Text(item.fileName, style: titleStyle),

                        // Gość widzi tylko minimum (żeby „tylko repo” działało)
                        subtitle: Text(
                          isLoggedIn
                              ? '$platform • ${item.format} • $status'
                              : '${item.format.toUpperCase()}',
                          style: subtitleStyle,
                        ),

                        trailing: isLoggedIn
                            ? const Icon(Icons.chevron_right)
                            : const Icon(Icons.lock_outline),

                        // 🔒 BLOKADA WEJŚCIA W METADANE
                        onTap: isLoggedIn
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailScreen(item: item),
                                  ),
                                );
                              }
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Zaloguj się, aby zobaczyć metadane.',
                                    ),
                                  ),
                                );
                              },
                      );
                    }).toList(),
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }

  Icon _iconForFormat(String format) {
    final f = format.trim().toLowerCase();

    if (f == 'jpg' ||
        f == 'jpeg' ||
        f == 'png' ||
        f == 'gif' ||
        f == 'webp') {
      return const Icon(Icons.image);
    }
    if (f == 'pdf') return const Icon(Icons.picture_as_pdf);
    if (f == 'zip' || f == 'rar' || f == '7z') return const Icon(Icons.archive);
    if (f == 'exe' || f == 'msi' || f == 'apk') return const Icon(Icons.apps);

    return const Icon(Icons.insert_drive_file);
  }
}
