import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/constants/app_info.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:resturent_application/feature/restaurant/auth/presentation/provider/branch_auth_provider.dart';
import 'package:resturent_application/feature/restaurant/live_orders/presentation/live_orders_screen.dart';
import 'package:resturent_application/feature/restaurant/order/presentation/provider/order_provider.dart';
import 'package:resturent_application/feature/restaurant/setting/presentation/provider/branch_setting_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _bg = Color(0xFFD4D4D2);
const _blue = Color(0xFF2C73B8);
const _cols =
    'online_orders_enabled, delivery_enabled, collection_enabled, delivery_minutes, collection_minutes';

class WebsiteSettings {
  final bool online;
  final bool delivery;
  final bool collection;
  final int deliveryMinutes;
  final int collectionMinutes;
  const WebsiteSettings({
    this.online = true,
    this.delivery = true,
    this.collection = true,
    this.deliveryMinutes = 45,
    this.collectionMinutes = 15,
  });

  factory WebsiteSettings.fromMap(Map<String, dynamic> m) => WebsiteSettings(
    online: m['online_orders_enabled'] as bool? ?? true,
    delivery: m['delivery_enabled'] as bool? ?? true,
    collection: m['collection_enabled'] as bool? ?? true,
    deliveryMinutes: (m['delivery_minutes'] as num?)?.toInt() ?? 45,
    collectionMinutes: (m['collection_minutes'] as num?)?.toInt() ?? 15,
  );

  WebsiteSettings copyWith({
    bool? online,
    bool? delivery,
    bool? collection,
    int? deliveryMinutes,
    int? collectionMinutes,
  }) => WebsiteSettings(
    online: online ?? this.online,
    delivery: delivery ?? this.delivery,
    collection: collection ?? this.collection,
    deliveryMinutes: deliveryMinutes ?? this.deliveryMinutes,
    collectionMinutes: collectionMinutes ?? this.collectionMinutes,
  );

  Map<String, dynamic> toMap() => {
    'online_orders_enabled': online,
    'delivery_enabled': delivery,
    'collection_enabled': collection,
    'delivery_minutes': deliveryMinutes,
    'collection_minutes': collectionMinutes,
  };
}

class _ManageState {
  final WebsiteSettings settings;
  final bool loading;
  final String? error;
  const _ManageState({
    this.settings = const WebsiteSettings(),
    this.loading = true,
    this.error,
  });
}

/// Reads and writes the website switches on the branch row.
class _ManageNotifier extends StateNotifier<_ManageState> {
  final String _branchId;
  _ManageNotifier(this._branchId) : super(const _ManageState()) {
    _load();
  }

  SupabaseClient get _db => Supabase.instance.client;

  Future<void> _load() async {
    try {
      final row = await _db
          .from('branches')
          .select(_cols)
          .eq('id', _branchId)
          .single();
      if (mounted)
        state = _ManageState(
          settings: WebsiteSettings.fromMap(row),
          loading: false,
        );
    } catch (e) {
      if (mounted) state = _ManageState(loading: false, error: _message(e));
    }
  }

  /// Shows the change at once, then saves it; puts the old value back if saving fails.
  Future<void> update(WebsiteSettings next) async {
    final old = state.settings;
    state = _ManageState(settings: next, loading: false);
    try {
      await _db.from('branches').update(next.toMap()).eq('id', _branchId);
    } catch (e) {
      if (mounted)
        state = _ManageState(settings: old, loading: false, error: _message(e));
    }
  }

  static String _message(Object e) {
    final text = e is PostgrestException ? e.message : e.toString();
    return text.contains('does not exist') || text.contains('column')
        ? 'The website settings are not set up in the database yet (run the 20261028130000 migration).'
        : text;
  }
}

final _manageProvider =
    StateNotifierProvider.autoDispose<_ManageNotifier, _ManageState>((ref) {
      final branchId = ref.watch(branchAuthProvider).branch?.branchId ?? '';
      return _ManageNotifier(branchId);
    });

/// Website ordering switches, today's date and recent callers' numbers.
class ManageScreen extends ConsumerWidget {
  final VoidCallback onBack;
  final VoidCallback onMenu;
  final VoidCallback? onDeliveries;
  final VoidCallback? onUsers;
  final VoidCallback? onSettings;
  final VoidCallback onReprint;

