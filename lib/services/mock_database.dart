import 'dart:async';
import '../models/pet.dart';
import '../models/user.dart';

class MockDatabase {
  static final MockDatabase instance = MockDatabase._internal();
  MockDatabase._internal() {
    _initData();
  }

  // State
  final List<Pet> _pets = [];
  final Map<String, AppUser> _users = {};
  AppUser? _currentUser;

  // Streams
  final StreamController<AppUser?> _authStreamController = StreamController<AppUser?>.broadcast();
  final StreamController<List<Pet>> _petsStreamController = StreamController<List<Pet>>.broadcast();
  final Map<String, StreamController<Pet?>> _petDetailControllers = {};

  void _initData() {
    // Seeding master_hewan awal
    _pets.addAll([
      Pet(
        id: "04-6E-9C-7A-81-5B-80",
        namaHewan: "Kucing Api",
        tipe: "Langka",
        deskripsi: "Seekor kucing yang diselimuti api abadi dan suka berjemur di dekat lava.",
        modelUrl: "https://modelviewer.dev/shared-assets/models/Astronaut.glb",
        statsAwal: {"hp": 100, "attack": 15},
      ),
      Pet(
        id: "AA-BB-CC-DD-EE-FF-00",
        namaHewan: "Naga Air",
        tipe: "Epik",
        deskripsi: "Naga legendaris yang menguasai elemen air dan melindungi samudra terdalam.",
        modelUrl: "https://modelviewer.dev/shared-assets/models/Horse.glb",
        statsAwal: {"hp": 150, "attack": 25},
      ),
      Pet(
        id: "11-22-33-44-55-66-77",
        namaHewan: "Kelinci Petir",
        tipe: "Umum",
        deskripsi: "Kelinci cepat dengan kekuatan listrik statis yang dapat menyengat musuhnya.",
        modelUrl: "https://modelviewer.dev/shared-assets/models/RobotExpressive.glb",
        statsAwal: {"hp": 80, "attack": 12},
      ),
    ]);

    // Seed user mock awal untuk dev mode
    _users["mock_uid_dev"] = AppUser(
      uid: "mock_uid_dev",
      email: "dev@petgame.com",
      username: "DevPlayer",
      dibuatPada: DateTime.now(),
    );
  }

  // Getters
  AppUser? get currentUser => _currentUser;
  Stream<AppUser?> get authStateChanges async* {
    yield _currentUser;
    yield* _authStreamController.stream;
  }

  // Auth Methods
  Future<AppUser> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulasi network delay
    
    // Cari user dengan email yang cocok
    final user = _users.values.firstWhere(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
      orElse: () => throw Exception("User tidak ditemukan. Silakan registrasi terlebih dahulu."),
    );

