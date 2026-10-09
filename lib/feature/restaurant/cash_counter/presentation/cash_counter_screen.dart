import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/shimmer.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import '../../../../core/constants/app_colors.dart';
import '../data/cash_counter_models.dart';
import 'cash_counter_provider.dart';
import 'package:resturent_application/core/constants/currency.dart';

String _rs(double v) => '${v < 0 ? '−' : ''}${formatMoney(v.abs())}';
final _time = DateFormat('h:mm a');
final _dateTime = DateFormat('d MMM yyyy, h:mm a');

String _duration(DateTime from, DateTime to) {
  final d = to.difference(from);
  final h = d.inHours, m = d.inMinutes % 60;
  return h > 0 ? '${h}h ${m}m' : '${m}m';
}

/// Cash Counter: open a shift with the drawer float, watch cash / card / online
/// sales live, record cash in / out, then count the drawer and close.
class CashCounterScreen extends ConsumerWidget {
  const CashCounterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(cashCounterProvider);
    final n = ref.read(cashCounterProvider.notifier);

    return Scaffold(
      backgroundColor: kBg,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Header(state: s, onRefresh: n.load),
          const SizedBox(height: 16),
          if (s.error != null) ...[
            _ErrorBanner(message: s.error!, onClose: n.clearError),
            const SizedBox(height: 12),
          ],
          if (s.loading)
            const _CounterSkeleton()
          else if (s.open == null)
            _OpenCounterCard(busy: s.busy, onOpen: n.openCounter)
          else
            _OpenCounterView(state: s),
          if (!s.loading) ...[
            const SizedBox(height: 24),
            _History(history: s.history),
          ],
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final CashCounterState state;
  final VoidCallback onRefresh;

  const _Header({required this.state, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final open = state.open;
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: const SvgIcon(AppIcons.pointOfSaleRounded, size: 22, color: kPrimary),
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Cash Counter', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kText)),
          Text('Shift sales, cash in / out and drawer closing',
              style: TextStyle(fontSize: 12.5, color: kMuted)),
        ]),
      ),
      if (state.loading)
        const Shimmer(child: ShimmerBox(width: 150, height: 28, radius: 20))
      else
        _StatusPill(
          label: open == null ? 'Counter closed' : 'Open since ${_time.format(open.openedAt)}',
          color: open == null ? kMuted : kGreen,
        ),
      const SizedBox(width: 8),
      IconButton(
        tooltip: 'Refresh',
        onPressed: onRefresh,
        icon: const SvgIcon(AppIcons.refreshRounded, size: 20, color: kSub),
      ),
    ]);
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _ErrorBanner({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
    decoration: BoxDecoration(
      color: kRed.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: kRed.withOpacity(0.3)),
    ),
    child: Row(children: [
      const SvgIcon(AppIcons.warningAmberRounded, size: 16, color: kRed),
      const SizedBox(width: 8),
      Expanded(child: Text(message, style: const TextStyle(fontSize: 13, color: kRed))),
      IconButton(onPressed: onClose, icon: const SvgIcon(AppIcons.closeRounded, size: 16, color: kRed)),
    ]),
  );
}

// ── No open counter ───────────────────────────────────────────────────────────
class _OpenCounterCard extends StatefulWidget {
  final bool busy;
  final Future<bool> Function(double) onOpen;

  const _OpenCounterCard({required this.busy, required this.onOpen});

  @override
  State<_OpenCounterCard> createState() => _OpenCounterCardState();
}

class _OpenCounterCardState extends State<_OpenCounterCard> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(28),
        decoration: _cardDecoration,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), shape: BoxShape.circle),
            child: const SvgIcon(AppIcons.lockOpenRounded, size: 34, color: kPrimary),
          ),
          const SizedBox(height: 14),
          const Text('Open the cash counter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kText)),
          const SizedBox(height: 6),
          const Text(
            'Count the cash already in the drawer and enter it below. Sales are tracked from the moment you open.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: kMuted, height: 1.5),
          ),
          const SizedBox(height: 20),
          _MoneyField(controller: _ctrl, label: 'Opening cash in drawer', autofocus: true),
          const SizedBox(height: 16),
          _PrimaryButton(
            label: widget.busy ? 'Opening…' : 'Open Counter',
            icon: AppIcons.lockOpenRounded,
            onPressed: widget.busy ? null : () => widget.onOpen(double.tryParse(_ctrl.text.trim()) ?? 0),
          ),
        ]),
      ),
    );
  }
}

