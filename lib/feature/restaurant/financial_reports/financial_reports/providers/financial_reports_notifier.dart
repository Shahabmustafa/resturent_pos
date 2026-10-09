import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/financial_reports_datasource.dart';
import '../models/financial_reports_models.dart';

class FinancialReportsNotifier extends StateNotifier<FinancialReportsState> {
  final FinancialReportsDatasource _ds;
  final String _branchId;

  FinancialReportsNotifier(this._ds, this._branchId)
      : super(FinancialReportsState(
          startDate: DateFilter.today.range.$1,
          endDate: DateFilter.today.range.$2,
        )) {
    loadAll();
  }

  Future<void> loadAll() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _ds.fetchSummary(branchId: _branchId, start: state.startDate, end: state.endDate),
        _ds.fetchProductReports(branchId: _branchId, start: state.startDate, end: state.endDate),
        _ds.fetchDailySales(branchId: _branchId, start: state.startDate, end: state.endDate),
        _ds.fetchExpenseReports(branchId: _branchId, start: state.startDate, end: state.endDate),
      ]);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        summary: results[0] as FinancialSummary,
        productReports: results[1] as List<ProductReport>,
        dailySales: results[2] as List<DailySales>,
        expenseReports: results[3] as List<ExpenseReport>,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void applyFilter(DateFilter filter) {
    if (filter == DateFilter.custom) return;
    final (start, end) = filter.range;
    state = state.copyWith(selectedFilter: filter, startDate: start, endDate: end);
    loadAll();
  }

  void applyCustomRange(DateTime start, DateTime end) {
    state = state.copyWith(
      selectedFilter: DateFilter.custom,
      startDate: start,
      endDate: DateTime(end.year, end.month, end.day, 23, 59, 59),
    );
    loadAll();
  }

  void setSortProductBy(String sort) {
    state = state.copyWith(sortProductBy: sort);
  }

  List<ProductReport> get sortedProducts {
    final list = [...state.productReports];
    switch (state.sortProductBy) {
      case 'quantity':
        list.sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
      case 'profit':
        list.sort((a, b) => b.profit.compareTo(a.profit));
      default:
        list.sort((a, b) => b.revenue.compareTo(a.revenue));
    }
    return list;
  }
}
