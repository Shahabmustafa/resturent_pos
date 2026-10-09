class CompanyModel {
  final String id;
  final String name;
  final String slug;
  final String? phone;
  final String? logoUrl;
  final String? city;
  final String? address;
  final String username;
  final String plan;
  final DateTime? planExpiresAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CompanyModel({
    required this.id,
    required this.name,
    required this.slug,
    this.phone,
    this.logoUrl,
    this.city,
    this.address,
    required this.username,
    required this.plan,
    this.planExpiresAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      phone: json['phone'] as String?,
      logoUrl: json['logo_url'] as String?,
      city: json['city'] as String?,
      address: json['address'] as String?,
      username: json['username'] as String? ?? '',
      plan: json['plan'] as String? ?? 'trial',
      planExpiresAt: json['plan_expires_at'] != null
          ? DateTime.parse(json['plan_expires_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'phone': phone,
      'logo_url': logoUrl,
      'city': city,
      'address': address,
      'username': username,
      'plan': plan,
      'plan_expires_at': planExpiresAt?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}