import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/binary_item.dart';

class FirebaseRepository {
  // WAŻNE: Twoje dane są w bazie Firestore o databaseId 'sala'
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'sala',
  );

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<BinaryItem>> watchItems() {
    return _db.collection('binary_items').snapshots().map((snapshot) {
      print('FIRESTORE (sala): docs=${snapshot.docs.length}');
      return snapshot.docs
          .map((doc) => BinaryItem.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> addItem(BinaryItem item) async {
    // id w item może być pusty w trybie add – i tak Firestore nada auto-id
    await _db.collection('binary_items').add(item.toMap());
  }

  Future<void> updateItem(BinaryItem item) async {
    await _db.collection('binary_items').doc(item.id).update(item.toMap());
  }

  Future<void> deleteItem(String id) async {
    await _db.collection('binary_items').doc(id).delete();
  }

  Future<String> getDownloadUrl(String storagePath) {
    return _storage.ref(storagePath).getDownloadURL();
  }
}
