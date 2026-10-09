class BranchAuthModel {
  final String id;
  final String branchId;
  final String name;
  final String username;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  BranchAuthModel({
    required this.id,
    required this.branchId,
    required this.name,
    required this.username,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BranchAuthModel.fromJson(Map<String, dynamic> json) {
    return BranchAuthModel(
      id: json['id'] as String,
      branchId: json['branch_id'] as String,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'staff',
      status: json['status'] as String? ?? 'active',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branch_id': branchId,
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}