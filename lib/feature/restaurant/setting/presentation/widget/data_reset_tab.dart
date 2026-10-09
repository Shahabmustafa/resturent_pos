import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:resturent_application/feature/restaurant/setting/presentation/widget/section_card_widget.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/provider/branch_auth_provider.dart';

class DataResetTab extends ConsumerStatefulWidget {
  const DataResetTab({super.key});

  @override
  ConsumerState<DataResetTab> createState() => _DataResetTabState();
}

class _DataResetTabState extends ConsumerState<DataResetTab> {
  bool _exporting = false;
  String? _exportingKey;

  SupabaseClient get _db => Supabase.instance.client;

  String get _branchId =>
      ref.read(branchAuthProvider).branch?.branchId ?? '';

  // ── CSV export helper ─────────────────────────────────────────────────────
  /// Asks where to save [filename] and writes the rows as CSV.
  Future<void> _downloadCsv(String filename, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) {
      _snack('No data found to export', error: true);
      return;
    }
    final headers = rows.first.keys.join(',');
    final lines = rows.map((r) => r.values.map((v) {
      final s = '$v'.replaceAll('"', '""');
      return '"$s"';
    }).join(',')).join('\n');
    final csv = '$headers\n$lines';

    final location = await getSaveLocation(
      suggestedName: filename,
      acceptedTypeGroups: const [XTypeGroup(label: 'CSV', extensions: ['csv'])],
    );
    if (location == null) return; // user cancelled the save dialog

    await XFile.fromData(utf8.encode(csv), mimeType: 'text/csv', name: filename).saveTo(location.path);
    _snack('Saved $filename');
  }

  // ── Export handlers ───────────────────────────────────────────────────────
  Future<void> _exportOrders() async {
    setState(() { _exporting = true; _exportingKey = 'orders'; });
    try {
      final res = await _db
          .from('orders')
          .select('order_number, order_type, customer_name, customer_phone, table_number, status, payment_method, payment_status, subtotal, discount_amt, tax_amt, total, notes, created_at')
          .eq('branch_id', _branchId)
          .order('created_at', ascending: false);
      await _downloadCsv('orders_history.csv', List<Map<String, dynamic>>.from(res));
    } catch (e) {
      _snack('Export failed: $e', error: true);
    } finally {
      if (mounted) setState(() { _exporting = false; _exportingKey = null; });
    }
  }

  Future<void> _exportFinancial() async {
    setState(() { _exporting = true; _exportingKey = 'financial'; });
    try {
      final res = await _db
          .from('cash_transactions')
          .select('type, ref_label, amount, direction, note, created_at')
          .eq('branch_id', _branchId)
          .order('created_at', ascending: false);
      await _downloadCsv('financial_report.csv', List<Map<String, dynamic>>.from(res));
    } catch (e) {
      _snack('Export failed: $e', error: true);
    } finally {
      if (mounted) setState(() { _exporting = false; _exportingKey = null; });
    }
  }

  Future<void> _exportCustomers() async {
    setState(() { _exporting = true; _exportingKey = 'customers'; });
    try {
      final res = await _db
          .from('customers')
          .select('name, phone, type, orders, spent, balance, loyalty, discount, joined_at')
          .eq('branch_id', _branchId)
          .order('joined_at', ascending: false);
      await _downloadCsv('customers.csv', List<Map<String, dynamic>>.from(res));
    } catch (e) {
      _snack('Export failed: $e', error: true);
    } finally {
      if (mounted) setState(() { _exporting = false; _exportingKey = null; });
    }
  }

  Future<void> _exportInventory() async {
    setState(() { _exporting = true; _exportingKey = 'inventory'; });
    try {
      final res = await _db
          .from('stock_items')
          .select('name, category, unit, qty, min_qty, cost, updated_at')
          .eq('branch_id', _branchId)
          .order('name');
      await _downloadCsv('inventory.csv', List<Map<String, dynamic>>.from(res));
    } catch (e) {
      _snack('Export failed: $e', error: true);
    } finally {
      if (mounted) setState(() { _exporting = false; _exportingKey = null; });
    }
  }

  // ── Reset handlers ────────────────────────────────────────────────────────
  Future<void> _resetOrders() async {
    try {
      // delete orders — order_items are removed by cascade
      await _db.from('orders').delete().eq('branch_id', _branchId);
      // Tables status reset
      await _db.from('tables')
          .update({'status': 'available'})
          .eq('branch_id', _branchId);
      if (mounted) _snack('Orders & sales data reset ✓');
    } catch (e) {
      if (mounted) _snack('Reset failed: $e', error: true);
    }
  }

  Future<void> _resetCustomers() async {
    try {
      await _db.from('customers').delete().eq('branch_id', _branchId);
      if (mounted) _snack('Customer data reset ✓');
    } catch (e) {
      if (mounted) _snack('Reset failed: $e', error: true);
    }
  }

  Future<void> _fullReset() async {
    try {
      // Orders + order_items (cascade)
      await _db.from('orders').delete().eq('branch_id', _branchId);
      // Customers
      await _db.from('customers').delete().eq('branch_id', _branchId);
      // Cash transactions
      await _db.from('cash_transactions').delete().eq('branch_id', _branchId);
      // Branch cash balance reset to 0
      await _db.from('branch_cash')
          .update({'balance': 0, 'updated_at': DateTime.now().toIso8601String()})
          .eq('branch_id', _branchId);
      // Supplier transactions
      await _db.from('supplier_transactions').delete().eq('branch_id', _branchId);
      // Tables status reset
      await _db.from('tables')
          .update({'status': 'available'})
          .eq('branch_id', _branchId);
      if (mounted) _snack('Full factory reset complete ✓');
    } catch (e) {
      if (mounted) _snack('Reset failed: $e', error: true);
    }
  }

  // ── Confirm dialog ────────────────────────────────────────────────────────
  void _confirmReset({
    required String title,
    required String msg,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: title,
        message: msg,
        onConfirm: () async {
          Navigator.pop(context);
          await onConfirm();
        },
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.success,
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Data & Reset',
          subtitle: 'Export data or reset it selectively',
        ),

        // ── EXPORT ───────────────────────────────────────────────────────
        SectionCard(title: 'EXPORT DATA', children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 4,
            children: [
              _ExportTile(
                icon: AppIcons.tableChartOutlined,
                label: 'Orders history',
                sub: 'CSV',
                loading: _exporting && _exportingKey == 'orders',
                onTap: _exportOrders,
              ),
              _ExportTile(
                icon: AppIcons.barChartOutlined,
                label: 'Financial reports',
                sub: 'CSV',
                loading: _exporting && _exportingKey == 'financial',
                onTap: _exportFinancial,
              ),
              _ExportTile(
                icon: AppIcons.peopleOutline,
                label: 'Customer list',
                sub: 'CSV',
                loading: _exporting && _exportingKey == 'customers',
                onTap: _exportCustomers,
              ),
              _ExportTile(
                icon: AppIcons.inventory2Outlined,
                label: 'Inventory data',
                sub: 'CSV',
                loading: _exporting && _exportingKey == 'inventory',
                onTap: _exportInventory,
              ),
            ],
          ),
        ]),

        // ── SELECTIVE RESET ───────────────────────────────────────────────
        SectionCard(title: 'SELECTIVE RESET', children: [
          _ResetCard(
            icon: AppIcons.historyOutlined,
            title: 'Reset orders & sales data',
            desc: 'Old orders, invoices and payment records will be deleted. Menu, categories and customers stay safe.',
            btnLabel: 'Reset orders',
            onTap: () => _confirmReset(
              title: 'Reset orders data?',
              msg: 'This cannot be undone. Only orders and sales records will be deleted.',
              onConfirm: _resetOrders,
            ),
          ),
          const SizedBox(height: 10),
          _ResetCard(
            icon: AppIcons.personOffOutlined,
            title: 'Reset customer data',
            desc: 'Customer accounts, order history and credit (ledger) records will be deleted.',
            btnLabel: 'Reset customers',
            onTap: () => _confirmReset(
              title: 'Reset customer data?',
              msg: 'This cannot be undone. Customers and their ledgers will be deleted.',
              onConfirm: _resetCustomers,
            ),
          ),
          const SizedBox(height: 10),
          _ResetCard(
            icon: AppIcons.deleteForeverOutlined,
            title: 'Full factory reset',
            desc: 'Everything will be deleted — orders, customers, cash transactions, supplier data. Only the menu, categories and company settings are kept.',
            btnLabel: 'Reset everything',
            severe: true,
            onTap: () => _confirmReset(
              title: 'Full factory reset?',
              msg: 'This is final. All data except the menu and company settings will be permanently deleted.',
              onConfirm: _fullReset,
            ),
          ),
        ]),
      ],
    );
  }
}

