// feature/branch/tables/presentation/widget/table_summary_widget.dart

import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/stat_card.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../data/model/table_model.dart';

class TableSummaryRow extends StatelessWidget {
  final List<TableModel> tables;
  const TableSummaryRow({super.key, required this.tables});

  @override
  Widget build(BuildContext context) {
    final total     = tables.length;
    final available = tables.where((t) => t.status == TableStatus.available).length;
    final reserved  = tables.where((t) => t.status == TableStatus.reserved).length;
    final cleaning  = tables.where((t) => t.status == TableStatus.cleaning).length;

    return StatCardRow(cards: [
      StatCardData(AppIcons.tableRestaurantRounded,    'Total Tables', '$total',     kBlue),
      StatCardData(AppIcons.checkCircleOutlineRounded, 'Available',    '$available', kGreen),
      StatCardData(AppIcons.eventSeatRounded,          'Reserved',     '$reserved',  kPrimary),
      StatCardData(AppIcons.cleaningServicesRounded,   'Cleaning',     '$cleaning',  kYellow),
    ]);
  }
}
