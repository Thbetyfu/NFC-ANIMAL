import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
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
    // Jalankan timer setiap 1 detik untuk memutakhirkan hitung mundur cooldown live
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
    final remaining = 180 - diff.inSeconds; // Cooldown 3 menit
    return remaining > 0 ? remaining : 0;
  }

  int _getTrainCooldownSeconds(Pet pet) {
    if (pet.terakhirLatihan == null) return 0;
    final diff = DateTime.now().difference(pet.terakhirLatihan!);
    final remaining = 180 - diff.inSeconds; // Cooldown 3 menit
    return remaining > 0 ? remaining : 0;
  }

  Future<void> _feedPet(Pet pet) async {
    if (_isFeeding) return;
    setState(() => _isFeeding = true);

    final result = await _gameService.beriMakan(context, pet.id);
    if (result != null && mounted) {
      final msg = result['message'] ?? 'Hewan berhasil diberi makan!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.green.shade600,
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
    if (result != null && mounted) {
      final msg = result['message'] ?? 'Latihan hewan selesai!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.blue.shade600,
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
    final themeColor = Color(
      int.parse(Pet.getTipeColor(widget.pet.tipe).substring(1), radix: 16) + 0xFF000000,
    );

    return StreamBuilder<Pet?>(
      stream: _gameService.getPetStream(widget.pet.id),
      builder: (context, snapshot) {
        final pet = snapshot.data ?? widget.pet;

        final feedCooldown = _getFeedCooldownSeconds(pet);
        final trainCooldown = _getTrainCooldownSeconds(pet);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
            title: Text(
              pet.namaHewan,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            centerTitle: true,
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A), // Slate 900
                  Color(0xFF1E293B), // Slate 800
                  Color(0xFF020617), // Slate 950
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3D Model Viewer container
                    Container(
                      height: 380,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: themeColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      themeColor.withOpacity(0.22),
                                      Colors.transparent,
                                    ],
                                    radius: 0.75,
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: ModelViewer(
                                src: pet.modelUrl,
                                alt: "Model 3D dari ${pet.namaHewan}",
                                ar: true,
                                autoRotate: false,
                                cameraControls: true,
                                backgroundColor: Colors.transparent,
                                loading: Loading.eager,
                                disableZoom: false,
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.threesixty,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Putar 3D',
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
                    ),

                    // Detail Information
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Name & Badges
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  pet.namaHewan,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 26,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: themeColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: themeColor.withOpacity(0.4),
                                      ),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade700.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.amber.shade500.withOpacity(0.5),
                                      ),
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
                          const SizedBox(height: 20),

                          // EXP progress bar
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.06),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Pengalaman (EXP)',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${pet.exp} / 100',
                                      style: TextStyle(
                                        color: Colors.amber.shade300,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: pet.exp / 100.0,
                                    minHeight: 10,
                                    backgroundColor: Colors.white.withOpacity(0.08),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.amber.shade500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Deskripsi
                          _buildSection(
                            'Deskripsi',
                            pet.deskripsi,
                            Icons.description_outlined,
                            themeColor,
                          ),
                          const SizedBox(height: 24),

                          // Stats
                          _buildStatsSection(pet),
                          const SizedBox(height: 24),

                          // Tag Info
                          _buildInfoSection(pet),
                          const SizedBox(height: 32),

                          // Actions
                          _buildActionButtons(
                            context,
                            pet,
                            feedCooldown,
                            trainCooldown,
                            themeColor,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(
    String title,
    String content,
    IconData icon,
    Color themeColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(Pet pet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.trending_up, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              'Statistik Peliharaan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
                Colors.red.shade400,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Attack',
                '${pet.currentAttack}',
                Icons.flash_on,
                Colors.orange.shade400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.bold,
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
        const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              'Informasi Tag',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.nfc, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Tag NFC ID:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                pet.id,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.amber,
                  fontSize: 13,
                ),
              ),
              if (pet.diklaimPada != null) ...[
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Diklaim pada:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${pet.diklaimPada!.day}/${pet.diklaimPada!.month}/${pet.diklaimPada!.year} ${pet.diklaimPada!.hour.toString().padLeft(2, '0')}:${pet.diklaimPada!.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Pet pet,
    int feedCooldown,
    int trainCooldown,
    Color themeColor,
  ) {
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
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
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
              disabledBackgroundColor: Colors.white.withOpacity(0.04),
              disabledForegroundColor: Colors.white24,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: feedCooldown > 0
                      ? Colors.white.withOpacity(0.08)
                      : Colors.transparent,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Button Latihan
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: (_isTraining || trainCooldown > 0) ? null : () => _trainPet(pet),
            icon: _isTraining
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white.withOpacity(0.04),
              disabledForegroundColor: Colors.white24,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: trainCooldown > 0
                      ? Colors.white.withOpacity(0.08)
                      : Colors.transparent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