// ── Open counter ──────────────────────────────────────────────────────────────
class _OpenCounterView extends ConsumerWidget {
  final CashCounterState state;

  const _OpenCounterView({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = state.open!;
    final sum = state.summary;
    final n = ref.read(cashCounterProvider.notifier);

    Future<void> entry(bool isIn) async {
      final result = await showDialog<(double, String)>(
        context: context,
        builder: (_) => _EntryDialog(isIn: isIn),
      );
      if (result != null) await n.addEntry(isIn: isIn, amount: result.$1, reason: result.$2);
    }

    Future<void> close() async {
      final result = await showDialog<(double, String)>(
        context: context,
        builder: (_) => _CloseDialog(summary: sum, openingCash: open.openingCash),
      );
      if (result == null) return;
      final report = await n.closeCounter(countedCash: result.$1, notes: result.$2);
      if (report != null && context.mounted) {
        showDialog(context: context, builder: (_) => _ReportDialog(counter: report));
      }
    }

    final stats = [
      _Stat('Total Sales', _rs(sum.totalSales), AppIcons.pointOfSaleRounded, kPrimary,
          sub: '${sum.orderCount} paid orders', highlight: true),
      _Stat('Cash Sales', _rs(sum.cashSales), AppIcons.paymentsRounded, kGreen),
      _Stat('Card Sales', _rs(sum.cardSales), AppIcons.creditCardRounded, kBlue),
      _Stat('Online Sales', _rs(sum.onlineSales), AppIcons.phoneAndroidRounded, kPurple),
      _Stat('Discounts', _rs(sum.discountTotal), AppIcons.localOfferOutlined, kYellow),
      _Stat('Unpaid Orders', _rs(sum.unpaidAmount), AppIcons.pendingActionsRounded, kRed,
          sub: '${sum.unpaidCount} not paid yet'),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Shift info + actions
      Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Wrap(spacing: 24, runSpacing: 8, children: [
              _InfoItem('Opened by', open.openedByName),
              _InfoItem('Opened at', _time.format(open.openedAt)),
              _InfoItem('Running for', _duration(open.openedAt, DateTime.now())),
              _InfoItem('Opening cash', _rs(open.openingCash)),
            ]),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _OutlineButton(
                label: 'Cash In', icon: AppIcons.arrowDownwardRounded, color: kGreen,
                onPressed: state.busy ? null : () => entry(true),
              ),
              _OutlineButton(
                label: 'Cash Out', icon: AppIcons.arrowUpwardRounded, color: kRed,
                onPressed: state.busy ? null : () => entry(false),
              ),
              _PrimaryButton(
                label: 'Close Counter', icon: AppIcons.lockOutlineRounded,
                onPressed: state.busy ? null : close,
              ),
            ]),
          ],
        ),
      ),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (context, c) {
        const gap = 12.0;
        final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 620 ? 2 : 1);
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final st in stats) SizedBox(width: w, child: _StatCard(stat: st))],
        );
      }),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (context, c) {
        final expected = _ExpectedCashCard(openingCash: open.openingCash, summary: sum);
        final entries = _EntriesCard(entries: state.entries);
        if (c.maxWidth < 820) {
          return Column(children: [expected, const SizedBox(height: 16), entries]);
        }
        return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: expected),
            const SizedBox(width: 16),
            Expanded(child: entries),
          ]),
        );
      }),
    ]);
  }
}

class _Stat {
  final String label, value;
  final AppIcon icon;
  final Color color;
  final String? sub;
  final bool highlight;

  const _Stat(this.label, this.value, this.icon, this.color, {this.sub, this.highlight = false});
}

class _StatCard extends StatelessWidget {
  final _Stat stat;

  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final hl = stat.highlight;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hl ? stat.color : kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hl ? stat.color : kBorder),
        boxShadow: hl ? [BoxShadow(color: stat.color.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6))] : null,
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: hl ? Colors.white.withOpacity(0.18) : stat.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SvgIcon(stat.icon, size: 20, color: hl ? Colors.white : stat.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(stat.label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: hl ? Colors.white70 : kMuted)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(stat.value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: hl ? Colors.white : kText)),
            ),
            if (stat.sub != null)
              Text(stat.sub!, style: TextStyle(fontSize: 11, color: hl ? Colors.white70 : kMuted)),
          ]),
        ),
      ]),
    );
  }
}

