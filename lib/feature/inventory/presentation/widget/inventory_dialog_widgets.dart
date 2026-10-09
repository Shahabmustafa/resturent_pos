import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/model/inventory_model.dart';
import 'inventory_micro_widgets.dart';
import 'package:resturent_application/core/constants/currency.dart';

// ─── Stock Dialog ─────────────────────────────────────────────────────────────

class StockDialogWidget extends StatefulWidget {
  final StockItem? item;
  final List<Supplier> suppliers;
  final void Function(StockItem) onSave;
  final String branchId;
  const StockDialogWidget({super.key, required this.item, required this.suppliers, required this.onSave, required this.branchId});

  @override
  State<StockDialogWidget> createState() => _StockDialogWidgetState();
}

class _StockDialogWidgetState extends State<StockDialogWidget> {
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late final _qty  = TextEditingController(text: widget.item?.qty.toStringAsFixed(1) ?? '');
  late final _min  = TextEditingController(text: widget.item?.minQty.toStringAsFixed(1) ?? '');
  late final _cost = TextEditingController(text: widget.item == null ? '' : amountInputText(widget.item!.cost));
  late String _unit = widget.item?.unit ?? 'kg';
  late String _cat  = widget.item?.category ?? 'Meat';
  late int? _supId  = widget.item?.supplierId ?? (widget.suppliers.isNotEmpty ? widget.suppliers.first.id : null);

  @override
  void dispose() { _name.dispose(); _qty.dispose(); _min.dispose(); _cost.dispose(); super.dispose(); }

  double get _total => (double.tryParse(_qty.text) ?? 0) * (double.tryParse(_cost.text) ?? 0);

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: kCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Text(widget.item == null ? 'Add Item' : 'Edit Item',
        style: const TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 16)),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          fieldWidget('Item Name', _name, 'e.g. Chicken Breast'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: fieldWidget('Quantity', _qty, '10', kt: TextInputType.number, onChange: (_) => setState(() {}))),
            const SizedBox(width: 10),
            Expanded(child: fieldWidget('Min Qty', _min, '5', kt: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: fieldWidget('Cost / Unit (£)', _cost, '650', kt: TextInputType.number, onChange: (_) => setState(() {}))),
            const SizedBox(width: 10),
            Expanded(child: dropdownWidget('Unit', _unit, ['kg', 'g', 'L', 'ml', 'pcs', 'pack', 'dz'], (v) => setState(() => _unit = v!))),
          ]),
          const SizedBox(height: 12),
          dropdownWidget('Category', _cat,
              ['Meat', 'Veggies', 'Dairy', 'Bakery', 'Dry Goods', 'Beverages', 'Other'], (v) => setState(() => _cat = v!)),
          if (widget.suppliers.isNotEmpty) ...[
            const SizedBox(height: 12),
            dropdownIntWidget('Supplier', _supId, widget.suppliers, (v) => setState(() => _supId = v)),
            // Auto purchase note
            if (widget.item == null && _supId != null && _total > 0) ...[
              const SizedBox(height: 10),
              _note('${formatMoney(_total)} will be added to this supplier\'s account as a purchase.'),
            ],
          ],
        ]),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: kMuted))),
      _saveBtn('Save', kPrimary, () {
        if (_name.text.trim().isEmpty) return;
        widget.onSave(StockItem(
          id: widget.item?.id ?? 0, branchId: widget.branchId, supplierId: _supId,
          name: _name.text.trim(), category: _cat, unit: _unit,
          qty: double.tryParse(_qty.text) ?? 0, minQty: double.tryParse(_min.text) ?? 0,
          cost: double.tryParse(_cost.text) ?? 0, updatedAt: DateTime.now(),
        ));
        Navigator.pop(context);
      }),
    ],
  );
}

// ─── Restock Dialog ───────────────────────────────────────────────────────────

class RestockDialogWidget extends StatefulWidget {
  final StockItem item;
  final void Function(double) onRestock;
  const RestockDialogWidget({super.key, required this.item, required this.onRestock});

  @override
  State<RestockDialogWidget> createState() => _RestockDialogWidgetState();
}

class _RestockDialogWidgetState extends State<RestockDialogWidget> {
  final _c = TextEditingController();
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final q = double.tryParse(_c.text) ?? 0;
    return AlertDialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Restock: ${widget.item.name}', style: const TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 15)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: kLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _stat('Current', '${widget.item.qty.toStringAsFixed(1)} ${widget.item.unit}', widget.item.isLow ? kRed : kGreen),
            const SvgIcon(AppIcons.arrowForwardRounded, color: kMuted, size: 18),
            _stat('After', '${(widget.item.qty + q).toStringAsFixed(1)} ${widget.item.unit}', kGreen),
          ]),
        ),
        const SizedBox(height: 14),
        fieldWidget('Add Quantity (${widget.item.unit})', _c, '10', kt: TextInputType.number, onChange: (_) => setState(() {})),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: kMuted))),
        _saveBtn('Add Stock', kGreen, () { if (q > 0) { widget.onRestock(q); Navigator.pop(context); } }),
      ],
    );
  }

  Widget _stat(String l, String v, Color c) => Column(children: [
    Text(l, style: const TextStyle(fontSize: 10, color: kMuted)),
    const SizedBox(height: 2),
    Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c)),
  ]);
}

