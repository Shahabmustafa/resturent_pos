import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

// ─── Branch User (branch_users table) ────────────────────────────────────────
class BranchUser {
  final String id;
  final String branchId;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String role; // admin | manager | cashier | chef | rider | waiter
  final String status; // active | inactive
  final String? avatarUrl;
  final DateTime createdAt;

  const BranchUser({
    required this.id,
    required this.branchId,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.avatarUrl,
    required this.createdAt,
  });

  factory BranchUser.fromJson(Map<String, dynamic> json) => BranchUser(
    id: json['id'] as String,
    branchId: json['branch_id'] as String,
    name: json['name'] as String? ?? '',
    username: json['username'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    role: json['role'] as String? ?? 'admin',
    status: json['status'] as String? ?? 'active',
    avatarUrl: json['avatar_url'] as String?,
    createdAt: DateTime.tryParse(
        json['created_at'] as String? ?? '') ??
        DateTime.now(),
  );

  BranchUser copyWith({
    String? name,
    String? username,
    String? email,
    String? phone,
    String? role,
    String? status,
  }) =>
      BranchUser(
        id: id,
        branchId: branchId,
        name: name ?? this.name,
        username: username ?? this.username,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        status: status ?? this.status,
        avatarUrl: avatarUrl,
        createdAt: createdAt,
      );
}

// ─── Branch (branches table) ──────────────────────────────────────────────────
class Branch {
  final String id;
  final String companyId;
  final String name;
  final String city;
  final String address;
  final String phone;
  final String ntn;
  final int tables;
  final Color color;
  final bool isOpen;
  final bool isActive;
  final double monthSales;
  final double target;

  // Admin user loaded from branch_users
  final BranchUser? adminUser;

  const Branch({
    required this.id,
    required this.companyId,
    required this.name,
    required this.city,
    required this.address,
    required this.phone,
    required this.ntn,
    required this.tables,
    required this.color,
    required this.isOpen,
    required this.isActive,
    required this.monthSales,
    required this.target,
    this.adminUser,
  });

  double get targetPct => (monthSales / target).clamp(0.0, 1.0);

  factory Branch.fromJson(Map<String, dynamic> json,
      {Color? color, BranchUser? adminUser}) {
    return Branch(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      ntn: json['ntn'] as String? ?? '',
      tables: json['tables'] as int? ?? 0,
      color: color ?? AppColors.branchColors[0],
      isOpen: json['is_open'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
      monthSales: (json['month_sales'] as num?)?.toDouble() ?? 0,
      target: (json['target'] as num?)?.toDouble() ?? 1000000,
      adminUser: adminUser,
    );
  }

  Branch copyWith({
    String? name,
    String? city,
    String? address,
    String? phone,
    String? ntn,
    int? tables,
    Color? color,
    bool? isOpen,
    bool? isActive,
    BranchUser? adminUser,
  }) =>
      Branch(
        id: id,
        companyId: companyId,
        name: name ?? this.name,
        city: city ?? this.city,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        ntn: ntn ?? this.ntn,
        tables: tables ?? this.tables,
        color: color ?? this.color,
        isOpen: isOpen ?? this.isOpen,
        isActive: isActive ?? this.isActive,
        monthSales: monthSales,
        target: target,
        adminUser: adminUser ?? this.adminUser,
      );
}