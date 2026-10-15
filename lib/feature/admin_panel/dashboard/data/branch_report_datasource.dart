import 'package:supabase_flutter/supabase_flutter.dart';
import '../../branches/data/model/branches_model.dart';

/// One branch's figures for the selected period, from the same
/// `dashboard_stats` function the branch POS dashboard uses, so the owner
/// sees exactly the numbers each branch sees.
class BranchReport {
  final Branch branch;

  /// Set when this branch's figures could not be loaded.
  final String? error;

  final double revenue;
  final double previousRevenue;
  final int paidOrders;
  final double avgOrder;
  final double discounts;
  final int ordersPlaced;
  final int cancelled;
  final double unpaidAmount;
  final double websiteRevenue;
  final double posRevenue;
  final double cash;
  final double card;
  final double online;

  // Live, not tied to the period.
  final int pendingOrders;
  final int activeDeliveries;
  final bool counterOpen;
  final double expectedCash;

  const BranchReport({
    required this.branch,
    this.error,
    this.revenue = 0,
    this.previousRevenue = 0,
    this.paidOrders = 0,
    this.avgOrder = 0,
    this.discounts = 0,
    this.ordersPlaced = 0,
    this.cancelled = 0,
    this.unpaidAmount = 0,
    this.websiteRevenue = 0,
    this.posRevenue = 0,
    this.cash = 0,
    this.card = 0,
    this.online = 0,
    this.pendingOrders = 0,
    this.activeDeliveries = 0,
    this.counterOpen = false,
    this.expectedCash = 0,
  });

  factory BranchReport.fromStats(Branch branch, Map<String, dynamic> j) {
    double d(Map? m, String k) => (m?[k] as num?)?.toDouble() ?? 0;
    int i(Map? m, String k) => (m?[k] as num?)?.toInt() ?? 0;
    final cur = j['current'] as Map?;
    final prev = j['previous'] as Map?;
    final channel = j['channel'] as Map?;
    final method = j['by_method'] as Map?;
    final live = j['live'] as Map?;
    final counter = live?['counter'] as Map?;
    return BranchReport(
      branch: branch,
      revenue: d(cur, 'revenue'),
      previousRevenue: d(prev, 'revenue'),
      paidOrders: i(cur, 'paid_orders'),
      avgOrder: d(cur, 'avg_order'),
      discounts: d(cur, 'discounts'),
      ordersPlaced: i(cur, 'orders_placed'),
      cancelled: i(cur, 'cancelled'),
      unpaidAmount: d(cur, 'unpaid_amount'),
      websiteRevenue: d(channel, 'website_revenue'),
      posRevenue: d(channel, 'pos_revenue'),
      cash: d(method, 'cash'),
      card: d(method, 'card'),
      online: d(method, 'online'),
      pendingOrders: i(live, 'pending_orders'),
      activeDeliveries: i(live, 'active_deliveries'),
      counterOpen: counter != null,
      expectedCash: d(counter, 'expected_cash'),
    );
  }
}

class BranchReportDatasource {
  final SupabaseClient _db;

  BranchReportDatasource(this._db);

  /// Figures for every branch over [from]..[to], fetched in parallel. A branch
  /// that fails comes back with [BranchReport.error] instead of failing all.
  Future<List<BranchReport>> fetch(List<Branch> branches, DateTime from, DateTime to) {
    final offset = DateTime.now().timeZoneOffset.inMinutes;
    return Future.wait(branches.map((b) async {
      try {
        final res = await _db.rpc('dashboard_stats', params: {
          'p_branch_id': b.id,
          'p_from': from.toUtc().toIso8601String(),
          'p_to': to.toUtc().toIso8601String(),
          'p_utc_offset_min': offset,
        });
        return BranchReport.fromStats(b, Map<String, dynamic>.from(res as Map));
      } catch (e) {
        return BranchReport(branch: b, error: e.toString().replaceAll('Exception: ', ''));
      }
    }));
  }
}
