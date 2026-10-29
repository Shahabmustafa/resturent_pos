import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/constants/currency.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:resturent_application/feature/restaurant/auth/presentation/provider/branch_auth_provider.dart';
import '../data/customer_lookup_datasource.dart';
import 'lookup_tabs.dart';

const _navy = Color(0xFF000000);
const _tabActive = Color(0xFF9B51C0);
const _keyBlue = Color(0xFF5BC0DE);
const _red = Color(0xFFD9534F);
const _green = Color(0xFF5CB85C);
const _panel = Color(0xFFFFFFFF);
const _label = Color(0xFF4B5563);

final customerLookupDatasourceProvider = Provider(
  (_) => CustomerLookupDatasource(),
);

/// Collection order start: find the customer by phone (or postcode, street,
/// name), check their details, then open POS for them.
class CollectionFlow extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  /// Name of the first tab: the sale type being started.
  final String saleLabel;

  /// Switch to another sale type ('Takeaway' = shop, 'Dine-in', 'Delivery').
  final ValueChanged<String> onStartSale;

  /// No customer: open POS as a walk-in collection.
  final VoidCallback onSkip;

  /// Customer saved: open POS with this customer selected.
  final ValueChanged<String> onConfirm;

  /// Delivery mode: the details step also asks for the delivery charge.
  final void Function(String customerId, double charge, String address)?
  onDelivery;

  const CollectionFlow({
    super.key,
    required this.onBack,
    required this.onStartSale,
    required this.onSkip,
    required this.onConfirm,
    this.onDelivery,
    this.saleLabel = 'COLLECTION',
  });

  @override
  ConsumerState<CollectionFlow> createState() => _CollectionFlowState();
}

class _CollectionFlowState extends ConsumerState<CollectionFlow> {
  CustomerProfile? _customer; // set = details step

  String get _branchId => ref.read(branchAuthProvider).branch!.branchId;

  @override
  Widget build(BuildContext context) {
    final ds = ref.read(customerLookupDatasourceProvider);
    return Container(
      color: const Color(0xFFD4D4D2),
      child: _customer == null
          ? _LookupView(
              loadAll: () => ds.fetchAll(_branchId),
              findByPhone: (phone) => ds.findByPhone(_branchId, phone),
              onBack: widget.onBack,
              saleLabel: widget.saleLabel,
              onStartSale: widget.onStartSale,
              delivery: widget.onDelivery != null,
              onSkip: widget.onSkip,
              onCustomer: (c) => setState(() => _customer = c),
            )
          : _DetailsView(
              key: ValueKey(_customer!.id ?? 'new-${_customer!.phone}'),
              customer: _customer!,
              loadOrders: ds.fetchOrders,
              save: (c) => ds.save(_branchId, c),
              onBack: () => setState(() => _customer = null),
              delivery: widget.onDelivery != null,
              onConfirm: (id, charge, address) => widget.onDelivery != null
                  ? widget.onDelivery!(id, charge, address)
                  : widget.onConfirm(id),
            ),
    );
  }
}

// ── Step 1: lookup ────────────────────────────────────────────────────────────

enum _LookupTab { phone, postcode, street, customers }

class _LookupView extends StatefulWidget {
  final Future<List<CustomerProfile>> Function() loadAll;
  final Future<CustomerProfile?> Function(String phone) findByPhone;
  final VoidCallback onBack;
  final String saleLabel;
  final ValueChanged<String> onStartSale;
  final bool delivery;
  final VoidCallback onSkip;
  final ValueChanged<CustomerProfile> onCustomer;

  const _LookupView({
    required this.loadAll,
    required this.findByPhone,
    required this.onBack,
    required this.saleLabel,
    required this.onStartSale,
    required this.delivery,
    required this.onSkip,
    required this.onCustomer,
  });

  @override
  State<_LookupView> createState() => _LookupViewState();
}

class _LookupViewState extends State<_LookupView> {
  _LookupTab _tab = _LookupTab.phone;
  late final Future<List<CustomerProfile>> _all = widget.loadAll();
  final _phone = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _press(String key) {
    final t = _phone.text;
    _phone.text = switch (key) {
      'back' => t.isEmpty ? t : t.substring(0, t.length - 1),
      'clear' => '',
      _ => t + key,
    };
  }

