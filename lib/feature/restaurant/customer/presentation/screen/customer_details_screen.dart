import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/constants/currency.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:resturent_application/feature/restaurant/customer_lookup/data/customer_lookup_datasource.dart';
import 'package:resturent_application/feature/restaurant/home/presentation/screen/pos_home_screen.dart';
import 'package:resturent_application/feature/restaurant/live_orders/presentation/live_orders_screen.dart';
import 'package:url_launcher/url_launcher.dart';

const _bg = Color(0xFFD4D4D2);
const _panel = Color(0xFFE9E9E9);
const _purple = Color(0xFF9B51B8);
const _red = Color(0xFFD9534F);
const _perPage = 5;

enum _Tab { details, address, orders }

/// Starts a sale for this customer (type is 'Dine-in', 'Takeaway' or 'Delivery').
typedef StartCustomerSale =
    void Function(String orderType, CustomerProfile customer);

/// One customer: details form, saved address and past orders, with the sale buttons
/// along the bottom.
class CustomerDetailsScreen extends StatefulWidget {
  final CustomerProfile customer;
  final CustomerLookupDatasource datasource;
  final String branchId;
  final VoidCallback onCancel;
  // Saved (or blacklist changed): the list should reload.
  final VoidCallback onChanged;
  final StartCustomerSale onStartSale;
  final void Function(CustomerProfile customer, CustomerOrderSummary order)
  onReorder;

  const CustomerDetailsScreen({
    super.key,
    required this.customer,
    required this.datasource,
    required this.branchId,
    required this.onCancel,
    required this.onChanged,
    required this.onStartSale,
    required this.onReorder,
  });

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  late final CustomerProfile c = widget.customer;
  _Tab _tab = _Tab.details;
  bool _saving = false;
  int _orderPage = 0;
  Future<List<CustomerOrderSummary>>? _orders;

  late final _ctrl = {
    'phone': TextEditingController(text: c.phone),
    'phone2': TextEditingController(text: c.phone2),
    'phone3': TextEditingController(text: c.phone3),
    'first': TextEditingController(text: c.firstName),
    'last': TextEditingController(text: c.lastName),
    'email': TextEditingController(text: c.email),
    'address': TextEditingController(text: c.address),
    'city': TextEditingController(text: c.city),
    'postcode': TextEditingController(text: c.postcode),
    'comments': TextEditingController(text: c.comments),
  };

  bool get _isNew => c.id == null;

