class AccountUser {
  const AccountUser({
    required this.id,
    required this.phoneNumber,
    required this.roles,
  });

  final String id;
  final String phoneNumber;
  final List<String> roles;

  bool get isProfessional => roles.contains('ROLE_PROFESSIONAL');
  bool get isAdmin => roles.contains('ROLE_ADMIN');

  factory AccountUser.fromJson(Map<String, dynamic> json) {
    return AccountUser(
      id: json['id']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}