// ─── Supplier Dialog ──────────────────────────────────────────────────────────

class SupplierDialogWidget extends StatefulWidget {
  final void Function(Supplier) onSave;
  final String branchId;
  const SupplierDialogWidget({super.key, required this.onSave, required this.branchId});

  @override
  State<SupplierDialogWidget> createState() => _SupplierDialogWidgetState();
}

class _SupplierDialogWidgetState extends State<SupplierDialogWidget> {
  final _n = TextEditingController();
  final _p = TextEditingController();
  final _a = TextEditingController();
  @override
  void dispose() { _n.dispose(); _p.dispose(); _a.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: kCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: const Text('Add Supplier', style: TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 16)),
    content: SizedBox(
      width: 360,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        fieldWidget('Name', _n, 'e.g. Malik Meat Supplier'),
        const SizedBox(height: 12),
        fieldWidget('Phone', _p, '0300-1234567', kt: TextInputType.phone),
        const SizedBox(height: 12),
        fieldWidget('Address', _a, 'e.g. Raja Bazaar'),
      ]),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: kMuted))),
      _saveBtn('Add', kPrimary, () {
        if (_n.text.trim().isEmpty) return;
        widget.onSave(Supplier(id: 0, branchId: widget.branchId, name: _n.text.trim(),
            phone: _p.text.trim(), address: _a.text.trim(), totalBiz: 0, totalPaid: 0));
        Navigator.pop(context);
      }),
    ],
  );
}

// ─── Transaction Dialog (cash-aware) ──────────────────────────────────────────

class TxDialogWidget extends StatefulWidget {
  final Supplier supplier;
  final double cashBalance;
  final void Function(SupTx) onSave;
  const TxDialogWidget({super.key, required this.supplier, this.cashBalance = 0, required this.onSave});

  @override
  State<TxDialogWidget> createState() => _TxDialogWidgetState();
}

class _TxDialogWidgetState extends State<TxDialogWidget> {
  final _d = TextEditingController();
  final _a = TextEditingController();
  bool _isPay = true;
  @override
  void dispose() { _d.dispose(); _a.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final amt = double.tryParse(_a.text) ?? 0;
    final low = _isPay && amt > widget.cashBalance;
    return AlertDialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('${widget.supplier.name} — New Entry',
          style: const TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 15)),
      content: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child: TogBtnWidget('Payment', AppIcons.arrowUpwardRounded, _isPay, kGreen, () => setState(() => _isPay = true))),
            const SizedBox(width: 8),
            Expanded(child: TogBtnWidget('Purchase', AppIcons.arrowDownwardRounded, !_isPay, kRed, () => setState(() => _isPay = false))),
          ]),
          if (_isPay) ...[
            const SizedBox(height: 12),
            _note(low
                ? 'Insufficient cash. Available: ${formatMoney(widget.cashBalance)}'
                : 'Cash in hand: ${formatMoney(widget.cashBalance)}. This will be deducted.',
                color: low ? kRed : kGreen),
          ],
          const SizedBox(height: 14),
          fieldWidget('Description', _d, _isPay ? 'e.g. Payment for chicken' : 'e.g. Chicken 20kg purchase'),
          const SizedBox(height: 12),
          fieldWidget('Amount (£)', _a, '13000', kt: TextInputType.number, onChange: (_) => setState(() {})),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: kMuted))),
        _saveBtn(_isPay ? 'Add Payment' : 'Add Purchase', low ? kMuted : (_isPay ? kGreen : kRed), low ? null : () {
          if (_d.text.trim().isEmpty || _a.text.isEmpty) return;
          widget.onSave(SupTx(id: 0, branchId: widget.supplier.branchId, supplierId: widget.supplier.id,
              desc: _d.text.trim(), amount: amt, isPay: _isPay, date: DateTime.now()));
          Navigator.pop(context);
        }),
      ],
    );
  }
}

// ─── Confirm Delete ───────────────────────────────────────────────────────────

class ConfirmDialogWidget extends StatelessWidget {
  final String msg;
  final VoidCallback onConfirm;
  const ConfirmDialogWidget({super.key, required this.msg, required this.onConfirm});

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: kCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    title: const Text('Delete?', style: TextStyle(color: kText, fontWeight: FontWeight.w700)),
    content: Text(msg, style: const TextStyle(color: kSub)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: kMuted))),
      _saveBtn('Delete', kRed, () { onConfirm(); Navigator.pop(context); }),
    ],
  );
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

Widget _saveBtn(String label, Color color, VoidCallback? onTap) => ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
  onPressed: onTap,
  child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
);

Widget _note(String text, {Color color = kBlue}) => Container(
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(9),
      border: Border.all(color: color.withOpacity(0.2))),
  child: Row(children: [
    SvgIcon(AppIcons.infoOutlineRounded, size: 14, color: color),
    const SizedBox(width: 8),
    Expanded(child: Text(text, style: TextStyle(fontSize: 11, color: color == kBlue ? kSub : color))),
  ]),
);