class _ExpectedCashCard extends StatelessWidget {
  final double openingCash;
  final CounterSummary summary;

  const _ExpectedCashCard({required this.openingCash, required this.summary});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _cardDecoration,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Cash in drawer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kText)),
      const SizedBox(height: 4),
      const Text('What should be in the drawer right now', style: TextStyle(fontSize: 12, color: kMuted)),
      const SizedBox(height: 14),
      _CalcRow('Opening cash', openingCash),
      _CalcRow('+ Cash sales', summary.cashSales, color: kGreen),
      _CalcRow('+ Cash in', summary.cashIn, color: kGreen),
      _CalcRow('− Cash out', -summary.cashOut, color: kRed),
      const Divider(color: kBorder, height: 20),
      Row(children: [
        const Expanded(
          child: Text('Expected cash', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kText)),
        ),
        Text(_rs(summary.expectedCash),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kPrimary)),
      ]),
      const SizedBox(height: 8),
      const Text('Card and online payments are not in the drawer.',
          style: TextStyle(fontSize: 11, color: kMuted)),
    ]),
  );
}

class _CalcRow extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;

  const _CalcRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: kSub))),
      Text(_rs(value), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: color ?? kText)),
    ]),
  );
}

class _EntriesCard extends StatelessWidget {
  final List<CounterEntry> entries;

  const _EntriesCard({required this.entries});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _cardDecoration,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Cash in / out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kText)),
      const SizedBox(height: 4),
      const Text('Money added to or taken from the drawer this shift',
          style: TextStyle(fontSize: 12, color: kMuted)),
      const SizedBox(height: 12),
      if (entries.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: Text('No entries yet', style: TextStyle(fontSize: 13, color: kMuted))),
        )
      else
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (e.isIn ? kGreen : kRed).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgIcon(e.isIn ? AppIcons.arrowDownwardRounded : AppIcons.arrowUpwardRounded,
                    size: 14, color: e.isIn ? kGreen : kRed),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.reason.isEmpty ? (e.isIn ? 'Cash in' : 'Cash out') : e.reason,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText)),
                  Text('${_time.format(e.at)} · ${e.byName}', style: const TextStyle(fontSize: 11, color: kMuted)),
                ]),
              ),
              Text('${e.isIn ? '+' : '−'}${_rs(e.amount)}',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: e.isIn ? kGreen : kRed)),
            ]),
          ),
    ]),
  );
}

class _InfoItem extends StatelessWidget {
  final String label, value;

  const _InfoItem(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(fontSize: 14, color: kText, fontWeight: FontWeight.w800)),
  ]);
}

// ── Loading skeleton ──────────────────────────────────────────────────────────
/// Shimmer placeholder shaped like the open-counter view plus the history table.
/// Card backgrounds stay outside each [Shimmer] so only the placeholders sweep.
class _CounterSkeleton extends StatelessWidget {
  const _CounterSkeleton();

