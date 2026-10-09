// feature/branch/users/data/model/branch_user_model.dart

import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';

enum BranchUserRole { admin, manager, cashier, chef, rider, waiter }
enum BranchUserStatus { active, inactive }

extension BranchUserRoleX on BranchUserRole {
  String toJson() => name;

  static BranchUserRole fromJson(String v) =>
      BranchUserRole.values.firstWhere((e) => e.name == v);

  String get label => switch (this) {
    BranchUserRole.admin   => 'Admin',
    BranchUserRole.manager => 'Manager',
    BranchUserRole.cashier => 'Cashier',
    BranchUserRole.chef    => 'Chef',
    BranchUserRole.rider   => 'Rider',
    BranchUserRole.waiter  => 'Waiter',
  };

  AppIcon get icon => switch (this) {
    BranchUserRole.admin   => AppIcons.shieldRounded,
    BranchUserRole.manager => AppIcons.manageAccountsRounded,
    BranchUserRole.cashier => AppIcons.pointOfSaleRounded,
    BranchUserRole.chef    => AppIcons.soupKitchenRounded,
    BranchUserRole.rider   => AppIcons.deliveryDiningRounded,
    BranchUserRole.waiter  => AppIcons.roomServiceRounded,
  };

  Color get color => switch (this) {
    BranchUserRole.admin   => const Color(0xFF7C3AED),
    BranchUserRole.manager => const Color(0xFF1D4ED8),
    BranchUserRole.cashier => const Color(0xFF0369A1),
    BranchUserRole.chef    => const Color(0xFF15803D),
    BranchUserRole.rider   => const Color(0xFFB45309),
    BranchUserRole.waiter  => const Color(0xFFBE185D),
  };

  Color get bgColor => switch (this) {
    BranchUserRole.admin   => const Color(0xFFF5F3FF),
    BranchUserRole.manager => const Color(0xFFEFF6FF),
    BranchUserRole.cashier => const Color(0xFFE0F2FE),
    BranchUserRole.chef    => const Color(0xFFF0FDF4),
    BranchUserRole.rider   => const Color(0xFFFFFBEB),
    BranchUserRole.waiter  => const Color(0xFFFDF2F8),
  };

  List<String> get allowedPages => switch (this) {
    // Keep in sync with _roleAccess in core/widget/drawer.dart.
    BranchUserRole.admin   => ['POS','Orders','Delivery','Tables','Menu','Users','Settings'],
    BranchUserRole.manager => ['POS','Orders','Delivery','Tables','Menu'],
    BranchUserRole.cashier => ['POS', 'Orders'],
    BranchUserRole.chef    => ['Orders'],
    BranchUserRole.rider   => ['Delivery'],
    BranchUserRole.waiter  => ['POS', 'Tables', 'Orders'],
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

  factory BranchUserModel.fromJson(Map<String, dynamic> json) => BranchUserModel(
    id:        json['id'] as String,
    branchId:  json['branch_id'] as String,
    name:      json['name'] as String,
    username:  json['username'] as String,
    email:     json['email'] as String? ?? '',
    phone:     json['phone'] as String?,
    role:      BranchUserRoleX.fromJson(json['role'] as String),
    status:    BranchUserStatusX.fromJson(json['status'] as String),
    avatarUrl: json['avatar_url'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  /// Body for the manage-branch-user Edge Function (action: create).
  Map<String, dynamic> toCreateBody(String branchId) => {
    'action':     'create',
    'branch_id':  branchId,
    'email':      email,
    'password':   password,
    'name':       name,
    'username':   username,
    'phone':      phone,
    'role':       role.toJson(),
    'status':     status.toJson(),
    'avatar_url': avatarUrl,
  };

  /// Body for the manage-branch-user Edge Function (action: update).
  /// An empty password keeps the existing one.
  Map<String, dynamic> toUpdateBody() => {
    'action':     'update',
    'user_id':    id,
    'email':      email,
    if (password.isNotEmpty) 'password': password,
    'name':       name,
    'username':   username,
    'phone':      phone,
    'role':       role.toJson(),
    'status':     status.toJson(),
    'avatar_url': avatarUrl,
  };
}
