import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/binary_item.dart';

class AdminRepository {
  // Połączenie z dedykowaną bazą 'sala'
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'sala',
  );

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> uploadFullEntry({
    required File file,
    required Map<String, String> metadataFields,
  }) async {
    // 1. Wyodrębnienie nazwy pliku i ścieżki Storage
    final String rawFileName = file.path.split(Platform.pathSeparator).last;
    final String storagePath = "binaries/$rawFileName"; // Zgodnie z wymaganiem

    try {
      // 2. Upload binarnego pliku
      final ref = _storage.ref().child(storagePath);
      await ref.putFile(file);

      // 3. Budowa modelu BinaryItem (16 pól)
      final newItem = BinaryItem(
        id: "", // Firestore nada własne ID
        fileName: rawFileName,
        fileNameDescription: metadataFields['fileNameDescription'] ?? "",
        platform: metadataFields['platform'] ?? "Unknown",
        platformDescription: metadataFields['platformDescription'] ?? "",
        format: rawFileName.split('.').last.toLowerCase(),
        formatDescription: metadataFields['formatDescription'] ?? "",
        source: metadataFields['source'] ?? "Unknown",
        sourceDescription: metadataFields['sourceDescription'] ?? "",
        status: "to analysis", // Początkowy status
        statusDescription: metadataFields['statusDescription'] ?? "",
        storagePath: storagePath,
        storagePathDescription: metadataFields['storagePathDescription'] ?? "",
      );

      // 4. Zapis do Firestore w bazie 'sala'
      await _db.collection('binary_items').add(newItem.toMap());
      
    } catch (e) {
      throw Exception("Błąd krytyczny panelu admina: $e");
    }
  }
}