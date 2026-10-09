import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/model/inventory_model.dart';
import 'inventory_micro_widgets.dart';
import 'package:resturent_application/core/constants/currency.dart';

// ─── Balance Card ─────────────────────────────────────────────────────────────

class BalCardWidget extends StatelessWidget {
  final String label, value;
  final Color color;
  const BalCardWidget(this.label, this.value, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2))),
    child: Column(children: [
      Text(label, style: const TextStyle(fontSize: 9, color: kMuted)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

// ─── Supplier Table ───────────────────────────────────────────────────────────

class SupplierTableWidget extends StatelessWidget {
  final List<Supplier> suppliers;
  final void Function(int) onDetail;
  final void Function(Supplier) onAddTx;
  const SupplierTableWidget({super.key, required this.suppliers, required this.onDetail, required this.onAddTx});

  @override
  Widget build(BuildContext context) {
    if (suppliers.isEmpty) return const Center(child: Text('No suppliers', style: TextStyle(color: kMuted)));
    return Column(children: [
      Container(
        color: kLight,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: const Row(children: [
          HdrWidget('Supplier', flex: 3),
          HdrWidget('Phone', flex: 2),
          HdrWidget('Total Business', flex: 2),
          HdrWidget('Paid', flex: 2),
          HdrWidget('Balance', flex: 2),
          HdrWidget('Actions', flex: 2),
        ]),
      ),
      const Divider(height: 1, color: kBorder),
      Expanded(
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: suppliers.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: kBorder),
          itemBuilder: (_, i) {
            final s = suppliers[i];
            final due = s.balance > 0;
            return Container(
              color: due ? kRed.withOpacity(0.02) : null,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(children: [
                Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText),
                      overflow: TextOverflow.ellipsis),
                  if (s.address.isNotEmpty)
                    Text(s.address, style: const TextStyle(fontSize: 10, color: kMuted), overflow: TextOverflow.ellipsis),
                ])),
                Expanded(flex: 2, child: Text(s.phone, style: const TextStyle(fontSize: 12, color: kSub))),
                Expanded(flex: 2, child: Text(formatMoney(s.totalBiz),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText))),
                Expanded(flex: 2, child: Text(formatMoney(s.totalPaid),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kGreen))),
                Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: (due ? kRed : kGreen).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(formatMoney(s.balance),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: due ? kRed : kGreen)),
                ))),
                Expanded(flex: 2, child: Row(children: [
                  IBtnWidget(AppIcons.historyRounded, kBlue, () => onDetail(s.id)),
                  const SizedBox(width: 4),
                  IBtnWidget(AppIcons.addRounded, kGreen, () => onAddTx(s)),
                ])),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}

// ─── Supplier Ledger ──────────────────────────────────────────────────────────

class SupplierLedgerWidget extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onBack;
  final void Function(Supplier) onAddTx;
  const SupplierLedgerWidget({super.key, required this.supplier, required this.onBack, required this.onAddTx});

  String _fmt(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final due = supplier.balance > 0;
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: const BoxDecoration(color: kCard, border: Border(bottom: BorderSide(color: kBorder))),
        child: Row(children: [
          GestureDetector(onTap: onBack, child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: kLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
            child: const SvgIcon(AppIcons.arrowBackRounded, size: 16, color: kSub),
          )),
          const SizedBox(width: 12),
          Text(supplier.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
          const SizedBox(width: 16),
          BalCardWidget('Total Business', formatMoney(supplier.totalBiz), kText),
          const SizedBox(width: 8),
          BalCardWidget('Paid', formatMoney(supplier.totalPaid), kGreen),
          const SizedBox(width: 8),
          BalCardWidget(due ? 'Balance' : 'Clear', formatMoney(supplier.balance), due ? kRed : kGreen),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => onAddTx(supplier),
            icon: const SvgIcon(AppIcons.addRounded, size: 16),
            label: const Text('Add Entry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
      Container(
        color: kLight,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        child: const Row(children: [
          SizedBox(width: 36),
          Expanded(flex: 4, child: HdrWidget('Description')),
          Expanded(flex: 2, child: HdrWidget('Date')),
          Expanded(flex: 2, child: HdrWidget('Type')),
          Expanded(flex: 2, child: HdrWidget('Amount')),
          Expanded(flex: 2, child: HdrWidget('Balance')),
        ]),
      ),
      const Divider(height: 1, color: kBorder),
      Expanded(
        child: supplier.txs.isEmpty
            ? const Center(child: Text('No transactions', style: TextStyle(color: kMuted)))
            : Builder(builder: (_) {
          double bal = supplier.totalBiz;
          final rows = supplier.txs.map((tx) { if (tx.isPay) bal -= tx.amount; else bal += tx.amount; return MapEntry(tx, bal); }).toList();
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: kBorder),
            itemBuilder: (_, i) {
              final tx = rows[i].key;
              final rb = rows[i].value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                child: Row(children: [
                  Container(width: 28, height: 28,
                      decoration: BoxDecoration(color: (tx.isPay ? kGreen : kRed).withOpacity(0.1), borderRadius: BorderRadius.circular(7)),
                      child: SvgIcon(tx.isPay ? AppIcons.arrowUpwardRounded : AppIcons.arrowDownwardRounded,
                          size: 13, color: tx.isPay ? kGreen : kRed)),
                  const SizedBox(width: 8),
                  Expanded(flex: 4, child: Text(tx.desc, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kText))),
                  Expanded(flex: 2, child: Text(_fmt(tx.date), style: const TextStyle(fontSize: 12, color: kMuted))),
                  Expanded(flex: 2, child: Text(tx.isPay ? 'Payment' : 'Purchase',
                      style: TextStyle(fontSize: 12, color: tx.isPay ? kGreen : kRed, fontWeight: FontWeight.w600))),
                  Expanded(flex: 2, child: Text('${tx.isPay ? "+" : "-"} ${formatMoney(tx.amount)}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tx.isPay ? kGreen : kRed))),
                  Expanded(flex: 2, child: Text(formatMoney(rb),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kSub))),
                ]),
              );
            },
          );
        }),
      ),
    ]);
  }
}