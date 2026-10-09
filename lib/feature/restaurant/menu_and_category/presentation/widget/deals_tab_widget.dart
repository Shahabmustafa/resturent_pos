import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../data/model/menu_model.dart';
import 'package:resturent_application/core/constants/currency.dart';

class DealsTabWidget extends StatelessWidget {
  final List<Deal> deals;
  final List<MenuItem> menuItems;
  final ValueChanged<Deal> onEdit, onDelete, onToggle;
  const DealsTabWidget({super.key, required this.deals, required this.menuItems,
    required this.onEdit, required this.onDelete, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    if (deals.isEmpty) return const _Empty(label: 'No deals yet', sub: 'Create your first deal package');
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: deals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => DealCardWidget(
        deal: deals[i], menuItems: menuItems,
        onEdit: onEdit, onDelete: onDelete, onToggle: onToggle,
      ),
    );
  }
}

class DealCardWidget extends StatelessWidget {
  final Deal deal;
  final List<MenuItem> menuItems;
  final ValueChanged<Deal> onEdit, onDelete, onToggle;
  const DealCardWidget({super.key, required this.deal, required this.menuItems,
    required this.onEdit, required this.onDelete, required this.onToggle});

  MenuItem _find(String id) => menuItems.firstWhere((m) => m.id == id,
      orElse: () => MenuItem(id: '', branchId: '', name: '?', price: 0, costPrice: 0));

  double get _orig => deal.itemIds.fold(0.0, (s, id) => s + _find(id).effectivePrice);
  double get _savings => _orig - deal.effectivePrice;

  @override
  Widget build(BuildContext context) {
    final items = deal.itemIds.map(_find).where((m) => m.id.isNotEmpty).toList();

    return Container(
      decoration: BoxDecoration(
        color: kCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: deal.isAvailable ? kPrimary.withValues(alpha: 0.3) : kBorder),
        boxShadow: [BoxShadow(color: kPrimary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
          decoration: BoxDecoration(
            color: kPrimary.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            border: const Border(bottom: BorderSide(color: kBorder)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: const SvgIcon(AppIcons.localOfferRounded, color: kPrimary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(deal.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                  color: deal.isAvailable ? kText : kMuted)),
              Text(deal.description, style: const TextStyle(fontSize: 12, color: kSub)),
            ])),
            if (_savings > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
                ),
                child: Text('Save ${formatMoney(_savings)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kPrimary)),
              ),
            GestureDetector(
              onTap: () => onToggle(deal),
              child: Container(
                width: 38, height: 22,
                decoration: BoxDecoration(
                  color: deal.isAvailable ? kGreen : Colors.redAccent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: deal.isAvailable ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(width: 16, height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const SvgIcon(AppIcons.moreVertRounded, size: 18, color: kMuted),
              color: kCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [SvgIcon(AppIcons.editRounded, size: 16, color: kPrimary), SizedBox(width: 8), Text('Edit')])),
                const PopupMenuItem(value: 'del', child: Row(children: [SvgIcon(AppIcons.deleteOutlineRounded, size: 16, color: Colors.redAccent), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.redAccent))])),
              ],
              onSelected: (v) => v == 'edit' ? onEdit(deal) : onDelete(deal),
            ),
          ]),
        ),
        // Body
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Items chips
            Wrap(
              spacing: 8, runSpacing: 8,
              children: items.map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: kLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const SvgIcon(AppIcons.fastfoodRounded, size: 12, color: kMuted),
                  const SizedBox(width: 5),
                  Text(item.name, style: const TextStyle(fontSize: 12, color: kSub, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 5),
                  Text(
                      item.hasSizes ? '${formatMoney(item.effectivePrice)}+' : formatMoney(item.price),
                      style: const TextStyle(fontSize: 11, color: kMuted)),
                ]),
              )).toList(),
            ),

            // Deal sizes (if any)
            if (deal.hasSizes) ...[
              const SizedBox(height: 10),
              const Text('Deal Sizes:', style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: deal.sizes.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kPrimary.withValues(alpha: 0.25)),
                  ),
                  child: Text('${s.name}  ${formatMoney(s.price)}',
                      style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w600)),
                )).toList(),
              ),
            ],

            const SizedBox(height: 12),
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Original: ${formatMoney(_orig)}',
                    style: const TextStyle(fontSize: 12, color: kMuted, decoration: TextDecoration.lineThrough)),
                Row(children: [
                  const Text('Deal Price: ', style: TextStyle(fontSize: 12, color: kSub)),
                  Text(
                      deal.hasSizes
                          ? '${formatMoney(deal.effectivePrice)}+'
                          : formatMoney(deal.dealPrice),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPrimary)),
                ]),
              ]),
              const Spacer(),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimary,
                  side: BorderSide(color: kPrimary.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => onEdit(deal),
                icon: const SvgIcon(AppIcons.editRounded, size: 14),
                label: const Text('Edit Deal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _Empty extends StatelessWidget {
  final String label, sub;
  const _Empty({required this.label, required this.sub});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: const SvgIcon(AppIcons.menuBookRounded, size: 48, color: kPrimary)),
      const SizedBox(height: 16),
      Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
      const SizedBox(height: 6),
      Text(sub, style: const TextStyle(fontSize: 13, color: kMuted)),
    ]),
  );
}