  const ManageScreen({
    super.key,
    required this.onBack,
    required this.onMenu,
    required this.onDeliveries,
    required this.onUsers,
    required this.onSettings,
    required this.onReprint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(_manageProvider);
    final notifier = ref.read(_manageProvider.notifier);
    final s = m.settings;
    final auth = ref.watch(branchAuthProvider).branch;
    final branch = ref.watch(branchSettingsProvider).branch;
    final systemName = (branch?.restaurantName.isNotEmpty ?? false)
        ? branch!.restaurantName
        : (branch?.name ?? kAppName);

    return Container(
      color: _bg,
      child: Column(
        children: [
          if (m.error != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFFDECEA),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                m.error!,
                style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: m.loading
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  _Section(
                                    title: 'ONLINE ORDER',
                                    on: s.online,
                                    onChanged: (v) =>
                                        notifier.update(s.copyWith(online: v)),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _Section(
                                          title: 'DELIVERY',
                                          on: s.delivery,
                                          onChanged: (v) => notifier.update(
                                            s.copyWith(delivery: v),
                                          ),
                                          minutes: s.deliveryMinutes,
                                          onMinutes: (v) => notifier.update(
                                            s.copyWith(deliveryMinutes: v),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _Section(
                                          title: 'COLLECTION',
                                          on: s.collection,
                                          onChanged: (v) => notifier.update(
                                            s.copyWith(collection: v),
                                          ),
                                          minutes: s.collectionMinutes,
                                          onMinutes: (v) => notifier.update(
                                            s.copyWith(collectionMinutes: v),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),
                                  _Clock(systemName: systemName),
                                  const Divider(height: 40),
                                  _InfoRow('User', auth?.username ?? ''),
                                  _InfoRow('System', systemName),
                                  _InfoRow('Version', 'v $kAppVersion'),
                                  if ((branch?.website ?? '').isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        branch!.website,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const SizedBox(width: 360, child: _RecentNumbers()),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            child: Row(
              children: [
                const TimeBox(),
                const SizedBox(width: 10),
                _NavButton(
                  label: 'Back',
                  icon: AppIcons.arrowBackRounded,
                  color: Colors.white,
                  background: Colors.black,
                  onTap: onBack,
                ),
                const SizedBox(width: 6),
                _NavButton(
                  label: 'Menu',
                  icon: AppIcons.menuBookRounded,
                  color: const Color(0xFF3F51B5),
                  onTap: onMenu,
                ),
                if (onDeliveries != null) ...[
                  const SizedBox(width: 6),
                  _NavButton(
                    label: 'Deliveries',
                    icon: AppIcons.deliveryDiningRounded,
                    color: const Color(0xFF8E44AD),
                    onTap: onDeliveries!,
                  ),
                ],
                if (onUsers != null) ...[
                  const SizedBox(width: 6),
                  _NavButton(
                    label: 'Users',
                    icon: AppIcons.manageAccountsRounded,
                    color: const Color(0xFF2C73B8),
                    onTap: onUsers!,
                  ),
                ],
                if (onSettings != null) ...[
                  const SizedBox(width: 6),
                  _NavButton(
                    label: 'Settings',
                    icon: AppIcons.settingsRounded,
                    color: const Color(0xFF3DBB16),
                    onTap: onSettings!,
                  ),
                ],
                const SizedBox(width: 6),
                _NavButton(
                  label: 'Re Print',
                  icon: AppIcons.receiptLongRounded,
                  color: const Color(0xFFE8742A),
                  onTap: onReprint,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Title, ON / OFF switch and (optionally) a minutes stepper.
class _Section extends StatelessWidget {
  final String title;
  final bool on;
  final ValueChanged<bool> onChanged;
  final int? minutes;
  final ValueChanged<int>? onMinutes;
  const _Section({
    required this.title,
    required this.on,
    required this.onChanged,
    this.minutes,
    this.onMinutes,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFEEEEEE)),
    ),
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Choice('ON', selected: on, onTap: () => onChanged(true)),
            _Choice('OFF', selected: !on, onTap: () => onChanged(false)),
          ],
        ),
        if (minutes != null) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Step('-', () => onMinutes!((minutes! - 5).clamp(0, 300))),
              Container(
                width: 100,
                height: 38,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$minutes Min',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              _Step('+', () => onMinutes!((minutes! + 5).clamp(0, 300))),
            ],
          ),
        ],
      ],
    ),
  );
}

class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Choice(this.label, {required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? _blue : Colors.white,
    shape: Border.all(color: selected ? _blue : const Color(0xFFCCCCCC)),
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 66,
        height: 46,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    ),
  );
}

class _Step extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Step(this.label, this.onTap);

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: Border.all(color: const Color(0xFFCCCCCC)),
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 42,
        height: 38,
        child: Center(child: Text(label, style: const TextStyle(fontSize: 16))),
      ),
    ),
  );
}

class _Clock extends StatelessWidget {
  final String systemName;
  const _Clock({required this.systemName});

  @override
  Widget build(BuildContext context) => StreamBuilder<DateTime>(
    stream: Stream.periodic(const Duration(seconds: 15), (_) => DateTime.now()),
    initialData: DateTime.now(),
    builder: (_, snap) => Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/branding/app_icon.svg',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 10),
            Text(
              systemName,
              style: const TextStyle(
                color: Color(0xFFC0392B),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        Text(
          DateFormat('EEE dd.MM.yyyy').format(snap.data!),
          style: const TextStyle(fontSize: 28),
        ),
        const SizedBox(height: 10),
        Text(
          DateFormat('h:mm a').format(snap.data!),
          style: const TextStyle(fontSize: 22),
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        const SizedBox(width: 10),
        const Text(':'),
        const SizedBox(width: 10),
        SizedBox(
          width: 220,
          child: Text(value, style: const TextStyle(fontSize: 15)),
        ),
      ],
    ),
  );
}

/// Numbers that recently placed an order; "Saved" when the number belongs to a customer.
class _RecentNumbers extends ConsumerWidget {
  const _RecentNumbers();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders =
        ref
            .watch(orderProvider)
            .orders
            .where((o) => o.customerPhone.trim().isNotEmpty)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Container(
      color: Colors.white,
      child: orders.isEmpty
          ? const Center(
              child: Text(
                'No recent orders',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            )
          : ListView.separated(
              itemCount: orders.length.clamp(0, 40),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final o = orders[i];
                final saved = o.customerId != null;
                final at = o.createdAt.toLocal();
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.customerPhone,
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                SvgIcon(
                                  saved
                                      ? AppIcons.checkRounded
                                      : AppIcons.personRounded,
                                  size: 14,
                                  color: saved
                                      ? const Color(0xFF3DBB16)
                                      : Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  saved ? 'Saved' : 'Unsaved',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat('h:mm a').format(at),
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('M/d/yy').format(at),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final AppIcon icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;
  const _NavButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.background = Colors.white,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: background,
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(3),
      side: BorderSide(
        color: background == Colors.white ? color : Colors.black,
        width: 2,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgIcon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    ),
  );
}
