import 'package:resturent_application/core/widget/page_skeleton.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/provider/branch_auth_provider.dart';
import '../../data/model/cash_model.dart';
import '../provider/cash_provider.dart';
import 'package:resturent_application/core/constants/currency.dart';

class CashScreen extends ConsumerStatefulWidget {
  const CashScreen({super.key});

  @override
  ConsumerState<CashScreen> createState() => _CashScreenState();
}

class _CashScreenState extends ConsumerState<CashScreen> {
  String _filter     = 'all';
  String _typeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(branchAuthProvider).branch?.branchId ?? '';
    final st = ref.watch(cashProvider(branchId));

    ref.listen(cashProvider(branchId), (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: kRed),
        );
        ref.read(cashProvider(branchId).notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: kBg,
      body: st.loading
          ? const PageSkeleton(statCount: 4, rows: 8, columns: 5)
          : Column(children: [
        _header(st, branchId),
        _statsRow(st),
        _filterBar(st),
        const SizedBox(height: 1),
        Expanded(child: _txTable(st)),
      ]),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _header(CashState st, String branchId) => Container(
    padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
    decoration: const BoxDecoration(
        color: kCard, border: Border(bottom: BorderSide(color: kBorder))),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFB91C1C), Color(0xFFDC2626)]),
            borderRadius: BorderRadius.circular(10)),
        child: const SvgIcon(AppIcons.accountBalanceWalletRounded,
            color: Colors.white, size: 20),
      ),
      const SizedBox(width: 12),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Cash Register',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: kText)),
        Text('Cash in hand and transactions',
            style: TextStyle(fontSize: 12, color: kMuted)),
      ]),
      const Spacer(),

      // Balance chip
      Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
            color: st.balance >= 0
                ? kGreen.withOpacity(0.1)
                : kRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: (st.balance >= 0 ? kGreen : kRed)
                    .withOpacity(0.3))),
        child: Row(children: [
          SvgIcon(AppIcons.paymentsRounded,
              size: 16, color: st.balance >= 0 ? kGreen : kRed),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Cash in Hand',
                style: TextStyle(fontSize: 10, color: kMuted)),
            Text(formatMoney(st.balance),
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: st.balance >= 0 ? kGreen : kRed)),
          ]),
        ]),
      ),
      const SizedBox(width: 12),

      _hdrBtn('Set Opening Balance', AppIcons.tuneRounded, kBlue,
              () => _showOpeningDialog(st.balance, branchId)),
      const SizedBox(width: 8),
      _hdrBtn('Cash In', AppIcons.addRounded, kGreen,
              () => _showManualDialog(isIn: true, branchId: branchId)),
      const SizedBox(width: 8),
      _hdrBtn('Cash Out / Expense', AppIcons.removeRounded, kRed,
              () => _showManualDialog(isIn: false, branchId: branchId)),
      const SizedBox(width: 8),
      IconButton(
        onPressed: () =>
            ref.read(cashProvider(branchId).notifier).load(),
        icon: const SvgIcon(AppIcons.refreshRounded, color: kSub, size: 18),
        tooltip: 'Refresh',
      ),
    ]),
  );

  Widget _hdrBtn(
      String label, AppIcon icon, Color color, VoidCallback onTap) =>
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.1),
            foregroundColor: color,
            elevation: 0,
            side: BorderSide(color: color.withOpacity(0.3)),
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8))),
        onPressed: onTap,
        icon: SvgIcon(icon, size: 15),
        label: Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700)),
      );

  // ── Stats Row ─────────────────────────────────────────────────────────────

  Widget _statsRow(CashState st) {
    final txs      = st.txs;
    final totalIn  = txs.where((t) => t.direction == 'in') .fold(0.0, (s, t) => s + t.amount);
    final totalOut = txs.where((t) => t.direction == 'out').fold(0.0, (s, t) => s + t.amount);
    final sales    = txs.where((t) => t.type == CashTxType.saleIn)         .fold(0.0, (s, t) => s + t.amount);
    final expenses = txs.where((t) => t.type == CashTxType.expense)        .fold(0.0, (s, t) => s + t.amount);
    final supPay   = txs.where((t) => t.type == CashTxType.supplierPayment).fold(0.0, (s, t) => s + t.amount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: kCard,
      child: Row(children: [
        _statCard('Total Cash In',     formatMoney(totalIn),  AppIcons.arrowDownwardRounded,  kGreen),
        const SizedBox(width: 10),
        _statCard('Total Cash Out',    formatMoney(totalOut), AppIcons.arrowUpwardRounded,    kRed),
        const SizedBox(width: 10),
        _statCard('Sale Revenue',      formatMoney(sales),    AppIcons.pointOfSaleRounded,   kBlue),
        const SizedBox(width: 10),
        _statCard('Supplier Payments', formatMoney(supPay),   AppIcons.localShippingRounded,  kPrimary),
        const SizedBox(width: 10),
        _statCard('Expenses',          formatMoney(expenses), AppIcons.receiptLongRounded,    kPurple),
        const SizedBox(width: 10),
        _statCard('Transactions',      '${txs.length}',        AppIcons.swapHorizRounded,      kSub),
      ]),
    );
  }

  Widget _statCard(String label, String value, AppIcon icon, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.15))),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(7)),
              child: SvgIcon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 10, color: kMuted)),
              Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ]),
          ]),
        ),
      );

  // ── Filter Bar ────────────────────────────────────────────────────────────

  Widget _filterBar(CashState st) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
    decoration: const BoxDecoration(
        color: kCard,
        border: Border(bottom: BorderSide(color: kBorder))),
    child: Row(children: [
      const Text('Direction:',
          style: TextStyle(
              fontSize: 12,
              color: kMuted,
              fontWeight: FontWeight.w600)),
      const SizedBox(width: 8),
      ...[
        ('all', 'All'),
        ('in', 'Cash In'),
        ('out', 'Cash Out'),
      ].map((e) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: _chip(
            e.$2,
            _filter == e.$1,
            _filter == e.$1 ? kPrimary : kMuted,
                () => setState(() => _filter = e.$1)),
      )),
      const SizedBox(width: 20),
      const Text('Type:',
          style: TextStyle(
              fontSize: 12,
              color: kMuted,
              fontWeight: FontWeight.w600)),
      const SizedBox(width: 8),
      ...[
        ('all',                       'All'),
        (CashTxType.saleIn,           'Sale'),
        (CashTxType.supplierPayment,  'Supplier'),
        (CashTxType.expense,          'Expense'),
        (CashTxType.manualIn,         'Manual In'),
        (CashTxType.manualOut,        'Manual Out'),
      ].map((e) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: _chip(
            e.$2,
            _typeFilter == e.$1,
            _typeFilter == e.$1 ? kBlue : kMuted,
                () => setState(() => _typeFilter = e.$1)),
      )),
      const Spacer(),
      Text('${_filtered(st).length} records',
          style: const TextStyle(fontSize: 12, color: kMuted)),
    ]),
  );

  Widget _chip(
      String label, bool active, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
              color: active ? color.withOpacity(0.1) : kLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color:
                  active ? color.withOpacity(0.4) : kBorder)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: active ? color : kMuted,
                  fontWeight:
                  active ? FontWeight.w700 : FontWeight.w400)),
        ),
      );

  List<CashTx> _filtered(CashState st) {
    var list = st.txs;
    if (_filter     != 'all') list = list.where((t) => t.direction == _filter).toList();
    if (_typeFilter != 'all') list = list.where((t) => t.type      == _typeFilter).toList();
    return list;
  }

  // ── Transaction Table ─────────────────────────────────────────────────────

  Widget _txTable(CashState st) {
    final list = _filtered(st);
    if (list.isEmpty) {
      return const Center(
        child: Text('No transactions found',
            style: TextStyle(color: kMuted, fontSize: 14)),
      );
    }

    return Column(children: [
      Container(
        color: kLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: const Row(children: [
          _Hdr('#',           flex: 1),
          _Hdr('Type',        flex: 1),
          SizedBox(width: 20,),
          _Hdr('Description', flex: 4),
          _Hdr('Direction',   flex: 2),
          _Hdr('Amount',      flex: 2),
          _Hdr('Running Bal', flex: 2),
          _Hdr('Date / Time', flex: 2),
        ]),
      ),
      const Divider(height: 1, color: kBorder),
      Expanded(
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: list.length,
          separatorBuilder: (_, __) =>
          const Divider(height: 1, color: kBorder),
          itemBuilder: (_, i) {
            final tx    = list[i];
            final isIn  = tx.direction == 'in';
            final color = isIn ? kGreen : kRed;

            final runBal = st.balance + list.sublist(0, i).fold(0.0, (s, t) =>
            t.direction == 'in' ? s - t.amount : s + t.amount);

            return Container(
              color: isIn
                  ? kGreen.withOpacity(0.015)
                  : kRed.withOpacity(0.015),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 11),
              child: Row(children: [
                Expanded(
                  flex: 1,
                  child: Text('${i + 1}',
                      style:
                      const TextStyle(fontSize: 12, color: kMuted)),
                ),
                Expanded(flex: 1, child: _typeBadge(tx.type)),
                SizedBox(width: 20,),
                Expanded(
                  flex: 4,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tx.refLabel != null)
                          Text(tx.refLabel!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: kText,
                              ),
                              overflow: TextOverflow.ellipsis),
                        if (tx.note != null && tx.note!.isNotEmpty)
                          Text(tx.note!,
                              style: const TextStyle(fontSize: 11, color: kMuted),
                              overflow: TextOverflow.ellipsis),
                        if (tx.refLabel == null &&
                            (tx.note == null || tx.note!.isEmpty))
                          Text(CashTxType.label(tx.type),
                              style: const TextStyle(
                                  fontSize: 13, color: kSub)),
                      ]),
                ),
                Expanded(
                  flex: 2,
                  child: Row(children: [
                    SvgIcon(
                        isIn ? AppIcons.arrowDownwardRounded : AppIcons.arrowUpwardRounded,
                        size: 13,
                        color: color),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5)),
                      child: Text(isIn ? 'Cash In' : 'Cash Out',
                          style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                      '${isIn ? "+" : "−"} ${formatMoney(tx.amount)}',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: color)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(formatMoney(runBal),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kSub)),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_date(tx.createdAt),
                            style: const TextStyle(
                                fontSize: 11, color: kMuted)),
                        Text(_time(tx.createdAt),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kSub)),
                      ]),
                ),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  Widget _typeBadge(String type) {
    final Color color;
    final AppIcon icon;
    switch (type) {
      case CashTxType.saleIn:
        color = kGreen; icon = AppIcons.pointOfSaleRounded;
        break;
      case CashTxType.supplierPayment:
        color = kPrimary; icon = AppIcons.localShippingRounded;
        break;
      case CashTxType.expense:
        color = kPurple; icon = AppIcons.receiptLongRounded;
        break;
      case CashTxType.manualIn:
        color = kBlue; icon = AppIcons.addCircleRounded;
        break;
      case CashTxType.manualOut:
        color = kRed; icon = AppIcons.removeCircleRounded;
        break;
      default:
        color = kMuted; icon = AppIcons.swapHorizRounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgIcon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(CashTxType.label(type),
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showOpeningDialog(double current, String branchId) {
    final ctrl =
    TextEditingController(text: amountInputText(current));
    showDialog(
      context: context,
      builder: (_) => _BaseDialog(
        title: 'Set Opening Balance',
        icon: AppIcons.tuneRounded,
        color: kBlue,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: kBlue.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border:
                Border.all(color: kBlue.withOpacity(0.2))),
            child: const Row(children: [
              SvgIcon(AppIcons.infoOutlineRounded,
                  size: 15, color: kBlue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This will override the current balance. The difference will be automatically saved in the transaction log.',
                  style: TextStyle(fontSize: 11, color: kSub),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          _field('New Balance (£)', ctrl, 'e.g. 50000'),
        ]),
        actionLabel: 'Set Balance',
        actionColor: kBlue,
        onAction: () {
          final val = double.tryParse(ctrl.text);
          if (val != null) {
            ref
                .read(cashProvider(branchId).notifier)
                .setOpeningBalance(val);
          }
        },
      ),
    );
  }

  // FIX: named parameter 'branchId' (was '_branchId' — leading underscore
  //      is only valid for positional params, not named ones)
  void _showManualDialog({required bool isIn, required String branchId}) {
    final amtCtrl  = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => _BaseDialog(
        title: isIn ? 'Add Cash In' : 'Cash Out / Expense',
        icon: isIn ? AppIcons.addRounded : AppIcons.removeRounded,
        color: isIn ? kGreen : kRed,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _field('Amount (£) *', amtCtrl, 'e.g. 5000',
              kt: TextInputType.number),
          const SizedBox(height: 12),
          _field(
              'Note / Reason *',
              noteCtrl,
              isIn ? 'e.g. Owner deposit' : 'e.g. Electricity bill, Rent'),
        ]),
        actionLabel: isIn ? 'Cash In' : 'Cash Out',
        actionColor: isIn ? kGreen : kRed,
        onAction: () {
          final amt  = double.tryParse(amtCtrl.text);
          final note = noteCtrl.text.trim();
          if (amt == null || amt <= 0 || note.isEmpty) return;
          if (isIn) {
            ref.read(cashProvider(branchId).notifier).manualIn(amt, note);
          } else {
            ref.read(cashProvider(branchId).notifier).manualOut(amt, note);
          }
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _date(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  String _time(DateTime dt) {
    final h   = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    return '$h:$min ${dt.hour >= 12 ? "PM" : "AM"}';
  }

  Widget _field(String label, TextEditingController ctrl, String hint,
      {TextInputType? kt}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: kSub)),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          keyboardType: kt,
          style: const TextStyle(fontSize: 13, color: kText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
            const TextStyle(color: Color(0xFFBBBDCC)),
            filled: true,
            fillColor: kLight,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 11),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide:
                const BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide:
                const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(
                    color: kPrimary, width: 1.5)),
          ),
        ),
      ]);
}

// ─── Header cell ─────────────────────────────────────────────────────────────

class _Hdr extends StatelessWidget {
  final String t;
  final int flex;
  const _Hdr(this.t, {this.flex = 1});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(t,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: kMuted,
            letterSpacing: 0.3)),
  );
}

// ─── Base Dialog ─────────────────────────────────────────────────────────────

class _BaseDialog extends StatelessWidget {
  final String title;
  final AppIcon icon;
  final Color color;
  final Widget content;
  final String actionLabel;
  final Color actionColor;
  final VoidCallback onAction;

  const _BaseDialog({
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
    required this.actionLabel,
    required this.actionColor,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: kCard,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20)),
    title: Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: SvgIcon(icon, size: 17, color: color),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: kText)),
    ]),
    content: SizedBox(width: 380, child: content),
    actions: [
      TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: kMuted))),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: actionColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8))),
        onPressed: () {
          onAction();
          Navigator.pop(context);
        },
        child: Text(actionLabel,
            style: const TextStyle(
                fontWeight: FontWeight.w700)),
      ),
    ],
  );
}