  static Widget _lines(int count, {double first = 140}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < count; i++) ...[
        if (i > 0) const SizedBox(height: 12),
        Row(children: [
          ShimmerBox(width: i == 0 ? first : 110 - (i % 3) * 14, height: 13),
          const Spacer(),
          ShimmerBox(width: 70 - (i % 2) * 12, height: 13),
        ]),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Shift info + actions
      Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration,
        child: Shimmer(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(spacing: 24, runSpacing: 8, children: [
                for (final w in const [70.0, 60.0, 56.0, 80.0])
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const ShimmerBox(width: 52, height: 10),
                    const SizedBox(height: 6),
                    ShimmerBox(width: w, height: 14),
                  ]),
              ]),
              const Wrap(spacing: 8, runSpacing: 8, children: [
                ShimmerBox(width: 96, height: 38, radius: 10),
                ShimmerBox(width: 104, height: 38, radius: 10),
                ShimmerBox(width: 140, height: 38, radius: 10),
              ]),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Six stat cards, same responsive grid as the real view
      LayoutBuilder(builder: (context, c) {
        const gap = 12.0;
        final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 620 ? 2 : 1);
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < 6; i++)
              Container(
                width: w,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorder),
                ),
                child: Shimmer(
                  child: Row(children: [
                    const ShimmerBox(width: 40, height: 40, radius: 10),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const ShimmerBox(width: 72, height: 11),
                      const SizedBox(height: 7),
                      ShimmerBox(width: 110 - (i % 3) * 16, height: 20),
                    ]),
                  ]),
                ),
              ),
          ],
        );
      }),
      const SizedBox(height: 16),

      // Expected cash + cash in/out
      LayoutBuilder(builder: (context, c) {
        Widget card(int rows) => Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration,
          child: Shimmer(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const ShimmerBox(width: 120, height: 15),
              const SizedBox(height: 8),
              const ShimmerBox(width: 210, height: 11),
              const SizedBox(height: 18),
              _lines(rows, first: 90),
            ]),
          ),
        );
        if (c.maxWidth < 820) return Column(children: [card(5), const SizedBox(height: 16), card(3)]);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: card(5)),
          const SizedBox(width: 16),
          Expanded(child: card(3)),
        ]);
      }),
      const SizedBox(height: 24),

      // Closed shifts table
      Container(
        decoration: _cardDecoration,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Shimmer(child: Row(children: [
              ShimmerBox(width: 18, height: 18, radius: 5),
              SizedBox(width: 8),
              ShimmerBox(width: 110, height: 15),
            ])),
          ),
          for (var i = 0; i < 4; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorder))),
              child: Shimmer(
                child: Row(children: [
                  Expanded(
                    flex: 3,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const ShimmerBox(width: 90, height: 13),
                      const SizedBox(height: 5),
                      ShimmerBox(width: 120 - (i % 2) * 20, height: 10),
                    ]),
                  ),
                  const Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: ShimmerBox(width: 70, height: 12))),
                  for (var c = 0; c < 4; c++)
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ShimmerBox(width: c == 3 ? 64 : 76 - ((i + c) % 3) * 10, height: c == 3 ? 22 : 13, radius: c == 3 ? 20 : 6),
                      ),
                    ),
                ]),
              ),
            ),
        ]),
      ),
    ]);
  }
}

// ── History ───────────────────────────────────────────────────────────────────
class _History extends StatelessWidget {
  final List<CashCounter> history;

  const _History({required this.history});

  @override
  Widget build(BuildContext context) => Container(
    decoration: _cardDecoration,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(18, 16, 18, 10),
        child: Row(children: [
          SvgIcon(AppIcons.historyRounded, size: 18, color: kSub),
          SizedBox(width: 8),
          Text('Closed shifts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kText)),
        ]),
      ),
      if (history.isEmpty)
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 6, 18, 22),
          child: Text('No closed shifts yet.', style: TextStyle(fontSize: 13, color: kMuted)),
        )
      else ...[
        Container(
          color: kLight,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: const Row(children: [
            Expanded(flex: 3, child: _Th('SHIFT')),
            Expanded(flex: 2, child: _Th('BY')),
            Expanded(flex: 2, child: _Th('TOTAL SALES', end: true)),
            Expanded(flex: 2, child: _Th('EXPECTED', end: true)),
            Expanded(flex: 2, child: _Th('COUNTED', end: true)),
            Expanded(flex: 2, child: _Th('DIFFERENCE', end: true)),
          ]),
        ),
        for (final c in history)
          InkWell(
            onTap: () => showDialog(context: context, builder: (_) => _ReportDialog(counter: c)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorder))),
              child: Row(children: [
                Expanded(
                  flex: 3,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(DateFormat('d MMM yyyy').format(c.openedAt),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
                    Text(
                      '${_time.format(c.openedAt)} – ${c.closedAt == null ? '' : _time.format(c.closedAt!)}',
                      style: const TextStyle(fontSize: 11, color: kMuted),
                    ),
                  ]),
                ),
                Expanded(
                  flex: 2,
                  child: Text(c.closedByName.isNotEmpty ? c.closedByName : c.openedByName,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: kSub)),
                ),
                Expanded(flex: 2, child: _Td(_rs(c.report?.totalSales ?? 0), bold: true)),
                Expanded(flex: 2, child: _Td(_rs(c.report?.expectedCash ?? 0))),
                Expanded(flex: 2, child: _Td(_rs(c.countedCash ?? 0))),
                Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: _DiffChip(c.difference ?? 0))),
              ]),
            ),
          ),
      ],
    ]),
  );
}

