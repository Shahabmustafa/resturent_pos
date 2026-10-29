import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../data/model/table_model.dart';
import '../provider/table_provider.dart';
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
  void _showAddDialog() {
    final tables = ref.read(tableProvider).tables;
    showDialog(
      context: context,
      builder: (_) => AddTableDialog(
        nextNumber: tables.length + 1,
        onAdd: (number) => ref.read(tableProvider.notifier).addTable(number),
      ),
    );
  }

  void _showQrDialog() {
    showDialog(
      context: context,
      builder: (_) => TableQrDialog(tables: ref.read(tableProvider).tables),
    );
  }

  void _confirmDelete(TableModel table) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Delete Table',
          style: TextStyle(color: kText, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '${table.tableNumber} will be deleted. Are you sure?',
          style: const TextStyle(color: kSub),
        ),
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
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              ref.read(tableProvider.notifier).deleteTable(table.id);
              Navigator.pop(ctx);
            },
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tableProvider);
    final tables = state.tables;

    ref.listen<TableState>(tableProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          TableTopBarWidget(onAdd: _showAddDialog, onQrCodes: _showQrDialog),
          Expanded(
            child: state.isLoading
                ? const TableBodySkeleton()
                : RefreshIndicator(
                    color: kPrimary,
                    onRefresh: () =>
                        ref.read(tableProvider.notifier).fetchTables(),
                    child: tables.isEmpty
                        ? ListView(
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(48),
                                child: Center(
                                  child: Text(
                                    'No tables yet',
                                    style: TextStyle(color: kMuted),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            itemCount: tables.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final t = tables[i];
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: kBorder),
                                ),
                                child: ListTile(
                                  title: Text(
                                    t.tableNumber,
                                    style: const TextStyle(
                                      color: kText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _confirmDelete(t),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