// ── Confirm Dialog ────────────────────────────────────────────────────────────
class _ConfirmDialog extends StatefulWidget {
  final String title, message;
  final VoidCallback onConfirm;
  const _ConfirmDialog({required this.title, required this.message, required this.onConfirm});

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    title: Row(children: [
      const SvgIcon(AppIcons.warningAmberRounded, color: AppColors.danger, size: 20),
      const SizedBox(width: 8),
      Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    ]),
    content: Text(widget.message,
        style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
    actions: [
      TextButton(
        onPressed: _loading ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.danger,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _loading
            ? null
            : () async {
          setState(() => _loading = true);
          widget.onConfirm();
        },
        child: _loading
            ? const SizedBox(
          width: 14, height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : const Text('Confirm Reset'),
      ),
    ],
  );
}

// ── Export Tile ───────────────────────────────────────────────────────────────
class _ExportTile extends StatelessWidget {
  final AppIcon icon;
  final String label, sub;
  final bool loading;
  final VoidCallback onTap;

  const _ExportTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: loading ? null : onTap,
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      alignment: Alignment.centerLeft,
    ),
    child: Row(children: [
      loading
          ? const SizedBox(
        width: 18, height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
      )
          : SvgIcon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w600)),
            Text(loading ? 'Exporting...' : sub,
                style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
          ],
        ),
      ),
      if (!loading)
        const SvgIcon(AppIcons.downloadOutlined, size: 16, color: AppColors.textGrey),
    ]),
  );
}

// ── Reset Card ────────────────────────────────────────────────────────────────
class _ResetCard extends StatelessWidget {
  final AppIcon icon;
  final String title, desc, btnLabel;
  final VoidCallback onTap;
  final bool severe;

  const _ResetCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.btnLabel,
    required this.onTap,
    this.severe = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.dangerLight,
      border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgIcon(icon, size: 20, color: AppColors.danger),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.danger)),
              const SizedBox(height: 3),
              Text(desc,
                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(color: AppColors.danger.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(btnLabel,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}