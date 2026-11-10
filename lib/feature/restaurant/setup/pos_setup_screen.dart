import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:resturent_application/feature/restaurant/live_orders/presentation/live_orders_screen.dart';
import 'package:resturent_application/feature/restaurant/setting/presentation/provider/branch_setting_provider.dart';
import 'package:resturent_application/feature/restaurant/setting/presentation/screen/receipt_tab.dart';
import 'pos_setup.dart';

const _bg = Color(0xFFD4D4D2);
const _purple = Color(0xFF9B51C0);

/// POS system setup: General, Print and Display tabs, saved on this computer.
class PosSetupScreen extends ConsumerStatefulWidget {
  final String systemName;
  final VoidCallback onBack;

  const PosSetupScreen({
    super.key,
    required this.systemName,
    required this.onBack,
  });

  @override
  ConsumerState<PosSetupScreen> createState() => _PosSetupScreenState();
}

class _PosSetupScreenState extends ConsumerState<PosSetupScreen> {
  int _tab = 0;
  late PosSetup _s = ref.read(posSetupProvider);
  final _text = <String, TextEditingController>{};
  List<Printer> _printers = const [];

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPrinters() async {
    try {
      final list = await Printing.listPrinters();
      if (mounted) setState(() => _printers = list);
    } catch (_) {
      // No printer list on this platform.
    }
  }

  TextEditingController _ctrl(String key, String value) =>
      _text.putIfAbsent(key, () => TextEditingController(text: value));

  int _int(String key, int fallback) =>
      int.tryParse(_text[key]?.text.trim() ?? '') ?? fallback;

  Future<void> _save() async {
    final s = _s;
    final next = PosSetup(
      virtualKeyboard: s.virtualKeyboard,
      zoom: _int('zoom', s.zoom).clamp(50, 200),
      orderSound: s.orderSound,
      orderTypes: s.orderTypes,
      payMethods: s.payMethods,
      menuBackground: (_text['bg']?.text ?? s.menuBackground).trim(),
      productWidth: _int('pw', s.productWidth).clamp(60, 400),
      productHeight: _int('ph', s.productHeight).clamp(40, 300),
      categoryWidth: _int('cw', s.categoryWidth).clamp(60, 400),
      categoryHeight: _int('ch', s.categoryHeight).clamp(30, 200),
      productFont: _int('pf', s.productFont).clamp(8, 30),
      categoryFont: _int('cf', s.categoryFont).clamp(8, 30),
      nameOnly: s.nameOnly,
      onlinePopup: s.onlinePopup,
      cartWidth: _int('cartw', s.cartWidth).clamp(280, 700),
      postcodesPerPage: _int('pcpp', s.postcodesPerPage).clamp(5, 100),
      customersPerPage: _int('cupp', s.customersPerPage).clamp(5, 100),
      printerName: s.printerName,
      printerUrl: s.printerUrl,
    );
    await ref.read(posSetupProvider.notifier).save(next);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved')));
    widget.onBack();
  }

  void _set(PosSetup s) => setState(() => _s = s);

  PosSetup _copy({
    bool? virtualKeyboard,
    bool? orderSound,
    Set<String>? orderTypes,
    Set<String>? payMethods,
    bool? nameOnly,
    bool? onlinePopup,
    String? printerName,
    String? printerUrl,
  }) => PosSetup(
    virtualKeyboard: virtualKeyboard ?? _s.virtualKeyboard,
    zoom: _s.zoom,
    orderSound: orderSound ?? _s.orderSound,
    orderTypes: orderTypes ?? _s.orderTypes,
    payMethods: payMethods ?? _s.payMethods,
    menuBackground: _s.menuBackground,
    productWidth: _s.productWidth,
    productHeight: _s.productHeight,
    categoryWidth: _s.categoryWidth,
    categoryHeight: _s.categoryHeight,
    productFont: _s.productFont,
    categoryFont: _s.categoryFont,
    nameOnly: nameOnly ?? _s.nameOnly,
    onlinePopup: onlinePopup ?? _s.onlinePopup,
    cartWidth: _s.cartWidth,
    postcodesPerPage: _s.postcodesPerPage,
    customersPerPage: _s.customersPerPage,
    printerName: printerName ?? _s.printerName,
    printerUrl: printerUrl ?? _s.printerUrl,
  );

  Widget _yesNo(String label, bool value, ValueChanged<bool> onChanged) => Row(
    children: [
      SizedBox(width: 230, child: Text(label)),
      Radio<bool>(
        value: true,
        groupValue: value,
        onChanged: (v) => onChanged(true),
      ),
      const Text('Yes'),
      const SizedBox(width: 12),
      Radio<bool>(
        value: false,
        groupValue: value,
        onChanged: (v) => onChanged(false),
      ),
      const Text('No'),
    ],
  );

