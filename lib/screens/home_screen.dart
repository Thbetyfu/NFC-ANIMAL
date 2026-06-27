import 'package:flutter/material.dart';
import '../models/pet.dart';
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

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Tidak ada sesi login.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kandang Saya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showGameStats,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade600,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header dengan info user
            Container(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(
                          Icons.person,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat datang!',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              currentUser.email,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // List hewan peliharaan
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder<List<Pet>>(
                  stream: _gameService.getOwnedPetsStream(currentUser.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error,
                              size: 64,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 16),
                            const Text('Terjadi kesalahan saat memuat data'),
                            TextButton(
                              onPressed: () => setState(() {}),
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      );
                    }

                    final pets = snapshot.data ?? [];

                    if (pets.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pets,
                              size: 96,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada hewan peliharaan',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AuthService.useMockMode
                                  ? 'Ketuk "Scan NFC" untuk melakukan simulasi!'
                                  : 'Scan tag NFC untuk mendapatkan hewan pertama Anda!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: pets.length,
                      itemBuilder: (context, index) {
                        final pet = pets[index];
                        return _buildPetCard(pet);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanNfc,
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.nfc),
        label: Text(AuthService.useMockMode ? 'Simulasi Scan' : 'Scan NFC'),
      ),
    );
  }

  Widget _buildPetCard(Pet pet) {
    final themeColor = Color(int.parse(Pet.getTipeColor(pet.tipe).substring(1), radix: 16) + 0xFF000000);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openPetDetail(pet),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon hewan
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Nama hewan
              Text(
                pet.namaHewan,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Tipe & Level
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pet.tipe,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'LV. ${pet.level}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.favorite, size: 12, color: Colors.red.shade400),
                        const SizedBox(width: 2),
                        Text(
                          '${pet.currentHp}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.flash_on, size: 12, color: Colors.orange.shade400),
                      const SizedBox(width: 2),
                      Text(
                        '${pet.currentAttack}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanNfc() async {
    if (AuthService.useMockMode) {
      _showSimulateScanDialog();
      return;
    }
    // Logika asli scan NFC
    try {
      final nfcService = GameService(); // Mock call via nfc_service as original if wanted
      // Dalam original nfc_service diakses lewat NfcService instans lokal
      // Kita panggil normal jika Firebase mode aktif
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
    final parentContext = context; // Simpan context parent HomeScreen yang aktif dan mounted
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
                Navigator.pop(dialogContext); // Pop the simulate dialog using its local context
                _gameService.klaimHewan(parentContext, "04-6E-9C-7A-81-5B-80"); // Claim using the mounted parent context
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
      Navigator.pop(context); // Tutup loading

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
      Navigator.pop(context); // Tutup loading
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
