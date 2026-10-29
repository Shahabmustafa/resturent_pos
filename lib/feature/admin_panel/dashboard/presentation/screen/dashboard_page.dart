import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/constants/currency.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../restaurant/sales_dashboard/presentation/sales_dashboard_provider.dart'
    show DashboardPeriod, DashboardPeriodX;
import '../../../branches/data/datasource/branches_datasource.dart';
import '../../../branches/data/model/branches_model.dart';
import '../../../widget/shared_widget.dart';
import '../../data/branch_report_datasource.dart';

/// Owner's report: every branch's sales for a period, side by side, with
/// company totals on top. Figures come from each branch's `dashboard_stats`,
/// so they match what the branch sees on its own POS dashboard.
class DashboardPage extends StatefulWidget {
  final String companyId;
  final BranchDatasource datasource;

  /// Reports the loaded branches so the sidebar can show real counts.
  final ValueChanged<List<Branch>> onBranchesLoaded;

  /// Opens the full reports of one branch.
  final ValueChanged<String> onBranchTap;

  const DashboardPage({
    super.key,
    required this.companyId,
    required this.datasource,
    required this.onBranchesLoaded,
    required this.onBranchTap,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final _reports = BranchReportDatasource(Supabase.instance.client);

  DashboardPeriod _period = DashboardPeriod.today;
  List<BranchReport>? _rows;
  String? _error;
  bool _loading = true;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final branches = await widget.datasource.fetchBranches(widget.companyId);
      if (!mounted || request != _request) return;
      widget.onBranchesLoaded(branches);
      final (from, to) = _period.range(DateTime.now());
      final rows = await _reports.fetch(branches, from, to);
      if (!mounted || request != _request) return;
      rows.sort((a, b) => b.revenue.compareTo(a.revenue));
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _setPeriod(DashboardPeriod p) {
    if (p == _period) return;
    _period = p;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final (from, to) = _period.range(DateTime.now());
    final sameDay = to.difference(from).inHours < 24 && from.day == to.day;
    final range = sameDay
        ? DateFormat('EEEE, d MMMM').format(from)
        : '${DateFormat('d MMM').format(from)} – ${DateFormat('d MMM').format(to)}';
    final narrow = MediaQuery.sizeOf(context).width < 700;

    return Column(
      children: [
        AdminTopBar(
          title: 'Branch Reports',
          subtitle: 'All branches · $range',
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _loading ? null : _load,
              icon: const SvgIcon(
                AppIcons.refreshRounded,
                size: 18,
                color: AppColors.grey,
              ),
            ),
          ],
        ),
        if (_loading)
          const LinearProgressIndicator(minHeight: 2, color: AppColors.primary),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(narrow ? 16 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in DashboardPeriod.values)
                        ChoiceChip(
                          label: Text(p.label),
                          selected: p == _period,
                          onSelected: (_) => _setPeriod(p),
                          selectedColor: AppColors.primaryLt,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p == _period
                                ? AppColors.primary
                                : AppColors.dark,
                          ),
                          side: BorderSide(
                            color: p == _period
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                          showCheckmark: false,
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_error != null)
                    _ErrorCard(message: _error!, onRetry: _load)
                  else if (_rows == null)
                    const SizedBox(height: 200)
                  else if (_rows!.isEmpty)
                    const _EmptyCard()
                  else ...[
                    _Totals(rows: _rows!, period: _period),
                    const SizedBox(height: 22),
                    const Text(
                      'Branch performance',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sales are paid orders, counted when they were paid. Tap a branch for its full reports.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _BranchTable(
                      rows: _rows!,
                      period: _period,
                      onBranchTap: widget.onBranchTap,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Company totals ────────────────────────────────────────────────────────────
class _Totals extends StatelessWidget {
  final List<BranchReport> rows;
  final DashboardPeriod period;

  const _Totals({required this.rows, required this.period});

  @override
  Widget build(BuildContext context) {
    double sum(double Function(BranchReport) f) =>
        rows.fold(0.0, (s, r) => s + f(r));
    int count(int Function(BranchReport) f) => rows.fold(0, (s, r) => s + f(r));

    final revenue = sum((r) => r.revenue);
    final prev = sum((r) => r.previousRevenue);
    final orders = count((r) => r.paidOrders);
    final cards = [
      _Kpi(
        label: 'Total sales',
        value: formatMoney(revenue),
        icon: AppIcons.paymentsOutlined,
        color: AppColors.primary,
        delta: _delta(revenue, prev),
        deltaNote: 'vs ${period.previousLabel}',
      ),
      _Kpi(
        label: 'Paid orders',
        value: '$orders',
        icon: AppIcons.receiptLongOutlined,
        color: const Color(0xFF8B5CF6),
      ),
      _Kpi(
        label: 'Average order',
        value: formatMoney(orders == 0 ? 0 : revenue / orders),
        icon: AppIcons.trendingUpRounded,
        color: AppColors.success,
      ),
      _Kpi(
        label: 'Unpaid orders',
        value: formatMoney(sum((r) => r.unpaidAmount)),
        icon: AppIcons.pendingActionsRounded,
        color: AppColors.warning,
      ),
      _Kpi(
        label: 'Pending now',
        value: '${count((r) => r.pendingOrders)}',
        icon: AppIcons.pendingRounded,
        color: AppColors.info,
        deltaNote: '${count((r) => r.activeDeliveries)} deliveries on the way',
      ),
      _Kpi(
        label: 'Counters open',
        value: '${rows.where((r) => r.counterOpen).length}/${rows.length}',
        icon: AppIcons.pointOfSaleOutlined,
        color: AppColors.danger,
        deltaNote: '${formatMoney(sum((r) => r.expectedCash))} expected cash',
      ),
    ];

    final failed = rows.where((r) => r.error != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth >= 1100
                ? 6
                : c.maxWidth >= 640
                ? 3
                : 2;
            const gap = 12.0;
            final w = (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [for (final k in cards) SizedBox(width: w, child: k)],
            );
          },
        ),
        const SizedBox(height: 12),
        _Split(
          title: 'Sales by channel',
          parts: [
            ('Website', sum((r) => r.websiteRevenue), AppColors.info),
            ('POS', sum((r) => r.posRevenue), AppColors.primary),
          ],
        ),
        const SizedBox(height: 12),
        _Split(
          title: 'Sales by payment',
          parts: [
            ('Cash', sum((r) => r.cash), AppColors.success),
            ('Card', sum((r) => r.card), const Color(0xFF8B5CF6)),
            ('Online', sum((r) => r.online), AppColors.warning),
          ],
        ),
        if (failed.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            "Couldn't load: ${failed.map((r) => r.branch.name).join(', ')}. Totals leave these out.",
            style: const TextStyle(fontSize: 11.5, color: AppColors.danger),
          ),
        ],
      ],
    );
  }
}

double? _delta(double cur, double prev) =>
    prev == 0 ? null : (cur - prev) / prev;

class _Kpi extends StatelessWidget {
  final String label, value;
  final AppIcon icon;
  final Color color;
  final double? delta;
  final String? deltaNote;

  const _Kpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.delta,
    this.deltaNote,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: SvgIcon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11.5, color: AppColors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            if (delta != null) ...[
              _DeltaText(delta!),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                deltaNote ?? ' ',
                style: const TextStyle(fontSize: 10.5, color: AppColors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _DeltaText extends StatelessWidget {
  final double delta;
  const _DeltaText(this.delta);

  @override
  Widget build(BuildContext context) {
    final up = delta >= 0;
    return Text(
      '${up ? '▲' : '▼'} ${(delta.abs() * 100).toStringAsFixed(0)}%',
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: up ? AppColors.success : AppColors.danger,
      ),
    );
  }
}

/// A labelled bar split into parts, e.g. website vs POS sales.
class _Split extends StatelessWidget {
  final String title;
  final List<(String, double, Color)> parts;

  const _Split({required this.title, required this.parts});

  @override
  Widget build(BuildContext context) {
    final total = parts.fold(0.0, (s, p) => s + p.$2);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: total == 0
                  ? const ColoredBox(color: AppColors.greyLt)
                  : Row(
                      children: [
                        for (final p in parts)
                          if (p.$2 > 0)
                            Expanded(
                              flex: (p.$2 / total * 1000).round().clamp(
                                1,
                                1000,
                              ),
                              child: ColoredBox(color: p.$3),
                            ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              for (final p in parts)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: p.$3,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${p.$1} ',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.grey,
                      ),
                    ),
                    Text(
                      formatMoney(p.$2),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    if (total > 0)
                      Text(
                        '  ${(p.$2 / total * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.grey,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Per-branch table ──────────────────────────────────────────────────────────
class _BranchTable extends StatelessWidget {
  final List<BranchReport> rows;
  final DashboardPeriod period;
  final ValueChanged<String> onBranchTap;

  const _BranchTable({
    required this.rows,
    required this.period,
    required this.onBranchTap,
  });

  static const _cols = <(String, double)>[
    ('Branch', 220),
    ('Sales', 170),
    ('Orders', 80),
    ('Avg order', 100),
    ('Website / POS', 170),
    ('Unpaid', 100),
    ('Cancelled', 90),
    ('Right now', 190),
  ];

  static double get _minWidth => _cols.fold(0.0, (s, c) => s + c.$2) + 32;

  @override
  Widget build(BuildContext context) {
    final best = rows.fold(0.0, (m, r) => r.revenue > m ? r.revenue : m);
    double sum(double Function(BranchReport) f) =>
        rows.fold(0.0, (s, r) => s + f(r));
    int count(int Function(BranchReport) f) => rows.fold(0, (s, r) => s + f(r));
    final totalOrders = count((r) => r.paidOrders);
    final totalRevenue = sum((r) => r.revenue);

    return AppCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, c) {
          final width = c.maxWidth < _minWidth ? _minWidth : c.maxWidth;
          final scale = (width - 32) / (_minWidth - 32);
          Widget cell(int i, Widget child) =>
              SizedBox(width: _cols[i].$2 * scale, child: child);

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < _cols.length; i++)
                          cell(
                            i,
                            Text(
                              _cols[i].$1.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  for (final r in rows) ...[
                    const Divider(height: 1, color: AppColors.border),
                    InkWell(
                      onTap: () => onBranchTap(r.branch.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: r.error != null
                            ? Row(
                                children: [
                                  cell(0, _BranchName(r.branch)),
                                  Expanded(
                                    child: Text(
                                      "Couldn't load this branch: ${r.error}",
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.danger,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  cell(0, _BranchName(r.branch)),
                                  cell(
                                    1,
                                    _SalesCell(
                                      report: r,
                                      best: best,
                                      period: period,
                                    ),
                                  ),
                                  cell(
                                    2,
                                    _num(
                                      '${r.paidOrders}',
                                      sub: '${r.ordersPlaced} placed',
                                    ),
                                  ),
                                  cell(3, _num(formatMoney(r.avgOrder))),
                                  cell(
                                    4,
                                    _num(
                                      formatMoney(r.websiteRevenue),
                                      sub: 'POS ${formatMoney(r.posRevenue)}',
                                    ),
                                  ),
                                  cell(
                                    5,
                                    _num(
                                      formatMoney(r.unpaidAmount),
                                      color: r.unpaidAmount > 0
                                          ? AppColors.warning
                                          : AppColors.dark,
                                    ),
                                  ),
                                  cell(
                                    6,
                                    _num(
                                      '${r.cancelled}',
                                      color: r.cancelled > 0
                                          ? AppColors.danger
                                          : AppColors.dark,
                                    ),
                                  ),
                                  cell(7, _LiveCell(r)),
                                ],
                              ),
                      ),
                    ),
                  ],
                  const Divider(height: 1, color: AppColors.border),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLt,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        cell(0, _num('All branches')),
                        cell(1, _num(formatMoney(totalRevenue))),
                        cell(2, _num('$totalOrders')),
                        cell(
                          3,
                          _num(
                            formatMoney(
                              totalOrders == 0 ? 0 : totalRevenue / totalOrders,
                            ),
                          ),
                        ),
                        cell(
                          4,
                          _num(
                            formatMoney(sum((r) => r.websiteRevenue)),
                            sub: 'POS ${formatMoney(sum((r) => r.posRevenue))}',
                          ),
                        ),
                        cell(5, _num(formatMoney(sum((r) => r.unpaidAmount)))),
                        cell(6, _num('${count((r) => r.cancelled)}')),
                        cell(
                          7,
                          _num('${count((r) => r.pendingOrders)} pending'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _num(
    String text, {
    String? sub,
    Color color = AppColors.dark,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      if (sub != null)
        Text(
          sub,
          style: const TextStyle(fontSize: 10.5, color: AppColors.grey),
          overflow: TextOverflow.ellipsis,
        ),
    ],
  );
}

class _BranchName extends StatelessWidget {
  final Branch branch;
  const _BranchName(this.branch);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: branch.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: SvgIcon(AppIcons.storeOutlined, color: branch.color, size: 16),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              branch.name,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Flexible(
                  child: Text(
                    branch.city.isEmpty ? '—' : branch.city,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  branch.isOpen ? '● Open' : '● Closed',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: branch.isOpen ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
    ],
  );
}

class _SalesCell extends StatelessWidget {
  final BranchReport report;
  final double best;
  final DashboardPeriod period;

  const _SalesCell({
    required this.report,
    required this.best,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final delta = _delta(report.revenue, report.previousRevenue);
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  formatMoney(report.revenue),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: report.branch.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (delta != null) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: 'vs ${period.previousLabel}',
                  child: _DeltaText(delta),
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: best == 0 ? 0 : report.revenue / best,
              minHeight: 4,
              backgroundColor: AppColors.greyLt,
              valueColor: AlwaysStoppedAnimation(report.branch.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCell extends StatelessWidget {
  final BranchReport r;
  const _LiveCell(this.r);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '${r.pendingOrders} pending · ${r.activeDeliveries} on the way',
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.dark,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        r.counterOpen
            ? 'Counter open · ${formatMoney(r.expectedCash)} cash'
            : 'Counter closed',
        style: TextStyle(
          fontSize: 10.5,
          color: r.counterOpen ? AppColors.success : AppColors.grey,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

// ── Empty / error ─────────────────────────────────────────────────────────────
class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) => const AppCard(
    padding: EdgeInsets.all(32),
    child: Center(
      child: Column(
        children: [
          SvgIcon(AppIcons.storeOutlined, size: 36, color: AppColors.grey),
          SizedBox(height: 10),
          Text(
            'No branches yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Add a branch from the Branches page to see its report here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.grey),
          ),
        ],
      ),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Column(
        children: [
          const SvgIcon(
            AppIcons.errorOutlineRounded,
            size: 32,
            color: AppColors.danger,
          ),
          const SizedBox(height: 10),
          const Text(
            "Couldn't load the report",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.grey),
          ),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