  Widget _number(String label, String key, int value) => SizedBox(
    width: 220,
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        SizedBox(
          width: 70,
          child: TextField(
            controller: _ctrl(key, '$value'),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _check(
    String label,
    String id,
    Set<String> set,
    ValueChanged<Set<String>> onChanged,
  ) => SizedBox(
    width: 200,
    child: CheckboxListTile(
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: set.contains(id),
      onChanged: (v) =>
          onChanged(v == true ? {...set, id} : ({...set}..remove(id))),
    ),
  );

  Widget _box(String title, Widget child) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE2E2E2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFFF6F6F6),
          padding: const EdgeInsets.all(12),
          child: Text(title, style: const TextStyle(fontSize: 16)),
        ),
        Padding(padding: const EdgeInsets.all(14), child: child),
      ],
    ),
  );

  Widget _general() => SingleChildScrollView(
    padding: const EdgeInsets.all(10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _box(
            'GENERAL',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _yesNo(
                  'Virtual Keyboard',
                  _s.virtualKeyboard,
                  (v) => _set(_copy(virtualKeyboard: v)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(width: 230, child: Text('Zoom (%)')),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: _ctrl('zoom', '${_s.zoom}'),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _yesNo(
                  'Sound on new online order',
                  _s.orderSound,
                  (v) => _set(_copy(orderSound: v)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              _box(
                'Delivery Methods',
                Wrap(
                  children: [
                    for (final (id, label) in const [
                      ('carry', 'Carry'),
                      ('dine', 'Dine'),
                      ('collection', 'Collection'),
                      ('delivery', 'Home Delivery'),
                    ])
                      _check(
                        label,
                        id,
                        _s.orderTypes,
                        (v) => _set(_copy(orderTypes: v)),
                      ),
                  ],
                ),
              ),
              _box('Opening Hours', const _OpeningHoursForm()),
              _box('Delivery Charges', const _DeliveryChargeForm()),
              _box(
                'Payment Methods',
                Wrap(
                  children: [
                    for (final (id, label) in const [
                      ('cash', 'Cash'),
                      ('card', 'Card payment'),
                      ('cashDue', 'Cash On Delivery'),
                    ])
                      _check(
                        label,
                        id,
                        _s.payMethods,
                        (v) => _set(_copy(payMethods: v)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _print() => SingleChildScrollView(
    padding: const EdgeInsets.all(10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _printerList()),
        const SizedBox(width: 10),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Invoice preview',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const LiveReceiptPreview(),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _printerList() => _box(
    'Printers',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Receipts print straight to the ticked printer. With none ticked, the thermal or default printer is used automatically.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 8),
        if (_printers.isEmpty)
          const Text('No printers found on this computer.')
        else
          for (final p in _printers)
            CheckboxListTile(
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(p.name),
              value: _s.printerUrl == p.url,
              onChanged: (v) => _set(
                _copy(
                  printerName: v == true ? p.name : '',
                  printerUrl: v == true ? p.url : '',
                ),
              ),
            ),
      ],
    ),
  );

  Widget _display() => SingleChildScrollView(
    padding: const EdgeInsets.all(14),
    child: Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _yesNo(
            'Show menu item names only (hide price)',
            _s.nameOnly,
            (v) => _set(_copy(nameOnly: v)),
          ),
          const SizedBox(height: 8),
          _yesNo(
            'Show Online Order Popup',
            _s.onlinePopup,
            (v) => _set(_copy(onlinePopup: v)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 30,
            runSpacing: 14,
            children: [
              _number('Product Button Width', 'pw', _s.productWidth),
              _number('Product Button Height', 'ph', _s.productHeight),
              _number('Product Button Font Size', 'pf', _s.productFont),
              _number('Category Button Width', 'cw', _s.categoryWidth),
              _number('Category Button Height', 'ch', _s.categoryHeight),
              _number('Category Button Font Size', 'cf', _s.categoryFont),
              _number('Cart Width', 'cartw', _s.cartWidth),
              _number(
                'Postcodes / Streets per Page',
                'pcpp',
                _s.postcodesPerPage,
              ),
              _number('Customers per Page', 'cupp', _s.customersPerPage),
              SizedBox(
                width: 260,
                child: Row(
                  children: [
                    const Expanded(child: Text('Menu Background')),
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: _ctrl('bg', _s.menuBackground),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _tabButton(int i, String label, AppIcon icon) {
    final on = _tab == i;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => setState(() => _tab = i),
        child: Container(
          width: 230,
          height: 56,
          decoration: BoxDecoration(
            color: on ? const Color(0xFFEDEDED) : Colors.white,
            border: Border.all(
              color: on ? Colors.black : _purple,
              width: on ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgIcon(icon, size: 24, color: _purple),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(color: _purple, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barButton(
    String label,
    AppIcon icon,
    Color color,
    VoidCallback onTap, {
    Color background = Colors.white,
  }) => Material(
    color: background,
    elevation: 3,
    borderRadius: BorderRadius.circular(3),
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 190,
        height: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgIcon(icon, size: 26, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Container(
    color: _bg,
    child: Column(
      children: [
        Container(
          color: const Color(0xFFF6F6F6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Text('POS SYSTEM SETUP', style: TextStyle(fontSize: 16)),
              const Spacer(),
              Text(
                widget.systemName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Container(
          color: const Color(0xFFF6F6F6),
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
          child: Row(
            children: [
              _tabButton(0, 'General', AppIcons.settingsRounded),
              _tabButton(1, 'Print', AppIcons.receiptLongRounded),
              _tabButton(2, 'Display', AppIcons.tuneRounded),
            ],
          ),
        ),
        Expanded(
          child: switch (_tab) {
            0 => _general(),
            1 => _print(),
            _ => _display(),
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
          child: Row(
            children: [
              const TimeBox(),
              const SizedBox(width: 10),
              _barButton(
                'Cancel',
                AppIcons.closeRounded,
                Colors.white,
                widget.onBack,
                background: Colors.black,
              ),
              const Spacer(),
              _barButton(
                'Save',
                AppIcons.checkRounded,
                Colors.white,
                _save,
                background: const Color(0xFF5CB85C),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Restaurant postcode and flat delivery charge, saved to the branch record.
class _DeliveryChargeForm extends ConsumerStatefulWidget {
  const _DeliveryChargeForm();

  @override
  ConsumerState<_DeliveryChargeForm> createState() =>
      _DeliveryChargeFormState();
}

class _DeliveryChargeFormState extends ConsumerState<_DeliveryChargeForm> {
  final _postcode = TextEditingController();
  final _fee = TextEditingController();
  bool _filled = false;

  @override
  void dispose() {
    _postcode.dispose();
    _fee.dispose();
    super.dispose();
  }

  void _save() {
    final branch = ref.read(branchSettingsProvider).branch;
    if (branch == null) return;
    final fee = double.tryParse(_fee.text.trim());
    if (fee == null || fee < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid delivery charge, e.g. 2.50'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    ref
        .read(branchSettingsProvider.notifier)
        .save(
          branch.copyWith(
            deliveryFee: (fee * 100).round() / 100,
            deliveryPostcode: _postcode.text.trim().toUpperCase(),
          ),
        );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Delivery charges saved')));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(branchSettingsProvider);
    final branch = state.branch;
    if (branch != null && !_filled) {
      _filled = true;
      _postcode.text = branch.deliveryPostcode;
      _fee.text = branch.deliveryFee.toStringAsFixed(2);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Website delivery: up to 3 miles £5, up to 5 miles £8, up to 7 miles £10. '
          'The distance is measured from the restaurant postcode.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _postcode,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Restaurant postcode',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _fee,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Flat delivery charge for POS orders (£)',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: branch == null || state.saving ? null : _save,
          child: Text(state.saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}

/// Opening and closing time (or open 24 hours), saved to the branch record.
class _OpeningHoursForm extends ConsumerStatefulWidget {
  const _OpeningHoursForm();

  @override
  ConsumerState<_OpeningHoursForm> createState() => _OpeningHoursFormState();
}

class _OpeningHoursFormState extends ConsumerState<_OpeningHoursForm> {
  final _open = TextEditingController();
  final _close = TextEditingController();
  bool _is24 = false;
  bool _filled = false;

  @override
  void dispose() {
    _open.dispose();
    _close.dispose();
    super.dispose();
  }

  void _save() {
    final branch = ref.read(branchSettingsProvider).branch;
    if (branch == null) return;
    ref
        .read(branchSettingsProvider.notifier)
        .save(
          branch.copyWith(
            openingTime: _open.text.trim(),
            closingTime: _close.text.trim(),
            is24Hours: _is24,
          ),
        );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening hours saved')));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(branchSettingsProvider);
    final branch = state.branch;
    if (branch != null && !_filled) {
      _filled = true;
      _open.text = branch.openingTime;
      _close.text = branch.closingTime;
      _is24 = branch.is24Hours;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Open 24 hours'),
          value: _is24,
          onChanged: (v) => setState(() => _is24 = v ?? false),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _open,
                enabled: !_is24,
                decoration: const InputDecoration(
                  labelText: 'Opening time (e.g. 11:00 AM)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _close,
                enabled: !_is24,
                decoration: const InputDecoration(
                  labelText: 'Closing time (e.g. 11:30 PM)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: branch == null || state.saving ? null : _save,
          child: Text(state.saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}
