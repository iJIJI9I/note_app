import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

class NotesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Отримання посилання  
  CollectionReference<Map<String, dynamic>> _userNotesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('notes');
  }

  // Потік
  Stream<List<Note>> getNotesStream(String userId) {
    return _userNotesCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Note.fromDocument(doc)).toList();
    });
  }

  // Додавання 
  Future<void> addNote({
    required String userId,
    required String title,
    required String content,
  }) async {
    await _userNotesCollection(userId).add({
      'title': title.trim(),
      'content': content.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
    });
  }

  // Оновлення 
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
    });
  }

  // Видалення
  Future<void> deleteNote({
    required String userId,
    required String noteId,
  }) async {
    await _userNotesCollection(userId).doc(noteId).delete();
  }
}