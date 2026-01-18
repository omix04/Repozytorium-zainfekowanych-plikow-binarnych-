import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/binary_item.dart';

class FirebaseRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'sala', // 
  );

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<BinaryItem>> watchItems() {
    return _db.collection('binary_items').snapshots().map((snapshot) {
      print('FIRESTORE (sala): docs=${snapshot.docs.length}');
      for (final d in snapshot.docs) {
        print('DOC: ${d.id} => ${d.data()}');
      }

      return snapshot.docs
          .map((doc) => BinaryItem.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<String> getDownloadUrl(String storagePath) {
    return _storage.ref(storagePath).getDownloadURL();
  }
}
