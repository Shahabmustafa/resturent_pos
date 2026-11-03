// feature/branch/users/data/model/branch_user_model.dart

import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';

enum BranchUserRole { admin, cashier }

enum BranchUserStatus { active, inactive }

extension BranchUserRoleX on BranchUserRole {
  String toJson() => name;

  /// Staff saved with an older role (manager, chef, rider, waiter) show as cashier.
  static BranchUserRole fromJson(String v) => BranchUserRole.values.firstWhere(
    (e) => e.name == v,
    orElse: () => BranchUserRole.cashier,
  );

  String get label => switch (this) {
    BranchUserRole.admin => 'Admin',
    BranchUserRole.cashier => 'Cashier',
  };

  AppIcon get icon => switch (this) {
    BranchUserRole.admin => AppIcons.shieldRounded,
    BranchUserRole.cashier => AppIcons.pointOfSaleRounded,
  };

  Color get color => switch (this) {
    BranchUserRole.admin => const Color(0xFF7C3AED),
    BranchUserRole.cashier => const Color(0xFF0369A1),
  };

  Color get bgColor => switch (this) {
    BranchUserRole.admin => const Color(0xFFF5F3FF),
    BranchUserRole.cashier => const Color(0xFFE0F2FE),
  };

  List<String> get allowedPages => switch (this) {
    // Keep in sync with _roleAccess in core/widget/drawer.dart.
    BranchUserRole.admin => [
      'POS',
      'Orders',
      'Delivery',
      'Tables',
      'Menu',
      'Users',
      'Settings',
    ],
    BranchUserRole.cashier => [
      'POS',
      'Orders',
      'Customers',
      'Cash Counter',
      'Till',
      'Notes',
    ],
  };
}

extension BranchUserStatusX on BranchUserStatus {
  String toJson() => name;
  static BranchUserStatus fromJson(String v) =>
      BranchUserStatus.values.firstWhere((e) => e.name == v);
}

class BranchUserModel {
  final String id;
  final String branchId;
  String name;
  String username;
  String email;
  String? phone;

  /// Only used to send a new password from the form. Never read from the database.
  String password;
  BranchUserRole role;
  BranchUserStatus status;
  String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  BranchUserModel({
    required this.id,
    required this.branchId,
    required this.name,
    required this.username,
    required this.email,
    this.phone,
    this.password = '',
    required this.role,
    required this.status,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory BranchUserModel.fromJson(Map<String, dynamic> json) =>
      BranchUserModel(
        id: json['id'] as String,
        branchId: json['branch_id'] as String,
        name: json['name'] as String,
        username: json['username'] as String,
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        role: BranchUserRoleX.fromJson(json['role'] as String),
        status: BranchUserStatusX.fromJson(json['status'] as String),
        avatarUrl: json['avatar_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  /// Body for the manage-branch-user Edge Function (action: create).
  Map<String, dynamic> toCreateBody(String branchId) => {
    'action': 'create',
    'branch_id': branchId,
    'email': email,
    'password': password,
    'name': name,
    'username': username,
    'phone': phone,
    'role': role.toJson(),
    'status': status.toJson(),
    'avatar_url': avatarUrl,
  };

  /// Body for the manage-branch-user Edge Function (action: update).
  /// An empty password keeps the existing one.
  Map<String, dynamic> toUpdateBody() => {
    'action': 'update',
    'user_id': id,
    'email': email,
    if (password.isNotEmpty) 'password': password,
    'name': name,
    'username': username,
    'phone': phone,
    'role': role.toJson(),
    'status': status.toJson(),
    'avatar_url': avatarUrl,
  };
}
