import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../data/model/table_model.dart';
import '../provider/table_provider.dart';
import '../widget/table_data_widget.dart';
import '../widget/table_summary_widget.dart';
import '../widget/table_dialog_widget.dart';
import '../widget/table_qr_dialog.dart';
import '../widget/table_skeleton.dart';
import '../widget/table_top_bar_widget.dart';

class TablePage extends ConsumerStatefulWidget {
  const TablePage({super.key});

  @override
  ConsumerState<TablePage> createState() => _TablePageState();
}

class _TablePageState extends ConsumerState<TablePage> {
  String _filterStatus = 'All';
  String _filterFloor  = 'All';
  String _searchQuery  = '';

  List<TableModel> _filtered(List<TableModel> tables) {
    return tables.where((t) {
      final statusMatch = _filterStatus == 'All' ||
          t.status.label == _filterStatus;
      final floorMatch = _filterFloor == 'All' ||
          t.floor.label == _filterFloor;
      final searchMatch = _searchQuery.isEmpty ||
          t.tableNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      return statusMatch && floorMatch && searchMatch;
    }).toList();
  }

  void _showAddDialog() {
    final tables = ref.read(tableProvider).tables;
    showDialog(
      context: context,
      builder: (_) => AddTableDialog(
        nextNumber: tables.length + 1,
        onAdd: (table) => ref.read(tableProvider.notifier).addTable(table),
      ),
    );
  }

  void _showQrDialog() {
    showDialog(
      context: context,
      builder: (_) => TableQrDialog(tables: ref.read(tableProvider).tables),
    );
  }

  void _showStatusDialog(TableModel table) {
    showDialog(
      context: context,
      builder: (_) => StatusChangeDialog(
        table: table,
        onChanged: (s) =>
            ref.read(tableProvider.notifier).updateStatus(table.id, s),
      ),
    );
  }

  void _confirmDelete(TableModel table) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Table',
            style: TextStyle(color: kText, fontWeight: FontWeight.w700)),
        content: Text('${table.tableNumber} will be permanently deleted. Are you sure?',
            style: const TextStyle(color: kSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: kMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              ref.read(tableProvider.notifier).deleteTable(table.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(tableProvider);
    final tables = state.tables;
    final filtered = _filtered(tables);
    final floors = ['All', ...{...tables.map((t) => t.floor.label)}];

    // Error snackbar
    ref.listen<TableState>(tableProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.errorMessage!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          // ── Top Bar ──────────────────────────────────────────────
          TableTopBarWidget(onAdd: _showAddDialog, onQrCodes: _showQrDialog),

          // ── Body ─────────────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const TableBodySkeleton()
                : RefreshIndicator(
              color: kPrimary,
              onRefresh: () =>
                  ref.read(tableProvider.notifier).fetchTables(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary cards
                    TableSummaryRow(tables: tables),
                    const SizedBox(height: 24),

                    // Data table card
                    TableDataWidget(
                      tables: filtered,
                      allTables: tables,
                      filterStatus: _filterStatus,
                      filterFloor: _filterFloor,
                      floors: floors,
                      searchQuery: _searchQuery,
                      onStatusChanged: (s) =>
                          setState(() => _filterStatus = s),
                      onFloorChanged: (f) =>
                          setState(() => _filterFloor = f),
                      onSearchChanged: (q) =>
                          setState(() => _searchQuery = q),
                      onStatusTap: _showStatusDialog,
                      onDelete: _confirmDelete,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}