import 'package:flutter/material.dart';

/// Opens the quick calculator as a dialog.
Future<void> showCalculator(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const CalculatorDialog());

/// Simple till calculator: + - x / with a small history of finished sums.
class CalculatorDialog extends StatefulWidget {
  const CalculatorDialog({super.key});

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _entry = '';
  double? _acc;
  String? _op;
  bool _fresh = true; // next digit starts a new number
  final List<String> _history = [];

  static String _fmt(double v) {
    final s = v.toStringAsFixed(8);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  double get _current => double.tryParse(_entry) ?? 0;

  double _apply(double a, String op, double b) => switch (op) {
    '+' => a + b,
    '-' => a - b,
    'x' => a * b,
    _ => b == 0 ? double.nan : a / b,
  };

  void _digit(String d) => setState(() {
    if (_fresh) {
      _entry = d == '.' ? '0.' : d;
      _fresh = false;
    } else if (d == '.' ? !_entry.contains('.') : true) {
      _entry += d;
    }
  });

  void _operator(String op) => setState(() {
    if (_acc != null && _op != null && !_fresh) {
      _acc = _apply(_acc!, _op!, _current);
      _entry = _fmt(_acc!);
    } else {
      _acc = _current;
    }
    _op = op;
    _fresh = true;
  });

  void _equals() => setState(() {
    if (_acc == null || _op == null) return;
    final b = _current;
    final r = _apply(_acc!, _op!, b);
    if (r.isNaN) {
      _history.insert(0, '${_fmt(_acc!)} $_op ${_fmt(b)} = Error');
      _clear();
      _entry = 'Error';
      return;
    }
    _history.insert(0, '${_fmt(_acc!)} $_op ${_fmt(b)} = ${_fmt(r)}');
    _entry = _fmt(r);
    _acc = null;
    _op = null;
    _fresh = true;
  });

  void _clear() {
    _entry = '';
    _acc = null;
    _op = null;
    _fresh = true;
  }

  Widget _key(
    String label, {
    required VoidCallback onTap,
    Color color = Colors.white,
    Color fg = const Color(0xFF1F2937),
  }) => Material(
    color: color,
    elevation: 2,
    borderRadius: BorderRadius.circular(4),
    child: InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: fg,
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF4FC1E0);
    Widget digit(String d) => _key(d, onTap: () => _digit(d));
    Widget op(String o) =>
        _key(o, onTap: () => _operator(o), color: blue, fg: Colors.white);

    return Dialog(
      backgroundColor: const Color(0xFFF9FAF7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: SizedBox(
        width: 560,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Calculator',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 360,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 52,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDEFEA),
                                    border: Border.all(
                                      color: const Color(0xFFD1D5DB),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _entry.isEmpty ? '0' : _entry,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 80,
                                height: 52,
                                child: _key(
                                  'C',
                                  onTap: () => setState(_clear),
                                  color: const Color(0xFFF4A94E),
                                  fg: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 4,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                digit('7'), digit('8'), digit('9'), op('+'),
                                digit('4'), digit('5'), digit('6'), op('-'),
                                digit('1'), digit('2'), digit('3'), op('/'),
                                digit('0'),
                                digit('.'),
                                _key(
                                  '=',
                                  onTap: _equals,
                                  color: const Color(0xFF5CB85C),
                                  fg: Colors.white,
                                ),
                                op('x'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDEFEA),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ListView(
                          children: [
                            for (final h in _history)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  h,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
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
}
