import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/pet.dart';
import 'auth_service.dart';
import 'mock_database.dart';

class GameService {
  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  FirebaseFunctions get _functions => FirebaseFunctions.instance;

  /// Mengalirkan daftar hewan peliharaan yang dimiliki pemain secara real-time
  Stream<List<Pet>> getOwnedPetsStream(String userId) {
    if (AuthService.useMockMode) {
      return MockDatabase.instance.getOwnedPetsStream(userId);
    }
    return FirebaseFirestore.instance
        .collection('master_hewan')
        .where('id_pemilik', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Pet.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Mengalirkan detail satu hewan peliharaan secara real-time
  Stream<Pet?> getPetStream(String petId) {
    if (AuthService.useMockMode) {
      return MockDatabase.instance.getPetStream(petId);
    }
    return FirebaseFirestore.instance
        .collection('master_hewan')
        .doc(petId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) return null;
          return Pet.fromFirestore(snapshot.id, snapshot.data()!);
        });
  }

  /// Mengklaim hewan peliharaan dengan UID tag NFC
  Future<void> klaimHewan(BuildContext context, String uidTag) async {
    final navigator = Navigator.of(context);

    // Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memproses klaim hewan...'),
            ],
          ),
        );
      },
    );

    try {
      if (AuthService.useMockMode) {
        final pet = await MockDatabase.instance.klaimHewan(uidTag);
        navigator.pop(); // Tutup loading
        _showSuccessDialog(context, pet);
        return;
      }

      // Panggil Cloud Function asli
      final HttpsCallable callable = _functions.httpsCallable('klaimHewan');
      final result = await callable.call({'uidTag': uidTag});

      // Tutup loading dialog
      navigator.pop();

      final data = result.data;
      
      if (data['status'] == 'sukses') {
        final petData = data['data'];
        final pet = Pet.fromFirestore(uidTag, petData);
        _showSuccessDialog(context, pet);
      } else {
        _showErrorDialog(context, 'Gagal Mengklaim', 
            data['message'] ?? 'Terjadi kesalahan yang tidak diketahui.');
      }

    } on FirebaseFunctionsException catch (e) {
      Navigator.of(context).pop();
      String errorMessage;
      switch (e.code) {
        case 'not-found':
          errorMessage = 'Tag NFC tidak valid atau tidak terdaftar dalam sistem.';
          break;
        case 'already-exists':
          errorMessage = 'Hewan ini sudah diklaim oleh pemain lain. Coba tag NFC yang berbeda.';
          break;
        case 'unauthenticated':
          errorMessage = 'Anda harus login terlebih dahulu.';
          break;
        case 'invalid-argument':
          errorMessage = 'Data tag NFC tidak valid.';
          break;
        default:
          errorMessage = 'Terjadi kesalahan: ${e.message}';
      }
      _showErrorDialog(context, 'Gagal Mengklaim Hewan', errorMessage);
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorDialog(context, 'Error/Gagal', 
          'Terjadi kesalahan: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  /// Mendapatkan statistik game
  Future<Map<String, dynamic>?> getGameStats() async {
    try {
      if (AuthService.useMockMode) {
        return MockDatabase.instance.getGameStats();
      }
      final HttpsCallable callable = _functions.httpsCallable('getGameStats');
      final result = await callable.call();
      return result.data as Map<String, dynamic>;
    } catch (e) {
      print('Error getting game stats: $e');
      return null;
    }
  }

  /// Memberi makan hewan peliharaan
  Future<Map<String, dynamic>?> beriMakan(BuildContext context, String uidTag) async {
    try {
      if (AuthService.useMockMode) {
        return await MockDatabase.instance.beriMakan(uidTag);
      }
      final HttpsCallable callable = _functions.httpsCallable('beriMakan');
      final result = await callable.call({'uidTag': uidTag});
      return result.data as Map<String, dynamic>;
    } on FirebaseFunctionsException catch (e) {
      _showErrorDialog(context, 'Gagal Memberi Makan', e.message ?? 'Terjadi kesalahan.');
      return null;
    } catch (e) {
      _showErrorDialog(context, 'Error/Gagal', 
          'Terjadi kesalahan: ${e.toString().replaceAll('Exception: ', '')}');
      return null;
    }
  }

  /// Melatih hewan peliharaan
  Future<Map<String, dynamic>?> latihanHewan(BuildContext context, String uidTag) async {
    try {
      if (AuthService.useMockMode) {
        return await MockDatabase.instance.latihanHewan(uidTag);
      }
      final HttpsCallable callable = _functions.httpsCallable('latihanHewan');
      final result = await callable.call({'uidTag': uidTag});
      return result.data as Map<String, dynamic>;
    } on FirebaseFunctionsException catch (e) {
      _showErrorDialog(context, 'Gagal Melatih Hewan', e.message ?? 'Terjadi kesalahan.');
      return null;
    } catch (e) {
      _showErrorDialog(context, 'Error/Gagal', 
          'Terjadi kesalahan: ${e.toString().replaceAll('Exception: ', '')}');
      return null;
    }
  }

  /// Tampilkan dialog sukses dengan animasi
  void _showSuccessDialog(BuildContext context, Pet pet) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final themeColor = Color(int.parse(Pet.getTipeColor(pet.tipe).substring(1), radix: 16) + 0xFF000000);
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.celebration, color: Colors.amber[600]),
              const SizedBox(width: 10),
              const Text('Selamat!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pets,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Anda mendapatkan:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                pet.namaHewan,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  pet.tipe,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                pet.deskripsi,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Lanjutkan'),
            ),
          ],
        );
      },
    );
  }

  /// Tampilkan dialog error
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 10),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
