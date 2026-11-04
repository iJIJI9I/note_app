import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/note_model.dart';

class NotesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userNotesCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('notes');
  }

  Stream<List<Note>> getNotesStream(String userId) {
    return _userNotesCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          return snapshot.docs.map((doc) => Note.fromDocument(doc)).toList();
        });
  }

  Future<void> addNote({
    required String userId,
    required String title,
    required String content,
  }) async {
    final docRef = _userNotesCollection(userId).doc();
    await docRef.set({
      'title': title.trim(),
      'content': content.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
    }).timeout(const Duration(milliseconds: 400), onTimeout: () {});
  }

  Future<void> updateNote({
    required String userId,
    required String noteId,
    required String title,
    required String content,
  }) async {
    await _userNotesCollection(userId).doc(noteId).update({
      'title': title.trim(),
      'content': content.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(milliseconds: 400), onTimeout: () {});
  }

  Future<void> deleteNote({
    required String userId,
    required String noteId,
  }) async {
    await _userNotesCollection(userId).doc(noteId).delete().timeout(
      const Duration(milliseconds: 400),
      onTimeout: () {},
    );
  }
}
