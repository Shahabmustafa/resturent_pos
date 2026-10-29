import 'package:flutter/material.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/constants/currency.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import '../provider/pos_provider.dart';

const _bg = Color(0xFF10527A);
const _teal = Color(0xFF138FA3);
const _noteGreen = Color(0xFF0BA67F);
const _coinOrange = Color(0xFFFF7A00);
const _purple = Color(0xFF9B51C0);
const _payGreen = Color(0xFF3FB618);
const _rightBg = Color(0xFFD6D6D2);

enum PayMode { cash, card, onDelivery }

/// What the till decided on this screen.
class PaymentResult {
  /// `Cash` or `Card`; ignored when the order is left unpaid.
  final String method;
  final bool paid;

  /// Cash given by the customer minus the total (0 for card / unpaid).
  final double change;
  const PaymentResult({
    required this.method,
    required this.paid,
    this.change = 0,
  });
}

/// Take payment for the sale: cash (with change), card, or pay on delivery.
/// Pops with a [PaymentResult], or null on Back.
class PaymentScreen extends StatefulWidget {
  final PosState sale;
  const PaymentScreen({super.key, required this.sale});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PayMode _mode = PayMode.cash;
  String _entry = '';

  PosState get _s => widget.sale;
  double get _total => _s.total;
  double get _given => double.tryParse(_entry) ?? 0;
  bool get _delivery => _s.orderType == 'Delivery';

  String _fmt(double v) => v.toStringAsFixed(2);

  void _press(String key) => setState(() {
    if (key == 'c') {
      _entry = '';
    } else if (key == '.') {
      if (!_entry.contains('.')) _entry = _entry.isEmpty ? '0.' : '$_entry.';
    } else {
      final dot = _entry.indexOf('.');
      if (dot < 0 || _entry.length - dot <= 2) _entry += key;
    }
  });

  void _add(double v) => setState(() => _entry = _fmt(_given + v));

