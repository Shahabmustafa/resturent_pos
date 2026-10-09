import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/model/inventory_model.dart';
import 'inventory_micro_widgets.dart';
import 'package:resturent_application/core/constants/currency.dart';

class StockTableWidget extends StatelessWidget {
  final List<StockItem> items;
  final String Function(int?) supName;
  final void Function(StockItem) onEdit, onDelete, onRestock;
  const StockTableWidget({super.key, required this.items, required this.supName,
    required this.onEdit, required this.onDelete, required this.onRestock});

  Color _sc(StockItem s) => s.isCritical ? kRed : s.isLow ? kYellow : kGreen;
  String _sl(StockItem s) => s.isCritical ? 'Critical' : s.isLow ? 'Low' : 'OK';

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('No items found', style: TextStyle(color: kMuted)));
    return Column(children: [
      Container(
        color: kLight,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: const Row(children: [
          HdrWidget('Item', flex: 3),
          HdrWidget('Category', flex: 2),
          HdrWidget('Quantity', flex: 2),
          HdrWidget('Unit Cost', flex: 2),
          HdrWidget('Total Value', flex: 2),
          HdrWidget('Supplier', flex: 2),
          HdrWidget('Status', flex: 2),
          HdrWidget('Updated', flex: 2),
          HdrWidget('Actions', flex: 2),
        ]),
      ),
      const Divider(height: 1, color: kBorder),
      Expanded(
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: kBorder),
          itemBuilder: (_, i) {
            final s = items[i];
            final sc = _sc(s);
            return Container(
              color: s.isCritical ? kRed.withOpacity(0.025) : s.isLow ? kYellow.withOpacity(0.025) : null,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              child: Row(children: [
                Expanded(flex: 3, child: Text(s.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText),
                    overflow: TextOverflow.ellipsis)),
                Expanded(flex: 2, child: Text(s.category, style: const TextStyle(fontSize: 12, color: kSub))),
                Expanded(flex: 2, child: Text('${s.qty.toStringAsFixed(s.qty % 1 == 0 ? 0 : 1)} ${s.unit}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sc))),
                Expanded(flex: 2, child: Text(formatMoney(s.cost), style: const TextStyle(fontSize: 12, color: kSub))),
                Expanded(flex: 2, child: Text(formatMoney(s.totalVal),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText))),
                Expanded(flex: 2, child: Text(supName(s.supplierId),
                    style: const TextStyle(fontSize: 11, color: kMuted), overflow: TextOverflow.ellipsis)),
                Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                  child: Text(_sl(s), style: TextStyle(fontSize: 10, color: sc, fontWeight: FontWeight.w700)),
                ))),
                Expanded(flex: 2, child: Text(_ago(s.updatedAt), style: const TextStyle(fontSize: 11, color: kMuted))),
                Expanded(flex: 2, child: Row(children: [
                  IBtnWidget(AppIcons.addRounded, s.isLow ? kRed : kGreen, () => onRestock(s)),
                  const SizedBox(width: 4),
                  IBtnWidget(AppIcons.editRounded, kBlue, () => onEdit(s)),
                  const SizedBox(width: 4),
                  IBtnWidget(AppIcons.deleteOutlineRounded, kMuted, () => onDelete(s)),
                ])),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}