  @override
  void initState() {
    super.initState();
    // The name on the first tab follows the form.
    _ctrl['first']!.addListener(() => setState(() {}));
    _ctrl['last']!.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final t in _ctrl.values) {
      t.dispose();
    }
    super.dispose();
  }

  String get _name =>
      '${_ctrl['first']!.text.trim()} ${_ctrl['last']!.text.trim()}'.trim();

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _readForm() {
    c
      ..phone = _ctrl['phone']!.text
      ..phone2 = _ctrl['phone2']!.text
      ..phone3 = _ctrl['phone3']!.text
      ..firstName = _ctrl['first']!.text
      ..lastName = _ctrl['last']!.text
      ..email = _ctrl['email']!.text
      ..address = _ctrl['address']!.text
      ..city = _ctrl['city']!.text
      ..postcode = _ctrl['postcode']!.text
      ..comments = _ctrl['comments']!.text;
  }

  /// Saves the form and returns the customer id, or null when it could not be saved.
  Future<String?> _save() async {
    if (_ctrl['phone']!.text.trim().isEmpty) {
      setState(() => _tab = _Tab.details);
      _snack('Telephone #1 is required');
      return null;
    }
    _readForm();
    setState(() => _saving = true);
    try {
      final id = await widget.datasource.save(widget.branchId, c);
      widget.onChanged();
      return id;
    } catch (e) {
      _snack('Could not save customer: $e');
      return null;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveAndClose() async {
    if (await _save() != null && mounted) widget.onCancel();
  }

  Future<void> _sale(String orderType) async {
    final id = await _save();
    if (id == null || !mounted) return;
    widget.onStartSale(
      orderType,
      CustomerProfile(
        id: id,
        phone: c.phone,
        firstName: c.firstName,
        lastName: c.lastName,
        address: c.address,
        city: c.city,
        postcode: c.postcode,
      ),
    );
  }

  Future<void> _toggleBlacklist() async {
    final id = c.id;
    if (id == null) return;
    final next = !c.blacklisted;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(next ? 'Blacklist customer' : 'Remove from blacklist'),
        content: Text(
          next
              ? 'Blacklist ${c.fullName}?'
              : 'Remove ${c.fullName} from the blacklist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(next ? 'Blacklist' : 'Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.datasource.setBlacklisted(id, next);
      if (!mounted) return;
      setState(() => c.blacklisted = next);
      widget.onChanged();
    } catch (e) {
      _snack('Could not update: $e');
    }
  }

  void _openMap() {
    final q = [
      _ctrl['address']!.text,
      _ctrl['city']!.text,
      _ctrl['postcode']!.text,
    ].where((s) => s.trim().isNotEmpty).join(', ');
    if (q.isEmpty) return;
    launchUrl(
      Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': q}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              children: [
                _TabButton(
                  label: _name.isEmpty ? 'New Customer' : _name,
                  active: _tab == _Tab.details,
                  icon: AppIcons.personRounded,
                  onTap: () => setState(() => _tab = _Tab.details),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: 'Address',
                  active: _tab == _Tab.address,
                  icon: AppIcons.personRounded,
                  onTap: () => setState(() => _tab = _Tab.address),
                ),
                const SizedBox(width: 8),
                if (!_isNew)
                  _TabButton(
                    label: 'Orders',
                    active: _tab == _Tab.orders,
                    icon: AppIcons.eventSeatRounded,
                    onTap: () => setState(() {
                      _tab = _Tab.orders;
                      _orders ??= widget.datasource.fetchOrders(c.id!);
                    }),
                  ),
                const Spacer(),
                if (!_isNew)
                  Material(
                    color: c.blacklisted ? const Color(0xFF6B7280) : _red,
                    elevation: 2,
                    borderRadius: BorderRadius.circular(3),
                    child: InkWell(
                      onTap: _toggleBlacklist,
                      child: SizedBox(
                        width: 230,
                        height: 46,
                        child: Center(
                          child: Text(
                            c.blacklisted ? 'REMOVE BLACKLIST' : 'BLACKLIST',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: switch (_tab) {
              _Tab.details => _details(),
              _Tab.address => _address(),
              _Tab.orders => _ordersView(),
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            child: Row(
              children: [
                const TimeBox(),
                const SizedBox(width: 10),
                _BarButton(
                  label: 'Cancel',
                  icon: AppIcons.closeRounded,
                  color: Colors.black,
                  onTap: widget.onCancel,
                ),
                const SizedBox(width: 6),
                for (final t in saleTiles) ...[
                  _BarButton(
                    label: t.label,
                    icon: t.icon,
                    color: t.color,
                    busy: _saving,
                    onTap: () => _sale(t.orderType),
                  ),
                  const SizedBox(width: 6),
                ],
                const Spacer(),
                _BarButton(
                  label: 'Save',
                  icon: AppIcons.checkRounded,
                  color: Colors.white,
                  dark: true,
                  busy: _saving,
                  onTap: _saveAndClose,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Details tab ─────────────────────────────────────────────────────────────

  Widget _details() {
    Widget side(String label, String key, {TextInputType? keyboard}) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: _input(key, keyboard: keyboard)),
        ],
      ),
    );

    Widget stacked(String label, String key, {int lines = 1}) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          _input(key, lines: lines),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 400,
            color: _panel,
            padding: const EdgeInsets.fromLTRB(16, 30, 16, 30),
            child: Column(
              children: [
                side('Telephone #1', 'phone', keyboard: TextInputType.phone),
                side('Telephone #2', 'phone2', keyboard: TextInputType.phone),
                side('Telephone #3', 'phone3', keyboard: TextInputType.phone),
                side('First Name', 'first'),
                side('Last Name', 'last'),
                side('Email', 'email', keyboard: TextInputType.emailAddress),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              color: _panel,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        stacked('Address', 'address', lines: 4),
                        stacked('Comment', 'comments', lines: 3),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        stacked('City', 'city'),
                        stacked('Postcode', 'postcode'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(String key, {int lines = 1, TextInputType? keyboard}) =>
      TextField(
        controller: _ctrl[key],
        minLines: lines,
        maxLines: lines,
        keyboardType: keyboard,
        textCapitalization: key == 'postcode'
            ? TextCapitalization.characters
            : TextCapitalization.words,
        style: const TextStyle(fontSize: 14),
        decoration: const InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFFDDDDDD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFFDDDDDD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: _purple, width: 1.5),
          ),
        ),
      );

  // ── Address tab ─────────────────────────────────────────────────────────────

  Widget _address() {
    final street = [
      _ctrl['address']!.text.trim(),
      _ctrl['city']!.text.trim(),
    ].where((s) => s.isNotEmpty).join(' ');
    final post = _ctrl['postcode']!.text.trim();
    if (street.isEmpty && post.isEmpty) {
      return const Center(
        child: Text(
          'No address saved. Add one on the details tab.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }
    return Container(
      color: _panel,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 400,
        child: Material(
          color: _purple,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 120,
                padding: const EdgeInsets.fromLTRB(28, 22, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in [_name, street, post])
                      Text(
                        line,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                color: const Color(0xFFF7F7F7),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    _SquareButton(
                      icon: AppIcons.editRounded,
                      color: const Color(0xFF374151),
                      onTap: () => setState(() => _tab = _Tab.details),
                    ),
                    const Spacer(),
                    _SquareButton(
                      icon: AppIcons.locationOnOutlined,
                      color: Colors.red,
                      onTap: _openMap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Orders tab ──────────────────────────────────────────────────────────────

  Widget _ordersView() => FutureBuilder<List<CustomerOrderSummary>>(
    future: _orders,
    builder: (_, snap) {
      if (snap.hasError)
        return Center(child: Text('Could not load orders: ${snap.error}'));
      if (!snap.hasData)
        return const Center(child: CircularProgressIndicator());
      final all = snap.data!;
      if (all.isEmpty)
        return const Center(
          child: Text(
            'No orders yet',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        );
      final pages = (all.length / _perPage).ceil();
      final page = _orderPage.clamp(0, pages - 1);
      final rows = all.skip(page * _perPage).take(_perPage).toList();
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: _panel,
            child: Column(
              children: [
                for (final o in rows)
                  _OrderRow(order: o, onReorder: () => widget.onReorder(c, o)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PageBtn(
                '‹',
                page > 0 ? () => setState(() => _orderPage = page - 1) : null,
              ),
              Container(
                width: 42,
                height: 42,
                color: const Color(0xFF1E7BC6),
                alignment: Alignment.center,
                child: Text(
                  '${page + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _PageBtn(
                '›',
                page < pages - 1
                    ? () => setState(() => _orderPage = page + 1)
                    : null,
              ),
            ],
          ),
        ],
      );
    },
  );
}

class _OrderRow extends StatelessWidget {
  final CustomerOrderSummary order;
  final VoidCallback onReorder;
  const _OrderRow({required this.order, required this.onReorder});

  Color get _statusColor => switch (order.status.toLowerCase()) {
    'cancelled' || 'rejected' => const Color(0xFF6B6B6B),
    'completed' || 'delivered' => const Color(0xFF4CA67A),
    _ => const Color(0xFF2EC4B6),
  };

  String get _statusLabel => switch (order.status.toLowerCase()) {
    'pending' => 'Preparing',
    'cancelled' => 'Rejected',
    final s => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1),
  };

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFFDDDDDD))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 190,
          height: 70,
          color: const Color(0xFFF1F1F1),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('#${order.number}', style: const TextStyle(fontSize: 14)),
              Text(
                formatMoney(order.total),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 200,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  color: _statusColor,
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text(
                    _statusLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (order.createdAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat(
                        'yyyy-MM-dd HH:mm:ss',
                      ).format(order.createdAt!),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, left: 20),
            child: Text(
              order.lines.map((l) => '${l.name},').join(' '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 40),
          child: Material(
            color: const Color(0xFF2F72B7),
            borderRadius: BorderRadius.circular(3),
            child: InkWell(
              onTap: order.lines.isEmpty ? null : onReorder,
              child: const SizedBox(
                width: 62,
                height: 50,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgIcon(
                      AppIcons.refreshRounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Reorder',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _TabButton extends StatelessWidget {
  final String label;
  final AppIcon icon;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: active ? _purple : Colors.white,
    elevation: 1,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 190,
        height: 46,
        child: Row(
          children: [
            const SizedBox(width: 14),
            SvgIcon(
              icon,
              size: 22,
              color: active ? Colors.white : Colors.black87,
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: active ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 22),
          ],
        ),
      ),
    ),
  );
}

class _BarButton extends StatelessWidget {
  final String label;
  final AppIcon icon;
  final Color color;
  final bool dark; // dark text on a light button
  final bool busy;
  final VoidCallback onTap;
  const _BarButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.dark = false,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    elevation: 4,
    shadowColor: Colors.black,
    borderRadius: BorderRadius.circular(3),
    child: InkWell(
      onTap: busy ? null : onTap,
      child: SizedBox(
        width: 150,
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgIcon(
              icon,
              size: 26,
              color: dark ? Colors.black87 : Colors.white,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: dark ? Colors.black87 : Colors.white,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SquareButton extends StatelessWidget {
  final AppIcon icon;
  final Color color;
  final VoidCallback onTap;
  const _SquareButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: Border.all(color: const Color(0xFFDDDDDD)),
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        height: 44,
        child: Center(child: SvgIcon(icon, size: 20, color: color)),
      ),
    ),
  );
}

class _PageBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _PageBtn(this.label, this.onTap);

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF2F2F2),
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 42,
        height: 42,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              color: onTap == null ? Colors.black26 : const Color(0xFF1E7BC6),
            ),
          ),
        ),
      ),
    ),
  );
}