  Future<void> _ok() async {
    final phone = _phone.text.trim();
    if (phone.isEmpty) return;
    setState(() => _searching = true);
    try {
      final found = await widget.findByPhone(phone);
      if (!mounted) return;
      widget.onCustomer(found ?? CustomerProfile(phone: phone));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not search customers: $e')));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TabBar(
          children: [
            _TabButton(
              label: widget.saleLabel,
              active: _tab == _LookupTab.phone,
              onTap: () => setState(() => _tab = _LookupTab.phone),
            ),
            _TabButton(
              label: 'POSTCODES',
              active: _tab == _LookupTab.postcode,
              onTap: () => setState(() => _tab = _LookupTab.postcode),
            ),
            _TabButton(
              label: 'STREETS',
              active: _tab == _LookupTab.street,
              onTap: () => setState(() => _tab = _LookupTab.street),
            ),
            _TabButton(
              label: 'CUSTOMERS',
              active: _tab == _LookupTab.customers,
              onTap: () => setState(() => _tab = _LookupTab.customers),
            ),
          ],
        ),
        Expanded(
          child: switch (_tab) {
            _LookupTab.phone => _phonePad(),
            _LookupTab.postcode => PostcodesTab(
              all: _all,
              onCustomer: widget.onCustomer,
            ),
            _LookupTab.street => StreetsTab(
              all: _all,
              onCustomer: widget.onCustomer,
            ),
            _LookupTab.customers => CustomersTab(
              all: _all,
              onCustomer: widget.onCustomer,
            ),
          },
        ),
        _BottomBar(
          children: [
            const _ClockBrandBox(),
            const SizedBox(width: 12),
            _ActionButton(
              label: 'BACK',
              icon: AppIcons.arrowBackRounded,
              color: _navy,
              onTap: widget.onBack,
            ),
            const Spacer(),
            _ChangeSaleButton(
              onPick: widget.onStartSale,
              delivery: widget.delivery,
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  Widget _phonePad() {
    Widget key(
      String label,
      String value, {
      Color color = _keyBlue,
      Color text = Colors.white,
      AppIcon? icon,
    }) => Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: color,
        elevation: 3,
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          borderRadius: BorderRadius.circular(3),
          onTap: () => _press(value),
          child: SizedBox(
            width: 128,
            height: 64,
            child: Center(
              child: icon != null
                  ? SvgIcon(icon, size: 26, color: text)
                  : Text(
                      label,
                      style: TextStyle(
                        color: text,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Telephone',
                  style: TextStyle(
                    color: _label,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 360,
                  child: TextField(
                    controller: _phone,
                    autofocus: true,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                    ],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _fieldDecoration(),
                    onSubmitted: (_) => _ok(),
                  ),
                ),
                const SizedBox(width: 14),
                _ActionButton(
                  label: 'SKIP',
                  icon: AppIcons.arrowForwardRounded,
                  color: _red,
                  width: 90,
                  height: 52,
                  onTap: widget.onSkip,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final row in const [
                      ['1', '2', '3'],
                      ['4', '5', '6'],
                      ['7', '8', '9'],
                    ])
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [for (final d in row) key(d, d)],
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        key(
                          'Delete',
                          'back',
                          color: _panel,
                          text: _label,
                          icon: AppIcons.arrowBackRounded,
                        ),
                        key('0', '0'),
                        key(
                          'Clear',
                          'clear',
                          color: _red,
                          icon: AppIcons.closeRounded,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 200),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _ActionButton(
                    label: 'OK',
                    icon: AppIcons.checkRounded,
                    color: _green,
                    width: 170,
                    height: 70,
                    busy: _searching,
                    onTap: _ok,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: customer details ──────────────────────────────────────────────────

class _DetailsView extends StatefulWidget {
  final CustomerProfile customer;
  final Future<List<CustomerOrderSummary>> Function(String customerId)
  loadOrders;
  final Future<String> Function(CustomerProfile c) save;
  final VoidCallback onBack;
  final bool delivery;
  final void Function(String id, double charge, String address) onConfirm;

  const _DetailsView({
    super.key,
    required this.customer,
    required this.loadOrders,
    required this.save,
    required this.onBack,
    required this.delivery,
    required this.onConfirm,
  });

  @override
  State<_DetailsView> createState() => _DetailsViewState();
}

class _DetailsViewState extends State<_DetailsView> {
  bool _showOrders = false;
  bool _saving = false;
  late final CustomerProfile c = widget.customer;
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
    'charge': TextEditingController(),
  };
  Future<List<CustomerOrderSummary>>? _orders;

  @override
  void dispose() {
    for (final t in _ctrl.values) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_ctrl['phone']!.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Telephone #1 is required')));
      return;
    }
    if (widget.delivery && _ctrl['address']!.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Address is required')));
      return;
    }
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
    setState(() => _saving = true);
    try {
      final id = await widget.save(c);
      if (mounted) {
        final charge = double.tryParse(_ctrl['charge']!.text.trim()) ?? 0;
        final address = [c.address, c.city, c.postcode]
            .where((p) => p.trim().isNotEmpty)
            .map((p) => p.trim())
            .join(', ');
        widget.onConfirm(id, charge, address);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save customer: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = c.fullName;
    return Column(
      children: [
        _TabBar(
          children: [
            _TabButton(
              label: name.isEmpty ? 'NEW CUSTOMER' : name.toUpperCase(),
              icon: AppIcons.personRounded,
              active: !_showOrders,
              onTap: () => setState(() => _showOrders = false),
            ),
            if (c.id != null)
              _TabButton(
                label: 'ORDERS (${c.orders})',
                icon: AppIcons.receiptLongRounded,
                active: _showOrders,
                onTap: () => setState(() {
                  _showOrders = true;
                  _orders ??= widget.loadOrders(c.id!);
                }),
              ),
          ],
        ),
        Expanded(child: _showOrders ? _ordersList() : _form()),
        _BottomBar(
          children: [
            _ActionButton(
              label: 'BACK',
              icon: AppIcons.arrowBackRounded,
              color: _navy,
              onTap: widget.onBack,
            ),
            const Spacer(),
            _ActionButton(
              label: widget.delivery ? 'DELIVERY' : 'COLLECTION',
              icon: AppIcons.checkRounded,
              color: _green,
              width: 210,
              busy: _saving,
              onTap: _confirm,
            ),
          ],
        ),
      ],
    );
  }

  Widget _chargeField() => Align(
    alignment: Alignment.centerLeft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery charge',
          style: TextStyle(
            color: _label,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 180,
          child: TextField(
            controller: _ctrl['charge'],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: _fieldDecoration(hint: formatMoney(0)),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in const [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0])
              Material(
                color: const Color(0xFFF0AD4E),
                borderRadius: BorderRadius.circular(3),
                child: InkWell(
                  borderRadius: BorderRadius.circular(3),
                  onTap: () => _ctrl['charge']!.text = v == 0
                      ? '0'
                      : v.toStringAsFixed(2),
                  child: SizedBox(
                    width: 84,
                    height: 40,
                    child: Center(
                      child: Text(
                        v == 0 ? 'Free' : formatMoney(v),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _form() {
    Widget field(
      String label,
      String key, {
      int lines = 1,
      TextInputType? keyboard,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _label,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _ctrl[key],
            minLines: lines,
            maxLines: lines,
            keyboardType: keyboard,
            textCapitalization: key == 'postcode'
                ? TextCapitalization.characters
                : TextCapitalization.words,
            decoration: _fieldDecoration(),
          ),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                field('Telephone #1', 'phone', keyboard: TextInputType.phone),
                field('Telephone #2', 'phone2', keyboard: TextInputType.phone),
                field('Telephone #3', 'phone3', keyboard: TextInputType.phone),
                field('First Name', 'first'),
                field('Last Name', 'last'),
                field('Email', 'email', keyboard: TextInputType.emailAddress),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                field('Address', 'address', lines: 3),
                Row(
                  children: [
                    Expanded(child: field('City', 'city')),
                    const SizedBox(width: 16),
                    Expanded(child: field('Postcode', 'postcode')),
                  ],
                ),
                field('Comments', 'comments', lines: 3),
                if (widget.delivery) _chargeField(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ordersList() => FutureBuilder<List<CustomerOrderSummary>>(
    future: _orders,
    builder: (_, snap) {
      if (snap.hasError)
        return Center(child: Text('Could not load orders: ${snap.error}'));
      if (!snap.hasData)
        return const Center(child: CircularProgressIndicator());
      final list = snap.data!;
      if (list.isEmpty)
        return const Center(
          child: Text('No orders yet', style: TextStyle(color: _label)),
        );
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(40, 24, 40, 16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final o = list[i];
          return Material(
            color: Colors.white,
            elevation: 1,
            borderRadius: BorderRadius.circular(3),
            child: ListTile(
              title: Text(
                o.number,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                [
                  if (o.createdAt != null)
                    DateFormat('d MMM yyyy, h:mm a').format(o.createdAt!),
                  o.type,
                  o.status,
                ].join('  ·  '),
              ),
              trailing: Text(
                formatMoney(o.total),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          );
        },
      );
    },
  );
}

// ── Shared pieces ─────────────────────────────────────────────────────────────

InputDecoration _fieldDecoration({String? hint}) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: Colors.white,
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(3),
    borderSide: const BorderSide(color: Color(0xFFD1D9E2)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(3),
    borderSide: const BorderSide(color: Color(0xFFD1D9E2)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(3),
    borderSide: const BorderSide(color: _tabActive, width: 1.5),
  ),
);

class _TabBar extends StatelessWidget {
  final List<Widget> children;
  const _TabBar({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFD4D4D2),
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
    child: Row(
      children: [
        for (final c in children)
          Padding(padding: const EdgeInsets.only(right: 8), child: c),
      ],
    ),
  );
}

class _TabButton extends StatelessWidget {
  final String label;
  final AppIcon? icon;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({
    required this.label,
    this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : _label;
    return Material(
      color: active ? _tabActive : _panel,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 240,
          height: 52,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                SvgIcon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final List<Widget> children;
  const _BottomBar({required this.children});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
    child: Row(children: children),
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final AppIcon icon;
  final Color color;
  final double width;
  final double height;
  final bool busy;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.width = 150,
    this.height = 64,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    elevation: 3,
    borderRadius: BorderRadius.circular(3),
    child: InkWell(
      borderRadius: BorderRadius.circular(3),
      onTap: busy ? null : onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: busy
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgIcon(icon, size: 22, color: Colors.white),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}

/// Clock with the restaurant name, bottom-left like the till's status box.
class _ClockBrandBox extends StatefulWidget {
  const _ClockBrandBox();

  @override
  State<_ClockBrandBox> createState() => _ClockBrandBoxState();
}

class _ClockBrandBoxState extends State<_ClockBrandBox> {
  late final Timer _timer = Timer.periodic(
    const Duration(seconds: 15),
    (_) => setState(() {}),
  );

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    width: 150,
    height: 64,
    color: const Color(0xFF008B8B),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          DateFormat('h:mm a').format(DateTime.now()),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/branding/app_icon.svg',
              width: 18,
              height: 18,
            ),
            const SizedBox(width: 6),
            const Text(
              'PakAfghan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// White "Change" button: opens a small popup above it to switch to SHOP, DINE or DELIVERY.
class _ChangeSaleButton extends StatelessWidget {
  final ValueChanged<String> onPick;
  final bool delivery;
  _ChangeSaleButton({required this.onPick, this.delivery = false});

  final _key = GlobalKey();

  Future<void> _open(BuildContext context) async {
    final box = _key.currentContext!.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero);
    final screen = MediaQuery.of(context).size;
    final type = await showDialog<String>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        Widget option(String label, IconData icon, String type) => Material(
          color: Colors.white,
          elevation: 2,
          child: InkWell(
            onTap: () => Navigator.pop(ctx, type),
            child: Container(
              width: 140,
              height: 74,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCCCCCC)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 26, color: const Color(0xFF222222)),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF222222),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return Stack(
          children: [
            Positioned(
              left: origin.dx + box.size.width / 2 - 170,
              bottom: screen.height - origin.dy + 10,
              width: 340,
              child: Material(
                color: Colors.white,
                elevation: 8,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      option('SHOP', Icons.storefront_rounded, 'Takeaway'),
                      option('DINE', Icons.restaurant_rounded, 'Dine-in'),
                      if (delivery)
                        option(
                          'COLLECTION',
                          Icons.person_pin_rounded,
                          'Collection',
                        )
                      else
                        option(
                          'DELIVERY',
                          Icons.local_shipping_rounded,
                          'Delivery',
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    if (type != null) onPick(type);
  }

  @override
  Widget build(BuildContext context) => Material(
    key: _key,
    color: Colors.white,
    elevation: 3,
    borderRadius: BorderRadius.circular(3),
    child: InkWell(
      borderRadius: BorderRadius.circular(3),
      onTap: () => _open(context),
      child: const SizedBox(
        width: 230,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_upward_rounded,
              size: 20,
              color: Color(0xFF222222),
            ),
            SizedBox(height: 2),
            Text(
              'Change',
              style: TextStyle(color: Color(0xFF222222), fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}
