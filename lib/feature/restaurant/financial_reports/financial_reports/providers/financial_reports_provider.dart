import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/provider/branch_auth_provider.dart';
import '../../../customer/presentation/provider/customer_provider.dart';
import '../data/financial_reports_datasource.dart';
import '../models/financial_reports_models.dart';
import 'financial_reports_notifier.dart';

// Import your actual branch auth provider path
// import '../../auth/providers/branch_auth_provider.dart';

final financialReportsDatasourceProvider = Provider<FinancialReportsDatasource>(
  (ref) => FinancialReportsDatasource(Supabase.instance.client),
);

final financialReportsProvider = StateNotifierProvider<FinancialReportsNotifier, FinancialReportsState>((ref) {
  final branchId = ref.watch(branchAuthProvider).branch!.branchId;
  final ds = ref.watch(financialReportsDatasourceProvider);
  return FinancialReportsNotifier(ds, branchId);
});
