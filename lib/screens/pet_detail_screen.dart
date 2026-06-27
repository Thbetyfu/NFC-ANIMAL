import 'dart:async';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet.dart';
import '../services/game_service.dart';

class PetDetailScreen extends StatefulWidget {
  final Pet pet;

  const PetDetailScreen({
    Key? key,
    required this.pet,
  }) : super(key: key);

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  final _gameService = GameService();
  bool _isFeeding = false;
  bool _isTraining = false;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Jalankan timer setiap 1 detik untuk memperbarui status hitung mundur cooldown
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  int _getFeedCooldownSeconds(Pet pet) {
    if (pet.terakhirDiberiMakan == null) return 0;
    final diff = DateTime.now().difference(pet.terakhirDiberiMakan!);
    final remaining = 180 - diff.inSeconds; // Cooldown 3 menit (180 detik)
    return remaining > 0 ? remaining : 0;
  }

  int _getTrainCooldownSeconds(Pet pet) {
    if (pet.terakhirLatihan == null) return 0;
    final diff = DateTime.now().difference(pet.terakhirLatihan!);
    final remaining = 180 - diff.inSeconds; // Cooldown 3 menit (180 detik)
    return remaining > 0 ? remaining : 0;
  }

  Future<void> _feedPet(Pet pet) async {
    if (_isFeeding) return;
    setState(() => _isFeeding = true);

    final result = await _gameService.beriMakan(context, pet.id);
    if (result != null) {
      final msg = result['message'] ?? 'Hewan berhasil diberi makan!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (mounted) {
      setState(() => _isFeeding = false);
    }
  }

  Future<void> _trainPet(Pet pet) async {
    if (_isTraining) return;
    setState(() => _isTraining = true);

    final result = await _gameService.latihanHewan(context, pet.id);
    if (result != null) {
      final msg = result['message'] ?? 'Latihan hewan selesai!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (mounted) {
      setState(() => _isTraining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Color(int.parse(Pet.getTipeColor(widget.pet.tipe).substring(1), radix: 16) + 0xFF000000);

    return StreamBuilder<Pet?>(
      stream: _gameService.getPetStream(widget.pet.id),
      builder: (context, snapshot) {
        // Fallback ke data awal jika stream belum memuat
        final pet = snapshot.data ?? widget.pet;

        final feedCooldown = _getFeedCooldownSeconds(pet);
        final trainCooldown = _getTrainCooldownSeconds(pet);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              pet.namaHewan,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3D Model Viewer
                Container(
                  height: 380,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        themeColor,
                        themeColor.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      ModelViewer(
                        src: pet.modelUrl,
                        alt: "Model 3D dari ${pet.namaHewan}",
                        ar: true,
                        autoRotate: false,
                        cameraControls: true,
                        backgroundColor: Colors.transparent,
                        loading: Loading.eager,
                        disableZoom: false,
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.threesixty, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Putar untuk melihat',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Detail Information
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header dengan Nama, Tipe, Level & EXP
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pet.namaHewan,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: themeColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        pet.tipe,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade700,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'LV. ${pet.level}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // EXP Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pengalaman (EXP)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${pet.exp} / 100',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: pet.exp / 100.0,
                              minHeight: 10,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Deskripsi
                      _buildSection(
                        'Deskripsi',
                        pet.deskripsi,
                        Icons.description,
                      ),
                      const SizedBox(height: 24),

                      // Statistik Dinamis
                      _buildStatsSection(pet),
                      const SizedBox(height: 24),

                      // Info tambahan
                      _buildInfoSection(pet),
                      const SizedBox(height: 28),

                      // Tombol aksi
                      _buildActionButtons(context, pet, feedCooldown, trainCooldown),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(Pet pet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Statistik Peliharaan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Maks HP',
                '${pet.currentHp}',
                Icons.favorite,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Attack',
                '${pet.currentAttack}',
                Icons.flash_on,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Pet pet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Informasi Tag',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.nfc, color: Colors.blue.shade600, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Tag NFC ID:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                pet.id,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.blue.shade900,
                  fontSize: 13,
                ),
              ),
              if (pet.diklaimPada != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.blue.shade600, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Diklaim pada:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${pet.diklaimPada!.day}/${pet.diklaimPada!.month}/${pet.diklaimPada!.year} ${pet.diklaimPada!.hour.toString().padLeft(2, '0')}:${pet.diklaimPada!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Pet pet, int feedCooldown, int trainCooldown) {
    final themeColor = Color(int.parse(Pet.getTipeColor(pet.tipe).substring(1), radix: 16) + 0xFF000000);

    return Column(
      children: [
        // Button Beri Makan
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: (_isFeeding || feedCooldown > 0) ? null : () => _feedPet(pet),
            icon: _isFeeding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.restaurant),
            label: Text(
              _isFeeding
                  ? 'Memproses...'
                  : feedCooldown > 0
                      ? 'Kenyang (${feedCooldown}s)'
                      : 'Beri Makan',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.green.shade200,
              disabledForegroundColor: Colors.green.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Button Latihan
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: (_isTraining || trainCooldown > 0) ? null : () => _trainPet(pet),
            icon: _isTraining
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.fitness_center),
            label: Text(
              _isTraining
                  ? 'Memproses...'
                  : trainCooldown > 0
                      ? 'Lelah (${trainCooldown}s)'
                      : 'Latihan',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: themeColor,
              disabledForegroundColor: themeColor.withOpacity(0.4),
              side: BorderSide(
                color: (_isTraining || trainCooldown > 0)
                    ? themeColor.withOpacity(0.3)
                    : themeColor,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
