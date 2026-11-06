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
          final notes = snapshot.docs.map((doc) => Note.fromDocument(doc)).toList();
          notes.sort((a, b) {
            if (a.isPinned != b.isPinned) {
              return a.isPinned ? -1 : 1;
            }
            return b.createdAt.compareTo(a.createdAt);
          });
          return notes;
        });
  }

  Future<void> addNote({
    required String userId,
    required String title,
    required String content,
    bool isPinned = false,
    int colorIndex = 0,
  }) async {
    final docRef = _userNotesCollection(userId).doc();
    await docRef.set({
      'title': title.trim(),
      'content': content.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
      'isPinned': isPinned,
      'colorIndex': colorIndex,
    }).timeout(const Duration(milliseconds: 400), onTimeout: () {});
  }

  Future<void> updateNote({
    required String userId,
    required String noteId,
    required String title,
    required String content,
    bool isPinned = false,
    int colorIndex = 0,
  }) async {
    await _userNotesCollection(userId).doc(noteId).update({
      'title': title.trim(),
      'content': content.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isPinned': isPinned,
      'colorIndex': colorIndex,
    }).timeout(const Duration(milliseconds: 400), onTimeout: () {});
  }

  Future<void> togglePinStatus({
    required String userId,
    required String noteId,
    required bool currentStatus,
  }) async {
    await _userNotesCollection(userId).doc(noteId).update({
      'isPinned': !currentStatus,
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
