import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resturent_application/feature/restaurant/customer_lookup/data/customer_lookup_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// One incoming call from the caller-ID box.
class CallEntry {
  final String id;
  final String phone;
  final DateTime calledAt;

  const CallEntry({
    required this.id,
    required this.phone,
    required this.calledAt,
  });

  factory CallEntry.fromMap(Map<String, dynamic> m) => CallEntry(
    id: m['id'] as String,
    phone: (m['phone'] as String?) ?? '',
    calledAt: DateTime.parse(m['called_at'] as String).toLocal(),
  );
}

SupabaseClient get _db => Supabase.instance.client;

/// Latest calls, newest first, updated live.
final callLogProvider = StreamProvider<List<CallEntry>>(
  (ref) => _db
      .from('call_log')
      .stream(primaryKey: ['id'])
      .order('called_at', ascending: false)
      .limit(50)
      .map((rows) => rows.map(CallEntry.fromMap).toList()),
);

/// Records a call. The caller-ID box (or the Test call button) calls this.
Future<void> logCall(String phone) async {
  final p = phone.trim();
  if (p.isEmpty) return;
  await _db.from('call_log').insert({'phone': p});
}

/// Customers, used to tell Saved from Unsaved numbers.
final callCustomersProvider = FutureProvider<List<CustomerProfile>>(
  (ref) => CustomerLookupDatasource().fetchAll(''),
);
