import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../models/pet.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import 'pet_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _gameService = GameService();
  
  late PageController _pageController;
  double _currentPage = 0.0;
  Timer? _uiTimer;

  // Set untuk menyimpan id pet yang sedang diproses agar animasi loading terlihat individual
  final Set<String> _activeFeedingPets = {};
  final Set<String> _activeTrainingPets = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8)
      ..addListener(() {
        if (mounted) {
          setState(() {
            _currentPage = _pageController.page ?? 0.0;
          });
        }
      });

    // Jalankan timer pembaruan 1 detik untuk menghitung mundur cooldown live
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _uiTimer?.cancel();
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
    if (_activeFeedingPets.contains(pet.id)) return;
    setState(() => _activeFeedingPets.add(pet.id));

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
      setState(() => _activeFeedingPets.remove(pet.id));
    }
  }

  Future<void> _trainPet(Pet pet) async {
    if (_activeTrainingPets.contains(pet.id)) return;
    setState(() => _activeTrainingPets.add(pet.id));

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
      setState(() => _activeTrainingPets.remove(pet.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Tidak ada sesi login.')),
      );
    }

    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    // Hitung dimensi kartu secara responsif berdasarkan tinggi layar (Rasio emas 282.64 / 612.0 = 0.4618)
    double cardHeight = screenHeight * 0.58;
    if (cardHeight > 612.0) {
      cardHeight = 612.0;
    } else if (cardHeight < 450.0) {
      cardHeight = 450.0;
    }
    double cardWidth = cardHeight * 0.4618;

    // Batasi lebar kartu agar tidak overflow secara horizontal pada layar sempit (viewportFraction = 0.8)
    final double maxCardWidth = screenWidth * 0.72;
    if (cardWidth > maxCardWidth) {
      cardWidth = maxCardWidth;
      cardHeight = cardWidth / 0.4618;
    }

    return StreamBuilder<List<Pet>>(
      stream: _gameService.getOwnedPetsStream(currentUser.uid),
      builder: (context, snapshot) {
        final pets = snapshot.data ?? [];

        // Hitung warna glow latar belakang berdasarkan pet aktif di carousel
        Color activeThemeColor = Colors.blue.shade600;
        if (pets.isNotEmpty && _currentPage.round() < pets.length) {
          final activePet = pets[_currentPage.round()];
          activeThemeColor = Color(
            int.parse(Pet.getTipeColor(activePet.tipe).substring(1), radix: 16) +
                0xFF000000,
          );
        }

        return Scaffold(
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
              child: Stack(
                children: [
                  // Ambient neon glow di background kiri atas
                  Positioned(
                    top: screenHeight * 0.15,
                    left: -80,
                    child: _BackgroundBlob(
                      color: activeThemeColor.withOpacity(0.18),
                      size: 320,
                    ),
                  ),

                  // Ambient neon glow di background kanan bawah
                  Positioned(
                    bottom: screenHeight * 0.05,
                    right: -100,
                    child: _BackgroundBlob(
                      color: Colors.orange.withOpacity(0.1),
                      size: 360,
                    ),
                  ),

                  // Konten Utama
                  Column(
                    children: [
                      // Header Profil Pengguna
                      _buildHeader(currentUser),

                      // Carousel Kartu / Empty State
                      Expanded(
                        child: pets.isEmpty
                            ? _buildEmptyState(cardWidth, cardHeight)
                            : PageView.builder(
                                controller: _pageController,
                                itemCount: pets.length,
                                itemBuilder: (context, index) {
                                  final pet = pets[index];

                                  // Efek kedalaman 3D menggunakan transformasi matriks scaling
                                  double scaleValue = 1.0;
                                  if (_pageController.position.haveDimensions) {
                                    scaleValue = (_currentPage - index);
                                    scaleValue =
                                        (1 - (scaleValue.abs() * 0.15)).clamp(0.0, 1.0);
                                  } else {
                                    scaleValue = index == 0 ? 1.0 : 0.85;
                                  }

                                  final feedCooldown = _getFeedCooldownSeconds(pet);
                                  final trainCooldown = _getTrainCooldownSeconds(pet);

                                  return Transform.scale(
                                    scale: scaleValue,
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: InteractivePetCard(
                                        pet: pet,
                                        width: cardWidth,
                                        height: cardHeight,
                                        onTap: () => _openPetDetail(pet),
                                        actionButtons: _buildCardActions(
                                          context,
                                          pet,
                                          feedCooldown,
                                          trainCooldown,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _scanNfc,
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
            elevation: 8,
            icon: const Icon(Icons.nfc),
            label: Text(AuthService.useMockMode ? 'Simulasi Scan' : 'Scan NFC'),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _buildHeader(AppUser currentUser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.1),
            child: const Icon(
              Icons.person,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Selamat datang!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                  ),
                ),
                Text(
                  currentUser.email,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white.withOpacity(0.6)),
            onPressed: _showGameStats,
            tooltip: 'Statistik Game',
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red.shade400),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double width, double height) {
    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.4),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.nfc_outlined,
                      size: 64,
                      color: Colors.orange.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Kandang Kosong',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AuthService.useMockMode
                        ? 'Ketuk tombol "Simulasi Scan" di bawah untuk mendapatkan hewan pertama Anda!'
                        : 'Dekatkan kartu atau tag NFC Anda ke bagian belakang ponsel untuk mengklaim hewan peliharaan baru!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardActions(
    BuildContext context,
    Pet pet,
    int feedCooldown,
    int trainCooldown,
  ) {
    final isFeeding = _activeFeedingPets.contains(pet.id);
    final isTraining = _activeTrainingPets.contains(pet.id);

    return Row(
      children: [
        Expanded(
          child: _GlassButton(
            text: feedCooldown > 0 ? '${feedCooldown}s' : 'Makan',
            icon: Icons.restaurant,
            color: Colors.green.shade400,
            isLoading: isFeeding,
            onPressed: feedCooldown > 0 ? null : () => _feedPet(pet),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _GlassButton(
            text: trainCooldown > 0 ? '${trainCooldown}s' : 'Latih',
            icon: Icons.fitness_center,
            color: Colors.blue.shade400,
            isLoading: isTraining,
            onPressed: trainCooldown > 0 ? null : () => _trainPet(pet),
          ),
        ),
      ],
    );
  }

  Future<void> _scanNfc() async {
    if (AuthService.useMockMode) {
      _showSimulateScanDialog();
      return;
    }
    // Logika asli scan NFC
    try {
      final nfcService = GameService();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSimulateScanDialog() {
    final parentContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Simulasi Scan NFC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih tag NFC hewan peliharaan untuk memicu event klaim:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.pets, color: Colors.blue),
              title: const Text('Kucing Api'),
              subtitle: const Text('Tag: 04-6E-9C-7A-81-5B-80 (Langka)'),
              onTap: () {
                Navigator.pop(dialogContext);
                _gameService.klaimHewan(parentContext, "04-6E-9C-7A-81-5B-80");
              },
            ),
            ListTile(
              leading: const Icon(Icons.pets, color: Colors.purple),
              title: const Text('Naga Air'),
              subtitle: const Text('Tag: AA-BB-CC-DD-EE-FF-00 (Epik)'),
              onTap: () {
                Navigator.pop(dialogContext);
                _gameService.klaimHewan(parentContext, "AA-BB-CC-DD-EE-FF-00");
              },
            ),
            ListTile(
              leading: const Icon(Icons.pets, color: Colors.green),
              title: const Text('Kelinci Petir'),
              subtitle: const Text('Tag: 11-22-33-44-55-66-77 (Umum)'),
              onTap: () {
                Navigator.pop(dialogContext);
                _gameService.klaimHewan(parentContext, "11-22-33-44-55-66-77");
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  void _openPetDetail(Pet pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetDetailScreen(pet: pet),
      ),
    );
  }

  Future<void> _showGameStats() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final stats = await _gameService.getGameStats();
      Navigator.pop(context);

      if (stats != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Statistik Game'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Hewan: ${stats['total_hewan']}'),
                Text('Hewan Terklaim: ${stats['hewan_terklaim']}'),
                Text('Hewan Tersedia: ${stats['hewan_tersedia']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error mendapatkan statistik: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class InteractivePetCard extends StatelessWidget {
  final Pet pet;
  final double width;
  final double height;
  final VoidCallback onTap;
  final Widget actionButtons;

  const InteractivePetCard({
    Key? key,
    required this.pet,
    required this.width,
    required this.height,
    required this.onTap,
    required this.actionButtons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeColor = Color(
      int.parse(Pet.getTipeColor(pet.tipe).substring(1), radix: 16) + 0xFF000000,
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.55), // Glassmorphism
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: themeColor.withOpacity(0.35),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.12),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Column(
            children: [
              // Top 3D Section
              Expanded(
                flex: 11,
                child: Stack(
                  children: [
                    // Glow background behind 3D
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
                    // Model Viewer
                    Positioned.fill(
                      child: ModelViewer(
                        src: pet.modelUrl,
                        alt: "Model 3D ${pet.namaHewan}",
                        ar: false,
                        autoRotate: false,
                        cameraControls: true,
                        backgroundColor: Colors.transparent,
                        loading: Loading.eager,
                        disableZoom: true,
                      ),
                    ),
                    // Rarity Badge (Floating)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: themeColor.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          pet.tipe,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: themeColor,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Clickable Zoom Icon / Hint
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: const Icon(
                              Icons.zoom_in,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Rotation Helper Info (Floating Bottom)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.threesixty, color: Colors.white70, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Putar 3D',
                              style: TextStyle(color: Colors.white70, fontSize: 8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.08),
              ),

              // Bottom Info Section
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Name & Level
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              pet.namaHewan,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'LV. ${pet.level}',
                            style: TextStyle(
                              color: Colors.amber.shade400,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),

                      // EXP bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pengalaman (EXP)',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                '${pet.exp}/100',
                                style: TextStyle(
                                  color: Colors.amber.shade300,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: pet.exp / 100.0,
                              minHeight: 6,
                              backgroundColor: Colors.white.withOpacity(0.08),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.amber.shade500),
                            ),
                          ),
                        ],
                      ),

                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    size: 14,
                                    color: Colors.red.shade400,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'HP: ${pet.currentHp}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.flash_on,
                                    size: 14,
                                    color: Colors.orange.shade400,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'ATK: ${pet.currentAttack}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Action Buttons
                      actionButtons,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GlassButton({
    Key? key,
    required this.text,
    required this.icon,
    required this.color,
    required this.isLoading,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isDisabled
                ? Colors.white.withOpacity(0.04)
                : color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDisabled
                  ? Colors.white.withOpacity(0.08)
                  : color.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 13,
                      color: isDisabled ? Colors.white24 : color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDisabled ? Colors.white24 : Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BackgroundBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _BackgroundBlob({
    Key? key,
    required this.color,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0.0),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}
