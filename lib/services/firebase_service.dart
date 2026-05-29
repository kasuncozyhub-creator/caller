import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Authentication Streams
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign In
  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Sign Out
  Future<void> signOut() {
    return _auth.signOut();
  }

  // Numbers CRUD
  Stream<QuerySnapshot> getNumbers() {
    return _db.collection('numbers').snapshots();
  }

  Future<void> addNumber(String number, String? name) {
    return _db.collection('numbers').add({
      'phoneNumber': number,
      'name': name ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteNumber(String docId) {
    return _db.collection('numbers').doc(docId).delete();
  }

  // Calling Jobs
  Stream<DocumentSnapshot> getCallJob() {
    return _db.collection('call_jobs').doc('current').snapshots();
  }

  Future<void> startCallJob(int intervalMinutes) {
    return _db.collection('call_jobs').doc('current').set({
      'status': 'running',
      'interval_minutes': intervalMinutes,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> stopCallJob() {
    return _db.collection('call_jobs').doc('current').set({
      'status': 'idle',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