    _currentUser = user;
    _authStreamController.add(user);
    _notifyPetsUpdated();
    return user;
  }

  Future<AppUser> register(String email, String password, String username) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final emailLower = email.trim().toLowerCase();
    if (_users.values.any((u) => u.email.toLowerCase() == emailLower)) {
      throw Exception("Email sudah digunakan.");
    }

    final newUid = "mock_uid_${DateTime.now().millisecondsSinceEpoch}";
    final newUser = AppUser(
      uid: newUid,
      email: email.trim(),
      username: username.trim(),
      dibuatPada: DateTime.now(),
    );

    _users[newUid] = newUser;
    _currentUser = newUser;
    _authStreamController.add(newUser);
    _notifyPetsUpdated();
    return newUser;
  }

  Future<void> signOut() async {
    _currentUser = null;
    _authStreamController.add(null);
    _notifyPetsUpdated();
  }

  // Pet Streams
  Stream<List<Pet>> getOwnedPetsStream(String userId) {
    // Kirim data saat ini segera
    Timer.run(() => _notifyPetsUpdated());
    return _petsStreamController.stream;
  }

  Stream<Pet?> getPetStream(String petId) {
    if (!_petDetailControllers.containsKey(petId)) {
      _petDetailControllers[petId] = StreamController<Pet?>.broadcast();
    }
    Timer.run(() => _notifyPetDetailUpdated(petId));
    return _petDetailControllers[petId]!.stream;
  }

  void _notifyPetsUpdated() {
    if (_currentUser == null) {
      _petsStreamController.add([]);
      return;
    }
    final owned = _pets.where((p) => p.idPemilik == _currentUser!.uid).toList();
    _petsStreamController.add(owned);
  }

  void _notifyPetDetailUpdated(String petId) {
    final petIdx = _pets.indexWhere((p) => p.id == petId);
    if (petIdx != -1) {
      final pet = _pets[petIdx];
      _petDetailControllers[petId]?.add(pet);
    } else {
      _petDetailControllers[petId]?.add(null);
    }
  }

  // Game Logic
  Future<Pet> klaimHewan(String uidTag) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (_currentUser == null) {
      throw Exception("Pengguna harus login terlebih dahulu.");
    }

    final idx = _pets.indexWhere((p) => p.id == uidTag);
    if (idx == -1) {
      throw Exception("Tag NFC ini tidak valid atau tidak terdaftar dalam sistem.");
    }

    final pet = _pets[idx];
    if (pet.idPemilik != null) {
      throw Exception("Hewan ini sudah diklaim oleh pemain lain. Coba tag NFC yang berbeda.");
    }

    // Update kepemilikan
    final updatedPet = Pet(
      id: pet.id,
      namaHewan: pet.namaHewan,
      tipe: pet.tipe,
      deskripsi: pet.deskripsi,
      modelUrl: pet.modelUrl,
      statsAwal: pet.statsAwal,
      idPemilik: _currentUser!.uid,
      diklaimPada: DateTime.now(),
      level: pet.level,
      exp: pet.exp,
      terakhirDiberiMakan: pet.terakhirDiberiMakan,
      terakhirLatihan: pet.terakhirLatihan,
    );

    _pets[idx] = updatedPet;
    _notifyPetsUpdated();
    _notifyPetDetailUpdated(uidTag);

    return updatedPet;
  }

  Future<Map<String, dynamic>> beriMakan(String uidTag) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final idx = _pets.indexWhere((p) => p.id == uidTag);
    if (idx == -1) throw Exception("Hewan tidak ditemukan.");

    final pet = _pets[idx];
    if (pet.idPemilik != _currentUser?.uid) {
      throw Exception("Anda bukan pemilik hewan ini.");
    }

    // Cek Cooldown (3 menit)
    final sekarang = DateTime.now();
    if (pet.terakhirDiberiMakan != null) {
      final diff = sekarang.difference(pet.terakhirDiberiMakan!);
      if (diff.inSeconds < 180) {
        final sisa = 180 - diff.inSeconds;
        throw Exception("Hewan masih kenyang. Tunggu $sisa detik lagi.");
      }
    }

    // Hitung level & exp
    int level = pet.level;
    int exp = pet.exp + 20;
    bool levelUp = false;

    if (exp >= 100) {
      level += 1;
      exp -= 100;
      levelUp = true;
    }

    final updatedPet = Pet(
      id: pet.id,
      namaHewan: pet.namaHewan,
      tipe: pet.tipe,
      deskripsi: pet.deskripsi,
      modelUrl: pet.modelUrl,
      statsAwal: pet.statsAwal,
      idPemilik: pet.idPemilik,
      diklaimPada: pet.diklaimPada,
      level: level,
      exp: exp,
      terakhirDiberiMakan: sekarang,
      terakhirLatihan: pet.terakhirLatihan,
    );

    _pets[idx] = updatedPet;
    _notifyPetsUpdated();
    _notifyPetDetailUpdated(uidTag);

    return {
      'nama_hewan': pet.namaHewan,
      'level': level,
      'exp': exp,
      'levelUp': levelUp,
      'message': levelUp
          ? "Selamat! ${pet.namaHewan} naik ke Level $level!"
          : "${pet.namaHewan} kenyang dan senang! (+20 EXP)",
    };
  }

  Future<Map<String, dynamic>> latihanHewan(String uidTag) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final idx = _pets.indexWhere((p) => p.id == uidTag);
    if (idx == -1) throw Exception("Hewan tidak ditemukan.");

    final pet = _pets[idx];
    if (pet.idPemilik != _currentUser?.uid) {
      throw Exception("Anda bukan pemilik hewan ini.");
    }

    // Cek Cooldown (3 menit)
    final sekarang = DateTime.now();
    if (pet.terakhirLatihan != null) {
      final diff = sekarang.difference(pet.terakhirLatihan!);
      if (diff.inSeconds < 180) {
        final sisa = 180 - diff.inSeconds;
        throw Exception("Hewan lelah setelah latihan. Tunggu $sisa detik lagi.");
      }
    }

    // Hitung level & exp
    int level = pet.level;
    int exp = pet.exp + 30;
    bool levelUp = false;

    if (exp >= 100) {
      level += 1;
      exp -= 100;
      levelUp = true;
    }

    final updatedPet = Pet(
      id: pet.id,
      namaHewan: pet.namaHewan,
      tipe: pet.tipe,
      deskripsi: pet.deskripsi,
      modelUrl: pet.modelUrl,
      statsAwal: pet.statsAwal,
      idPemilik: pet.idPemilik,
      diklaimPada: pet.diklaimPada,
      level: level,
      exp: exp,
      terakhirDiberiMakan: pet.terakhirDiberiMakan,
      terakhirLatihan: sekarang,
    );

    _pets[idx] = updatedPet;
    _notifyPetsUpdated();
    _notifyPetDetailUpdated(uidTag);

    return {
      'nama_hewan': pet.namaHewan,
      'level': level,
      'exp': exp,
      'levelUp': levelUp,
      'message': levelUp
          ? "Selamat! ${pet.namaHewan} naik ke Level $level!"
          : "${pet.namaHewan} bertambah kuat setelah latihan! (+30 EXP)",
    };
  }

  Map<String, dynamic> getGameStats() {
    final total = _pets.length;
    final claimed = _pets.where((p) => p.idPemilik != null).length;
    return {
      'total_hewan': total,
      'hewan_terklaim': claimed,
      'hewan_tersedia': total - claimed,
    };
  }
}
