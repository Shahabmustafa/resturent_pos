import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/provider/branch_auth_provider.dart';
import '../../data/datasource/customer_datasource.dart';
import '../../data/model/customer_model.dart';

final customerDatasourceProvider = Provider<CustomerDatasource>(
      (_) => CustomerDatasource(Supabase.instance.client),
);

class CustomerState {
  final List<CustomerModel> customers;
  final bool isLoading;
  final String? errorMessage;

  const CustomerState({
    this.customers = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CustomerState copyWith({
    List<CustomerModel>? customers,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) => CustomerState(
    customers:    customers    ?? this.customers,
    isLoading:    isLoading    ?? this.isLoading,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

class CustomerNotifier extends StateNotifier<CustomerState> {
  final CustomerDatasource _ds;
  final String _branchId;

  CustomerNotifier(this._ds, this._branchId) : super(const CustomerState()) {
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final customers = await _ds.fetchCustomers(_branchId);
      state = state.copyWith(customers: customers, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> addCustomer(CustomerModel customer) async {
    try {
      final added = await _ds.addCustomer(customer, _branchId);
      state = state.copyWith(customers: [added, ...state.customers]);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      final updated = await _ds.updateCustomer(customer);
      state = state.copyWith(
        customers: state.customers.map((c) => c.id == updated.id ? updated : c).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  Future<void> deleteCustomer(String customerId) async {
    try {
      await _ds.deleteCustomer(customerId);
      state = state.copyWith(customers: state.customers.where((c) => c.id != customerId).toList());
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

// autoDispose: the list reloads each time the Customers page opens, so order
// counts and totals (updated by the database) are current.
final customerProvider = StateNotifierProvider.autoDispose<CustomerNotifier, CustomerState>((ref) {
  final ds       = ref.watch(customerDatasourceProvider);
  final branchId = ref.watch(branchAuthProvider).branch!.branchId; // ✅ FIXED
  return CustomerNotifier(ds, branchId);
});