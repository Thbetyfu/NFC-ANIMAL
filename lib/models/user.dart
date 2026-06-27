class AppUser {
  final String uid;
  final String email;
  final String username;
  final DateTime dibuatPada;

  AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.dibuatPada,
  });

  factory AppUser.fromFirestore(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      dibuatPada: data['dibuat_pada']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'dibuat_pada': dibuatPada,
    };
  }
}
