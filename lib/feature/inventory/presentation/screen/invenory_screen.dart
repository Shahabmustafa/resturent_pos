import 'package:resturent_application/core/widget/app_tab_bar.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../restaurant/cash/presentation/provider/cash_provider.dart';
import '../../data/model/inventory_model.dart';
import '../provider/inventory_provider.dart';
import '../widget/inventory_micro_widgets.dart';
import '../widget/inventory_skeleton.dart';
import '../widget/stock_table_widget.dart';
import '../widget/supplier_widgets.dart';
import '../widget/inventory_dialog_widgets.dart';
import '../../../../feature/restaurant/auth/presentation/provider/branch_auth_provider.dart';
import 'package:resturent_application/core/constants/currency.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});
  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _sf = 'All', _search = '';
  int? _supDetail;

  String get _branchId => ref.read(branchAuthProvider).branch?.branchId ?? '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this)..addListener(() => setState(() {}));
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  List<StockItem> _filtered(List<StockItem> stock) => stock.where((s) {
    if (_sf == 'Low') return s.isLow;
    if (_sf == 'Critical') return s.isCritical;
    return true;
  }).where((s) => _search.isEmpty || s.name.toLowerCase().contains(_search.toLowerCase())).toList();

  String _supName(List<Supplier> sups, int? id) => id == null ? '—'
      : sups.where((s) => s.id == id).firstOrNull?.name ?? '—';

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _stockDialog(List<Supplier> sups, StockItem? item) => showDialog(context: context, builder: (_) =>
      StockDialogWidget(item: item, suppliers: sups, branchId: _branchId, onSave: (s) {
        final n = ref.read(inventoryProvider(_branchId).notifier);
        item == null ? n.addStock(s.copyWith(branchId: _branchId)) : n.updateStock(s);
      }));

  void _deleteStock(StockItem item) => showDialog(context: context, builder: (_) =>
      ConfirmDialogWidget(msg: 'Delete "${item.name}"?',
          onConfirm: () => ref.read(inventoryProvider(_branchId).notifier).deleteStock(item.id)));

  void _restock(StockItem item) => showDialog(context: context, builder: (_) =>
      RestockDialogWidget(item: item, onRestock: (q) => ref.read(inventoryProvider(_branchId).notifier).restock(item.id, q)));

  void _addSupplier() => showDialog(context: context, builder: (_) =>
      SupplierDialogWidget(branchId: _branchId,
          onSave: (s) => ref.read(inventoryProvider(_branchId).notifier).addSupplier(s.copyWith(branchId: _branchId))));

  void _addTx(Supplier sup) {
    final cash = ref.read(cashProvider(_branchId)).balance;
    showDialog(context: context, builder: (_) =>
        TxDialogWidget(supplier: sup, cashBalance: cash,
            onSave: (tx) => ref.read(inventoryProvider(_branchId).notifier).addTx(sup, tx.copyWith(branchId: _branchId))));
  }

  void _openLedger(Supplier sup) {
    setState(() => _supDetail = sup.id);
    ref.read(inventoryProvider(_branchId).notifier).loadTxs(sup);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider(_branchId));
    final stock = state.stock, sups = state.suppliers;
    final lowCnt = stock.where((s) => s.isLow).length;
    final critCnt = stock.where((s) => s.isCritical).length;
    final totalDue = sups.fold<double>(0, (v, s) => v + s.balance);

    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!), backgroundColor: kRed));
        ref.read(inventoryProvider(_branchId).notifier).clearError();
      });
    }

    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        // Header
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(color: kCard, border: Border(bottom: BorderSide(color: kBorder))),
          child: Row(children: [
            const Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Inventory', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kText)),
              Text('Stock & Suppliers', style: TextStyle(fontSize: 11, color: kMuted)),
            ]),
            const Spacer(),
            if (state.loading) ...[
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary)),
              const SizedBox(width: 12),
            ],
            PillWidget(AppIcons.warningAmberRounded, '$lowCnt Low', kYellow),
            const SizedBox(width: 6),
            PillWidget(AppIcons.errorOutlineRounded, '$critCnt Critical', kRed),
            const SizedBox(width: 6),
            PillWidget(AppIcons.accountBalanceWalletRounded, 'Due: ${formatMoneyCompact(totalDue)}', kPrimary),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
              onPressed: state.loading ? null : () => _tab.index == 0 ? _stockDialog(sups, null) : _addSupplier(),
              icon: const SvgIcon(AppIcons.addRounded, size: 16),
              label: Text(_tab.index == 0 ? 'Add Item' : 'Add Supplier',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ]),
        ),
        // Tabs
        Container(
          color: kCard,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: AppTabBar(
            controller: _tab,
            expand: false,
            items: [
              AppTabItem('Stock', icon: AppIcons.inventory2Rounded, count: stock.length),
              AppTabItem('Suppliers', icon: AppIcons.localShippingRounded, count: sups.length),
            ],
          ),
        ),
        // Content
        Expanded(
          child: state.loading && stock.isEmpty
              ? const InventoryStockSkeleton()
              : TabBarView(controller: _tab, children: [
            // Stock tab
            Column(children: [
              Container(
                color: kCard,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(children: [
                  SizedBox(width: 220, child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(fontSize: 13, color: kText),
                    decoration: InputDecoration(
                      hintText: 'Search...', hintStyle: const TextStyle(color: kMuted, fontSize: 12),
                      prefixIcon: const SvgIcon(AppIcons.searchRounded, size: 16, color: kMuted),
                      filled: true, fillColor: kLight, isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimary, width: 1.5)),
                    ),
                  )),
                  const SizedBox(width: 10),
                  ...['All', 'Low', 'Critical'].map((f) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChipWidget(f, _sf == f,
                        f == 'Low' ? kYellow : f == 'Critical' ? kRed : kBlue, () => setState(() => _sf = f)),
                  )),
                ]),
              ),
              Expanded(child: StockTableWidget(
                items: _filtered(stock), supName: (id) => _supName(sups, id),
                onEdit: (s) => _stockDialog(sups, s), onDelete: _deleteStock, onRestock: _restock,
              )),
            ]),
            // Suppliers tab
            _supDetail == null
                ? SupplierTableWidget(suppliers: sups,
                onDetail: (id) => _openLedger(sups.firstWhere((s) => s.id == id)), onAddTx: _addTx)
                : SupplierLedgerWidget(supplier: sups.firstWhere((s) => s.id == _supDetail),
                onBack: () => setState(() => _supDetail = null), onAddTx: _addTx),
          ]),
        ),
      ]),
    );
  }
}