class _Th extends StatelessWidget {
  final String text;
  final bool end;

  const _Th(this.text, {this.end = false});

  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: end ? TextAlign.right : TextAlign.left,
      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: kMuted, letterSpacing: 0.5));
}

class _Td extends StatelessWidget {
  final String text;
  final bool bold;

  const _Td(this.text, {this.bold = false});

  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: TextAlign.right,
      style: TextStyle(fontSize: 13, color: kText, fontWeight: bold ? FontWeight.w800 : FontWeight.w500));
}

/// Short (red), over (amber) or balanced (green).
class _DiffChip extends StatelessWidget {
  final double diff;

  const _DiffChip(this.diff);

  @override
  Widget build(BuildContext context) {
    final (label, color) = diff.abs() < 0.5
        ? ('Balanced', kGreen)
        : diff < 0
            ? ('Short ${_rs(-diff)}', kRed)
            : ('Over ${_rs(diff)}', kYellow);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

// ── Dialogs ───────────────────────────────────────────────────────────────────
class _EntryDialog extends StatefulWidget {
  final bool isIn;

  const _EntryDialog({required this.isIn});

  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  final _amount = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    final color = widget.isIn ? kGreen : kRed;
    return AlertDialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.isIn ? 'Cash In' : 'Cash Out',
          style: const TextStyle(fontWeight: FontWeight.w800, color: kText)),
      content: SizedBox(
        width: 380,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
            widget.isIn
                ? 'Money added to the drawer (e.g. more change).'
                : 'Money taken from the drawer (e.g. an expense or supplier payment).',
            style: const TextStyle(fontSize: 12.5, color: kMuted),
          ),
          const SizedBox(height: 14),
          _MoneyField(controller: _amount, label: 'Amount', autofocus: true, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          _TextInput(controller: _reason, label: 'Reason', hint: widget.isIn ? 'e.g. Change added' : 'e.g. Milk, gas bill'),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: kMuted))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, elevation: 0),
          onPressed: amount <= 0 ? null : () => Navigator.pop(context, (amount, _reason.text.trim())),
          child: Text(widget.isIn ? 'Add Cash In' : 'Add Cash Out'),
        ),
      ],
    );
  }
}

class _CloseDialog extends StatefulWidget {
  final CounterSummary summary;
  final double openingCash;

  const _CloseDialog({required this.summary, required this.openingCash});

  @override
  State<_CloseDialog> createState() => _CloseDialogState();
}

class _CloseDialogState extends State<_CloseDialog> {
  final _counted = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _counted.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expected = widget.summary.expectedCash;
    final counted = double.tryParse(_counted.text.trim());
    return AlertDialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Close Counter', style: TextStyle(fontWeight: FontWeight.w800, color: kText)),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
            child: Column(children: [
              _CalcRow('Total sales', widget.summary.totalSales),
              _CalcRow('Card + online (not in drawer)', widget.summary.cardSales + widget.summary.onlineSales),
              Row(children: [
                const Expanded(
                  child: Text('Expected cash', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kText)),
                ),
                Text(_rs(expected), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPrimary)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          _MoneyField(controller: _counted, label: 'Cash counted in drawer', autofocus: true,
              onChanged: (_) => setState(() {})),
          if (counted != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Text('Difference', style: TextStyle(fontSize: 13, color: kSub)),
              const Spacer(),
              _DiffChip(counted - expected),
            ]),
          ],
          const SizedBox(height: 12),
          _TextInput(controller: _notes, label: 'Notes (optional)', hint: 'e.g. £50.00 given as change on credit'),
          if (widget.summary.unpaidCount > 0) ...[
            const SizedBox(height: 12),
            Row(children: [
              const SvgIcon(AppIcons.warningAmberRounded, size: 15, color: kYellow),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${widget.summary.unpaidCount} order(s) worth ${_rs(widget.summary.unpaidAmount)} are still unpaid.',
                  style: const TextStyle(fontSize: 12, color: kSub),
                ),
              ),
            ]),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: kMuted))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0),
          onPressed: counted == null || counted < 0 ? null : () => Navigator.pop(context, (counted, _notes.text.trim())),
          child: const Text('Close Counter'),
        ),
      ],
    );
  }
}

