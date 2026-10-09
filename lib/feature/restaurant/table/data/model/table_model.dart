// feature/branch/tables/data/model/table_model.dart

import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

enum TableFloor { ground, firstFloor, secondFloor, rooftop }
enum TableSection { indoor, outdoor, vip, balcony, garden }
enum TableStatus { available, reserved, cleaning }

extension TableFloorX on TableFloor {
  String toJson() => const {
    TableFloor.ground:       'ground',
    TableFloor.firstFloor:   '1st_floor',
    TableFloor.secondFloor:  '2nd_floor',
    TableFloor.rooftop:      'rooftop',
  }[this]!;

  String get label => const {
    TableFloor.ground:       'Ground',
    TableFloor.firstFloor:   '1st Floor',
    TableFloor.secondFloor:  '2nd Floor',
    TableFloor.rooftop:      'Rooftop',
  }[this]!;

  static TableFloor fromJson(String v) => const {
    'ground':     TableFloor.ground,
    '1st_floor':  TableFloor.firstFloor,
    '2nd_floor':  TableFloor.secondFloor,
    'rooftop':    TableFloor.rooftop,
  }[v]!;
}

extension TableSectionX on TableSection {
  String toJson() => name; // indoor, outdoor, vip, balcony, garden
  String get label => name[0].toUpperCase() + name.substring(1);
  static TableSection fromJson(String v) =>
      TableSection.values.firstWhere((e) => e.name == v);
}

extension TableStatusX on TableStatus {
  String toJson() => name; // available, reserved, cleaning
  String get label => name[0].toUpperCase() + name.substring(1);

  Color get color {
    switch (this) {
      case TableStatus.available: return kGreen;
      case TableStatus.reserved:  return kPrimary;
      case TableStatus.cleaning:  return kYellow;
    }
  }

  AppIcon get icon {
    switch (this) {
      case TableStatus.available: return AppIcons.checkCircleRounded;
      case TableStatus.reserved:  return AppIcons.eventSeatRounded;
      case TableStatus.cleaning:  return AppIcons.cleaningServicesRounded;
    }
  }

  static TableStatus fromJson(String v) =>
      TableStatus.values.firstWhere((e) => e.name == v);
}

class TableModel {
  final String id;
  final String branchId;
  final String tableNumber;
  final int capacity;
  final TableFloor floor;
  final TableSection section;
  TableStatus status;
  final bool isActive;
  final DateTime createdAt;
  /// Secret code in the table's QR (website opened at `?table=<qrToken>`).
  final String qrToken;

  TableModel({
    required this.id,
    required this.branchId,
    required this.tableNumber,
    required this.capacity,
    required this.floor,
    required this.section,
    required this.status,
    required this.isActive,
    required this.createdAt,
    this.qrToken = '',
  });

  factory TableModel.fromJson(Map<String, dynamic> json) => TableModel(
    id:          json['id'] as String,
    branchId:    json['branch_id'] as String,
    tableNumber: json['table_number'] as String,
    capacity:    json['capacity'] as int,
    floor:       TableFloorX.fromJson(json['floor'] as String),
    section:     TableSectionX.fromJson(json['section'] as String),
    status:      TableStatusX.fromJson(json['status'] as String),
    isActive:    json['is_active'] as bool? ?? true,
    createdAt:   DateTime.parse(json['created_at'] as String),
    qrToken:     json['qr_token'] as String? ?? '',
  );

  Map<String, dynamic> toInsertJson(String branchId) => {
    'branch_id':    branchId,
    'table_number': tableNumber,
    'capacity':     capacity,
    'floor':        floor.toJson(),
    'section':      section.toJson(),
    'status':       status.toJson(),
    'is_active':    isActive,
  };
}