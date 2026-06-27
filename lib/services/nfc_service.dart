import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  static final NfcService _instance = NfcService._internal();
  factory NfcService() => _instance;
  NfcService._internal();

  /// Mengecek apakah NFC tersedia di device
  Future<bool> isNfcAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  /// Memulai pemindaian NFC dan mengembalikan UID dalam format Hex
  Future<String?> startNfcScan(BuildContext context) async {
    if (!await isNfcAvailable()) {
      _showErrorDialog(context, 'NFC Tidak Tersedia', 
          'Perangkat Anda tidak mendukung NFC atau NFC sedang dimatikan.');
      return null;
    }

    String? uidResult;
    bool isScanning = true;

    // Tampilkan dialog scanning
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.nfc, color: Colors.blue),
              SizedBox(width: 10),
              Text('Pemindaian NFC'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Dekatkan smartphone ke tag NFC...'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  isScanning = false;
                  NfcManager.instance.stopSession();
                  Navigator.of(context).pop();
                },
                child: const Text('Batal'),
              ),
            ],
          ),
        );
      },
    );

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          if (!isScanning) return;
          
          uidResult = _extractUidFromTag(tag);
          isScanning = false;
          
          await NfcManager.instance.stopSession();
          Navigator.of(context).pop(); // Tutup dialog scanning
        },
      );
    } catch (e) {
      isScanning = false;
      Navigator.of(context).pop(); // Tutup dialog scanning
      _showErrorDialog(context, 'Error NFC', 
          'Terjadi kesalahan saat memindai NFC: $e');
    }

    return uidResult;
  }

  /// Ekstrak UID dari NFC tag dan konversi ke format Hex String
  String? _extractUidFromTag(NfcTag tag) {
    try {
      // Coba ambil dari berbagai teknologi NFC
      Uint8List? identifier;

      // NFCA (paling umum)
      if (tag.data.containsKey('nfca')) {
        identifier = tag.data['nfca']['identifier'];
      }
      // NFCB
      else if (tag.data.containsKey('nfcb')) {
        identifier = tag.data['nfcb']['identifier'];
      }
      // NFCF
      else if (tag.data.containsKey('nfcf')) {
        identifier = tag.data['nfcf']['identifier'];
      }
      // NFCV
      else if (tag.data.containsKey('nfcv')) {
        identifier = tag.data['nfcv']['identifier'];
      }

      if (identifier != null) {
        return _bytesToHexString(identifier);
      }

      return null;
    } catch (e) {
      print('Error extracting UID: $e');
      return null;
    }
  }

  /// Konversi bytes ke Hex String dengan format XX-XX-XX-XX
  String _bytesToHexString(Uint8List bytes) {
    return bytes
        .map((byte) => byte.toRadixString(16).toUpperCase().padLeft(2, '0'))
        .join('-');
  }

  /// Tampilkan dialog error
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
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

  /// Stop session NFC (untuk cleanup)
  Future<void> stopSession() async {
    await NfcManager.instance.stopSession();
  }
}
