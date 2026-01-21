import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/auth_repository.dart';
import '../data/firebase_repository.dart';
import '../models/binary_item.dart';
import 'detail_screen.dart';
import 'edit_screen.dart';
import 'login_screen.dart';

class ListScreen extends StatelessWidget {
  const ListScreen({super.key});

  bool _isLogged(User? user) => user != null && !user.isAnonymous;
  bool _isAdmin(User? user) =>
      user != null && !user.isAnonymous && user.email == 'omix041@gmail.com';

  @override
  Widget build(BuildContext context) {
    final repo = FirebaseRepository();
    final auth = AuthRepository();

    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, authSnap) {
        final user = authSnap.data;
        final logged = _isLogged(user);
        final admin = _isAdmin(user);

        return Scaffold(
          appBar: AppBar(title: const Text('Repozytorium binariów')),

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
                      const SizedBox(height: 10),
                      Text(
                        logged ? (user!.email ?? user.uid) : 'Gość',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        admin
                            ? 'Uprawnienia: ADMIN (CRUD)'
                            : (logged
                                ? 'Uprawnienia: USER (podgląd metadanych)'
                                : 'Uprawnienia: GUEST (lista bez metadanych)'),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                if (!logged)
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

                if (logged)
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

          // ✅ Dodawanie TYLKO dla admina
          floatingActionButton: admin
              ? FloatingActionButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditItemScreen()),
                    );
                  },
                  child: const Icon(Icons.add),
                )
              : null,

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

                      return ListTile(
                        leading: _iconForFormat(item.format),
                        title: Text(item.fileName),

                        // 👀 Gość widzi tylko minimum, zalogowany widzi więcej
                        subtitle: Text(
                          logged
                              ? '$platform • ${item.format} • $status'
                              : item.format.toUpperCase(),
                        ),

                        trailing: logged
                            ? const Icon(Icons.chevron_right)
                            : const Icon(Icons.lock_outline),

                        // 🔒 Gość nie może wejść w szczegóły
                        onTap: logged
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
