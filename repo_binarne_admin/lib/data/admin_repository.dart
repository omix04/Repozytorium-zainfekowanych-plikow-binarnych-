import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/binary_item.dart';

class AdminRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'sala',
  );

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> uploadFullEntry({
    required File file,
    required Map<String, String> metadataFields,
  }) async {

    final String rawFileName = file.path.split(Platform.pathSeparator).last;
    final String storagePath = "binaries/$rawFileName"; 

    try {
      final ref = _storage.ref().child(storagePath);
      await ref.putFile(file);

      final newItem = BinaryItem(
        id: "", 
        fileName: rawFileName,
        fileNameDescription: metadataFields['fileNameDescription'] ?? "",
        platform: metadataFields['platform'] ?? "Unknown",
        platformDescription: metadataFields['platformDescription'] ?? "",
        format: rawFileName.split('.').last.toLowerCase(),
        formatDescription: metadataFields['formatDescription'] ?? "",
        source: metadataFields['source'] ?? "Unknown",
        sourceDescription: metadataFields['sourceDescription'] ?? "",
        status: "to analysis", 
        statusDescription: metadataFields['statusDescription'] ?? "",
        storagePath: storagePath,
        storagePathDescription: metadataFields['storagePathDescription'] ?? "",
      );


      await _db.collection('binary_items').add(newItem.toMap());
      
    } catch (e) {
      throw Exception("Błąd krytyczny panelu admina: $e");
    }
  }
}