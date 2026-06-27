import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'mock_database.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Mode Uji Coba Offline (Ganti ke false untuk menggunakan Firebase Asli)
  static const bool useMockMode = true;

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Stream untuk mendengarkan perubahan status auth
  Stream<AppUser?> get authStateChanges {
    if (useMockMode) {
      return MockDatabase.instance.authStateChanges;
    }
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return await getUserData(firebaseUser.uid) ?? AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        username: firebaseUser.displayName ?? 'Pemain',
        dibuatPada: DateTime.now(),
      );
    });
  }

  // User saat ini
  AppUser? get currentUser {
    if (useMockMode) {
      return MockDatabase.instance.currentUser;
    }
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      username: firebaseUser.displayName ?? 'Pemain',
      dibuatPada: DateTime.now(),
    );
  }

  /// Login dengan email dan password
  Future<void> signInWithEmailPassword(String email, String password) async {
    if (useMockMode) {
      await MockDatabase.instance.signIn(email, password);
      return;
    }
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Register dengan email dan password
  Future<void> registerWithEmailPassword(
    String email, 
    String password, 
    String username
  ) async {
    if (useMockMode) {
      await MockDatabase.instance.register(email, password, username);
      return;
    }
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Simpan data user tambahan ke Firestore
      if (result.user != null) {
        await _createUserDocument(result.user!, username);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Logout
  Future<void> signOut() async {
    if (useMockMode) {
      await MockDatabase.instance.signOut();
      return;
    }
    await _auth.signOut();
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    if (useMockMode) {
      // Mock reset password langsung sukses
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Buat dokumen user di Firestore
  Future<void> _createUserDocument(User user, String username) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    
    final userData = AppUser(
      uid: user.uid,
      email: user.email ?? '',
      username: username,
      dibuatPada: DateTime.now(),
    );

    await userDoc.set(userData.toMap());
  }

  /// Mendapatkan data user dari Firestore
  Future<AppUser?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromFirestore(uid, doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Handle Firebase Auth Exception
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Email tidak terdaftar.';
      case 'wrong-password':
        return 'Password salah.';
      case 'email-already-in-use':
        return 'Email sudah digunakan.';
      case 'weak-password':
        return 'Password terlalu lemah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'operation-not-allowed':
        return 'Operasi tidak diizinkan.';
      default:
        return 'Terjadi kesalahan: ${e.message}';
    }
  }
}