  void _finish({required bool paid, String method = 'Cash'}) {
    if (paid && method == 'Cash' && _given + 0.001 < _total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cash given is less than the amount due')),
      );
      return;
    }
    Navigator.pop(
      context,
      PaymentResult(
        method: method,
        paid: paid,
        change: paid && method == 'Cash' ? _given - _total : 0,
      ),
    );
  }

  void _confirm() => switch (_mode) {
    PayMode.cash => _finish(paid: true),
    PayMode.card => _finish(paid: true, method: 'Card'),
    PayMode.onDelivery => _finish(paid: false),
  };

  Widget _padKey(
    String label,
    Color color,
    VoidCallback onTap, {
    Color text = Colors.white,
    double width = 100,
  }) => Padding(
    padding: const EdgeInsets.all(5),
    child: Material(
      color: color,
      elevation: 3,
      borderRadius: BorderRadius.circular(3),
      child: InkWell(
        borderRadius: BorderRadius.circular(3),
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: 74,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: text,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _bigButton(
    String label,
    Color color,
    VoidCallback onTap, {
    AppIcon? icon,
    double width = 190,
    double height = 80,
    Color text = Colors.white,
  }) => Material(
    color: color,
    elevation: 3,
    borderRadius: BorderRadius.circular(3),
    child: InkWell(
      borderRadius: BorderRadius.circular(3),
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              SvgIcon(icon, size: 26, color: text),
              const SizedBox(height: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: text,
                fontSize: icon != null ? 13 : 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _modeTab(String label, AppIcon icon, PayMode mode) {
    final on = _mode == mode;
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: _bigButton(
        label,
        on ? _purple : Colors.white,
        () => setState(() => _mode = mode),
        icon: icon,
        width: 218,
        height: 88,
        text: on ? Colors.white : _purple,
      ),
    );
  }

  Widget _cashPanel() {
    final change = _given - _total;
    return Column(
      children: [
        const SizedBox(height: 18),
        SizedBox(
          width: 424,
          child: Row(
            children: [
              Container(
                width: 66,
                height: 66,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(4),
                  ),
                ),
                child: const Text('C', style: TextStyle(fontSize: 22)),
              ),
              Expanded(
                child: Container(
                  height: 66,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: const Color(0xFFEFF0EC),
                  child: Text(
                    _entry,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 24,
          child: _given > 0 && change >= 0
              ? Text(
                  'Change ${formatMoney(change)}',
                  style: const TextStyle(
                    color: _payGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  for (final row in const [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                  ])
                    Row(
                      children: [
                        for (final d in row) _padKey(d, _teal, () => _press(d)),
                      ],
                    ),
                  Row(
                    children: [
                      _padKey('.', _teal, () => _press('.')),
                      _padKey('0', _teal, () => _press('0')),
                      _padKey(
                        'c',
                        Colors.white,
                        () => _press('c'),
                        text: Colors.black87,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 60),
              Column(
                children: [
                  for (final row in const [
                    [1.0, 2.0, 5.0],
                    [10.0, 20.0, 50.0],
                  ])
                    Row(
                      children: [
                        for (final n in row)
                          _padKey(
                            n.toStringAsFixed(0),
                            _noteGreen,
                            () => _add(n),
                          ),
                      ],
                    ),
                  for (final row in const [
                    [1, 2, 5],
                    [10, 20, 50],
                  ])
                    Row(
                      children: [
                        for (final p in row)
                          _padKey('${p}p', _coinOrange, () => _add(p / 100)),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              _bigButton(
                'Exact Pay',
                _purple,
                () => setState(() => _entry = _fmt(_total)),
                width: 200,
                height: 80,
              ),
              const Spacer(),
              _bigButton(
                'Pay',
                _payGreen,
                _confirm,
                icon: AppIcons.checkRounded,
                width: 200,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _messagePanel(String message, String button, VoidCallback onTap) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, color: Colors.black54),
          ),
          const SizedBox(height: 30),
          _bigButton(
            button,
            _payGreen,
            onTap,
            icon: AppIcons.checkRounded,
            width: 220,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final title = switch (_mode) {
      PayMode.cash => 'Cash',
      PayMode.card => 'Card payment',
      PayMode.onDelivery => 'Cash On Delivery',
    };
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      color: _bg,
                      padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              color: const Color(0xFFFEFEFC),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      18,
                                      24,
                                      14,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                        const Spacer(),
                                        const Text(
                                          'TO PAY',
                                          style: TextStyle(
                                            fontSize: 34,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          _fmt(_total),
                                          style: const TextStyle(
                                            fontSize: 34,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  Expanded(
                                    child: switch (_mode) {
                                      PayMode.cash => _cashPanel(),
                                      PayMode.card => _messagePanel(
                                        'Take the card payment on the card machine, then press Pay.',
                                        'Pay',
                                        _confirm,
                                      ),
                                      PayMode.onDelivery => _messagePanel(
                                        'The customer pays the rider on delivery. The order is saved as unpaid.',
                                        'Confirm',
                                        _confirm,
                                      ),
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  if (_delivery)
                                    _modeTab(
                                      'Cash On Delivery',
                                      AppIcons.localShippingRounded,
                                      PayMode.onDelivery,
                                    ),
                                  _modeTab(
                                    'Card payment',
                                    AppIcons.paymentsRounded,
                                    PayMode.card,
                                  ),
                                  _modeTab(
                                    'Cash',
                                    AppIcons.paymentsRounded,
                                    PayMode.cash,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 640, child: _summary()),
                ],
              ),
            ),
            Container(
              color: _rightBg,
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  _bigButton(
                    'Back',
                    Colors.black,
                    () => Navigator.pop(context),
                    icon: AppIcons.arrowBackRounded,
                    width: 230,
                    height: 76,
                  ),
                  const Spacer(),
                  _bigButton(
                    'HOLD',
                    _coinOrange,
                    () => _finish(paid: false),
                    icon: AppIcons.checkRounded,
                    width: 230,
                    height: 76,
                  ),
                  const SizedBox(width: 8),
                  _bigButton(
                    'Confirm',
                    _payGreen,
                    _confirm,
                    icon: AppIcons.checkRounded,
                    width: 230,
                    height: 76,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary() {
    final s = _s;
    final header = switch (s.orderType) {
      'Dine-in' =>
        s.selectedTable.isEmpty ? 'DINE' : 'DINE T${s.selectedTable}',
      'Delivery' => 'DELIVERY',
      _ => s.isShop ? 'SHOP' : 'COLLECTION',
    };
    final name = s.customerName.trim();
    Widget row(String l, String r, {bool bold = false, Color? bg, Color? fg}) =>
        Container(
          color: bg ?? Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Text(
                l,
                style: TextStyle(
                  color: fg,
                  fontSize: 17,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              const Spacer(),
              Text(
                r,
                style: TextStyle(
                  color: fg,
                  fontSize: 17,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
    return Container(
      color: _rightBg,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: _purple,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              header,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 100,
            color: const Color(0xFF7FFFD4),
            padding: const EdgeInsets.all(8),
            child: Text(
              [
                if (name.isNotEmpty) name.toUpperCase(),
                if (s.customerPhone.trim().isNotEmpty) s.customerPhone.trim(),
                if (s.orderType == 'Delivery' &&
                    s.deliveryAddress.trim().isNotEmpty)
                  s.deliveryAddress.trim(),
              ].join('\n'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          const SizedBox(height: 6),
          row('Total Items', '${s.cart.fold<int>(0, (a, c) => a + c.qty)}'),
          row(
            'Total Amount',
            _fmt(_total),
            bold: true,
            bg: const Color(0xFF00A676),
            fg: Colors.white,
          ),
          row('Sub Total', _fmt(s.subtotal)),
          if (s.discountAmt > 0) row('Discount', '-${_fmt(s.discountAmt)}'),
          if (s.tax > 0) row('Tax', _fmt(s.tax)),
          if (s.fee > 0) row('Delivery', _fmt(s.fee)),
        ],
      ),
    );
  }
}
