class BackendUser {
  const BackendUser({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
  });

  final String id;
  final String name;
  final String username;
  final String password;

  Map<String, dynamic> toPublicJson() {
    return {'id': id, 'name': name, 'username': username};
  }
}
