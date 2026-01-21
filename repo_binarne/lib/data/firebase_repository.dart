import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/binary_item.dart';

class FirebaseRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'sala',
  );

  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Inicjalizacja funkcji w konkretnym regionie
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west2',
  );

  Stream<List<BinaryItem>> watchItems() {
    return _db.collection('binary_items').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BinaryItem.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Wywołanie ręcznego sprawdzenia MD5
  Future<Map<String, dynamic>> triggerMd5Check(String storagePath, String docId) async {
    final callable = _functions.httpsCallable('manualMd5Check');
    final result = await callable.call({
      'storagePath': storagePath,
      'docId': docId,
    });
    return Map<String, dynamic>.from(result.data);
  }

  Future<void> addItem(BinaryItem item) async => await _db.collection('binary_items').add(item.toMap());
  Future<void> updateItem(BinaryItem item) async => await _db.collection('binary_items').doc(item.id).update(item.toMap());
  Future<void> deleteItem(String id) async => await _db.collection('binary_items').doc(id).delete();
  Future<String> getDownloadUrl(String storagePath) => _storage.ref(storagePath).getDownloadURL();
}