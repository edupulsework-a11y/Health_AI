import 'user_role.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String walletAddress;
  final bool abhaVerified;
  final String? profileImageUrl;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.walletAddress,
    this.abhaVerified = false,
    this.profileImageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String? ?? 'regular'),
      walletAddress: json['wallet_address'] as String? ?? '',
      abhaVerified: json['abha_verified'] as bool? ?? false,
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role.name,
        'wallet_address': walletAddress,
        'abha_verified': abhaVerified,
        'profile_image_url': profileImageUrl,
      };

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? walletAddress,
    bool? abhaVerified,
    String? profileImageUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      walletAddress: walletAddress ?? this.walletAddress,
      abhaVerified: abhaVerified ?? this.abhaVerified,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