/// Closing report for one shift.
class _ReportDialog extends StatelessWidget {
  final CashCounter counter;

  const _ReportDialog({required this.counter});

  @override
  Widget build(BuildContext context) {
    final r = counter.report ?? const CounterSummary();
    Widget row(String label, String value, {Color? color, bool bold = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: bold ? kText : kSub, fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
        Text(value, style: TextStyle(fontSize: 13.5, fontWeight: bold ? FontWeight.w900 : FontWeight.w700, color: color ?? kText)),
      ]),
    );

    return AlertDialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        const Expanded(child: Text('Shift Report', style: TextStyle(fontWeight: FontWeight.w800, color: kText))),
        _DiffChip(counter.difference ?? 0),
      ]),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
              '${_dateTime.format(counter.openedAt)} → ${counter.closedAt == null ? '' : _time.format(counter.closedAt!)}'
              '${counter.closedAt == null ? '' : '  (${_duration(counter.openedAt, counter.closedAt!)})'}',
              style: const TextStyle(fontSize: 12, color: kMuted),
            ),
            Text('Opened by ${counter.openedByName} · Closed by ${counter.closedByName}',
                style: const TextStyle(fontSize: 12, color: kMuted)),
            const Divider(color: kBorder, height: 24),
            row('Cash sales', _rs(r.cashSales)),
            row('Card sales', _rs(r.cardSales)),
            row('Online sales', _rs(r.onlineSales)),
            row('Total sales', _rs(r.totalSales), bold: true, color: kPrimary),
            row('Paid orders', '${r.orderCount}'),
            row('Discounts given', _rs(r.discountTotal)),
            const Divider(color: kBorder, height: 20),
            row('Opening cash', _rs(counter.openingCash)),
            row('Cash in', '+${_rs(r.cashIn)}', color: kGreen),
            row('Cash out', '−${_rs(r.cashOut)}', color: kRed),
            row('Expected cash', _rs(r.expectedCash), bold: true),
            row('Counted cash', _rs(counter.countedCash ?? 0), bold: true),
            if (counter.notes.isNotEmpty) ...[
              const Divider(color: kBorder, height: 20),
              Text('Notes: ${counter.notes}', style: const TextStyle(fontSize: 12.5, color: kSub)),
            ],
          ]),
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0),
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

// ── Small building blocks ─────────────────────────────────────────────────────
final _cardDecoration = BoxDecoration(
  color: kCard,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: kBorder),
);

InputDecoration _inputDecoration(String label, {String? hint, Widget? prefix}) => InputDecoration(
  labelText: label,
  hintText: hint,
  labelStyle: const TextStyle(color: kMuted, fontSize: 13),
  hintStyle: const TextStyle(color: kMuted, fontSize: 12.5),
  prefixIcon: prefix,
  filled: true,
  fillColor: kLight,
  isDense: true,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPrimary, width: 1.5)),
);

class _MoneyField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  const _MoneyField({required this.controller, required this.label, this.autofocus = false, this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autofocus: autofocus,
    onChanged: onChanged,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kText),
    decoration: _inputDecoration(label,
        hint: '0',
        prefix: const Padding(
          padding: EdgeInsets.only(left: 14, right: 6, top: 12),
          child: Text('£', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kMuted)),
        )),
  );
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;

  const _TextInput({required this.controller, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    style: const TextStyle(fontSize: 13.5, color: kText),
    decoration: _inputDecoration(label, hint: hint),
  );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final AppIcon icon;
  final VoidCallback? onPressed;

  const _PrimaryButton({required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    onPressed: onPressed,
    icon: SvgIcon(icon, size: 16, color: Colors.white),
    label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
  );
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final AppIcon icon;
  final Color color;
  final VoidCallback? onPressed;

  const _OutlineButton({required this.label, required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withOpacity(0.5)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    onPressed: onPressed,
    icon: SvgIcon(icon, size: 16, color: color),
    label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
  );
}
