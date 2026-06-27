class Pet {
  final String id;
  final String namaHewan;
  final String tipe;
  final String deskripsi;
  final String modelUrl;
  final Map<String, dynamic> statsAwal;
  final String? idPemilik;
  final DateTime? diklaimPada;
  final int level;
  final int exp;
  final DateTime? terakhirDiberiMakan;
  final DateTime? terakhirLatihan;

  Pet({
    required this.id,
    required this.namaHewan,
    required this.tipe,
    required this.deskripsi,
    required this.modelUrl,
    required this.statsAwal,
    this.idPemilik,
    this.diklaimPada,
    this.level = 1,
    this.exp = 0,
    this.terakhirDiberiMakan,
    this.terakhirLatihan,
  });

  factory Pet.fromFirestore(String id, Map<String, dynamic> data) {
    return Pet(
      id: id,
      namaHewan: data['nama_hewan'] ?? '',
      tipe: data['tipe'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      modelUrl: data['model_url'] ?? '',
      statsAwal: Map<String, dynamic>.from(data['stats_awal'] ?? {}),
      idPemilik: data['id_pemilik'],
      diklaimPada: data['diklaim_pada']?.toDate(),
      level: data['level'] ?? 1,
      exp: data['exp'] ?? 0,
      terakhirDiberiMakan: data['terakhir_diberi_makan']?.toDate(),
      terakhirLatihan: data['terakhir_latihan']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama_hewan': namaHewan,
      'tipe': tipe,
      'deskripsi': deskripsi,
      'model_url': modelUrl,
      'stats_awal': statsAwal,
      'id_pemilik': idPemilik,
      'diklaim_pada': diklaimPada,
      'level': level,
      'exp': exp,
      'terakhir_diberi_makan': terakhirDiberiMakan,
      'terakhir_latihan': terakhirLatihan,
    };
  }

  // Getters untuk statistik yang sudah disesuaikan dengan level
  int get currentHp => (statsAwal['hp'] ?? 0) + (level - 1) * 10;
  int get currentAttack => (statsAwal['attack'] ?? 0) + (level - 1) * 2;

  // Helper untuk mendapatkan warna berdasarkan tipe
  static String getTipeColor(String tipe) {
    switch (tipe.toLowerCase()) {
      case 'umum':
        return '#4CAF50'; // Hijau
      case 'langka':
        return '#2196F3'; // Biru
      case 'epik':
        return '#9C27B0'; // Ungu
      case 'legendaris':
        return '#FF9800'; // Orange
      default:
        return '#757575'; // Abu-abu
    }
  }
}
