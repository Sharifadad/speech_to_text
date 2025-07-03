import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sends a message to Firestore with proper validation
  Future<void> sendMessage(String text) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (text.trim().isEmpty) {
        throw Exception('Message cannot be empty');
      }

      await _firestore.collection('messages').add({
        'text': text,
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Anonymous',
        'userPhoto': user.photoURL,
        'timestamp': FieldValue.serverTimestamp(),
        'edited': false,
      });
    } on FirebaseException catch (e) {
      throw Exception('Failed to send message: ${e.message}');
    }
  }

  /// Additional useful methods
  Stream<QuerySnapshot> getMessagesStream() {
    return _firestore
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }
}