import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/customer_model.dart';

class CustomerDatasource {
  final SupabaseClient _client;
  static const _table = 'customers';

  CustomerDatasource(this._client);

  // ── Fetch all customers for a branch ─────────────────────────────
  Future<List<CustomerModel>> fetchCustomers(String branchId) async {
    final res = await _client
        .from(_table)
        .select()
        .eq('branch_id', branchId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => CustomerModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ── Add ───────────────────────────────────────────────────────────
  Future<CustomerModel> addCustomer(CustomerModel customer, String branchId) async {
    final res = await _client
        .from(_table)
        .insert(customer.toInsertMap(branchId))
        .select()
        .single();

    return CustomerModel.fromMap(res);
  }

  // ── Update ────────────────────────────────────────────────────────
  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    final res = await _client
        .from(_table)
        .update(customer.toUpdateMap())
        .eq('id', customer.id)
        .select()
        .single();

    return CustomerModel.fromMap(res);
  }

  // ── Delete ────────────────────────────────────────────────────────
  Future<void> deleteCustomer(String customerId) async {
    await _client
        .from(_table)
        .delete()
        .eq('id', customerId);
  }
}