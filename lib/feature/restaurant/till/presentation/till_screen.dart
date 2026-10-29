import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/constants/currency.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:resturent_application/feature/restaurant/cash_counter/presentation/cash_counter_provider.dart';
import 'package:resturent_application/feature/restaurant/live_orders/presentation/live_orders_screen.dart';

const _bg = Color(0xFFD4D4D2);

/// Open till: type an amount, then put cash IN to the drawer or take it OUT. With no
/// shift open, the green button opens the till with that amount as the opening cash.
/// Everything is stored through the cash counter (Supabase) functions.
class TillScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  // Full shift report and closing.
  final VoidCallback onCounter;
  const TillScreen({super.key, required this.onBack, required this.onCounter});

  @override
  ConsumerState<TillScreen> createState() => _TillScreenState();
}

class _TillScreenState extends ConsumerState<TillScreen> {
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  final _amountFocus = FocusNode();
  final _reasonFocus = FocusNode();
  bool _shift = false;
  String? _message;
  bool _messageIsError = false;

  // The keyboard types into whichever field was focused last.
  TextEditingController get _active =>
      _reasonFocus.hasFocus ? _reason : _amount;

  @override
  void initState() {
    super.initState();
    _amountFocus.requestFocus();
  }

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    _amountFocus.dispose();
    _reasonFocus.dispose();
    super.dispose();
  }

  void _type(String key) {
    final c = _active;
    if (c == _amount && !RegExp(r'^[0-9.]$').hasMatch(key)) return;
    final text = _shift ? key.toUpperCase() : key.toLowerCase();
    final sel = c.selection;
    final start = sel.isValid ? sel.start : c.text.length;
    final end = sel.isValid ? sel.end : c.text.length;
    c.value = TextEditingValue(
      text: c.text.replaceRange(start, end, text),
      selection: TextSelection.collapsed(offset: start + text.length),
    );
    if (_shift) setState(() => _shift = false);
  }

  void _backspace() {
    final c = _active;
    final sel = c.selection;
    if (!sel.isValid || c.text.isEmpty) return;
    if (!sel.isCollapsed) {
      c.value = TextEditingValue(
        text: c.text.replaceRange(sel.start, sel.end, ''),
        selection: TextSelection.collapsed(offset: sel.start),
      );
    } else if (sel.start > 0) {
      c.value = TextEditingValue(
        text: c.text.replaceRange(sel.start - 1, sel.start, ''),
        selection: TextSelection.collapsed(offset: sel.start - 1),
      );
    }
  }

  void _clear() {
    _amount.clear();
    _reason.clear();
    setState(() => _message = null);
  }

  Future<void> _submit({required bool isIn}) async {
    final amount = double.tryParse(_amount.text.trim());
    final notifier = ref.read(cashCounterProvider.notifier);
    final isOpen = ref.read(cashCounterProvider).open != null;

    String? problem;
    if (amount == null) {
      problem = 'Enter an amount';
    } else if (isOpen && amount <= 0) {
      problem = 'Amount must be more than 0';
    }
    if (problem != null) {
      setState(() {
        _message = problem;
        _messageIsError = true;
      });
      return;
    }

    final ok = isOpen
        ? await notifier.addEntry(
            isIn: isIn,
            amount: amount!,
            reason: _reason.text.trim(),
          )
        : await notifier.openCounter(amount!);
    if (!mounted) return;
    final error = ref.read(cashCounterProvider).error;
    setState(() {
      _messageIsError = !ok;
      _message = !ok
          ? (error ?? 'Could not save')
          : !isOpen
          ? 'Till opened with ${formatMoney(amount)}'
          : isIn
          ? '${formatMoney(amount)} added to the till'
          : '${formatMoney(amount)} taken out of the till';
    });
    if (ok) {
      _amount.clear();
      _reason.clear();
    } else {
      notifier.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(cashCounterProvider);
    final isOpen = s.open != null;

    return Container(
      color: _bg,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 830,
                decoration: const BoxDecoration(color: Color(0xFFE4E4E2)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      color: const Color(0xFFF7F7F7),
                      height: 80,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Center(
                              child: Text(
                                'OPEN TILL',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          Tooltip(
                            message: 'Shift report and closing',
                            child: Material(
                              color: const Color(0xFFF0AD4E),
                              borderRadius: BorderRadius.circular(3),
                              child: InkWell(
                                onTap: widget.onCounter,
                                child: const SizedBox(
                                  width: 58,
                                  height: 52,
                                  child: Center(
                                    child: SvgIcon(
                                      AppIcons.lockOutlineRounded,
                                      size: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
                      child: Column(
                        children: [
                          Text(
                            s.loading
                                ? 'Loading...'
                                : isOpen
                                ? 'Till open since ${DateFormat('h:mm a').format(s.open!.openedAt.toLocal())}  ·  Expected cash ${formatMoney(s.summary.expectedCash)}'
                                : 'Till is closed. Enter the opening cash and press OPEN',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 256,
                            height: 64,
                            child: TextField(
                              controller: _amount,
                              focusNode: _amountFocus,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'),
                                ),
                              ],
                              style: const TextStyle(fontSize: 20),
                              decoration: InputDecoration(
                                hintText: '0',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF3730A3),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (isOpen) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: 400,
                              child: TextField(
                                controller: _reason,
                                focusNode: _reasonFocus,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: 'Reason (optional)',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 20,
                            child: _message == null
                                ? null
                                : Text(
                                    _message!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _messageIsError
                                          ? const Color(0xFFB91C1C)
                                          : const Color(0xFF15803D),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _ActionButton(
                                label: 'VOID',
                                color: const Color(0xFF5BC0DE),
                                icon: AppIcons.pointOfSaleRounded,
                                onTap: s.busy ? null : _clear,
                              ),
                              const SizedBox(width: 10),
                              _ActionButton(
                                label: 'OUT',
                                color: const Color(0xFFD9534F),
                                icon: AppIcons.removeRounded,
                                onTap: s.busy || !isOpen
                                    ? null
                                    : () => _submit(isIn: false),
                              ),
                              const Spacer(),
                              _ActionButton(
                                label: isOpen ? 'IN' : 'OPEN',
                                color: const Color(0xFF5CB85C),
                                icon: AppIcons.addRounded,
                                onTap: s.busy || s.loading
                                    ? null
                                    : () => _submit(isIn: true),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _OnScreenKeyboard(
            shift: _shift,
            onKey: _type,
            onBackspace: _backspace,
            onClear: _clear,
            onShift: () => setState(() => _shift = !_shift),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Row(
              children: [
                const TimeBox(),
                const SizedBox(width: 10),
                Material(
                  color: Colors.black,
                  elevation: 4,
                  borderRadius: BorderRadius.circular(3),
                  child: InkWell(
                    onTap: widget.onBack,
                    child: const SizedBox(
                      width: 230,
                      height: 80,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgIcon(
                            AppIcons.arrowBackRounded,
                            size: 28,
                            color: Colors.white,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Back',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final AppIcon icon;
  final VoidCallback? onTap;
  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onTap == null ? 0.45 : 1,
    child: Material(
      color: color,
      elevation: 3,
      borderRadius: BorderRadius.circular(3),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 146,
          height: 86,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgIcon(icon, size: 26, color: Colors.white),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Touch keyboard on a black tray, laid out like the reference POS.
class _OnScreenKeyboard extends StatelessWidget {
  final bool shift;
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onShift;
  const _OnScreenKeyboard({
    required this.shift,
    required this.onKey,
    required this.onBackspace,
    required this.onClear,
    required this.onShift,
  });

  @override
  Widget build(BuildContext context) {
    Widget key(
      String label, {
      int flex = 2,
      VoidCallback? onTap,
      bool active = false,
    }) => Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: active ? const Color(0xFFBFDBFE) : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(3),
          child: InkWell(
            canRequestFocus: false,
            onTap: onTap ?? () => onKey(label),
            child: SizedBox(
              height: 52,
              child: Center(
                child: Text(
                  shift || label.length > 1 ? label : label.toLowerCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    List<Widget> letters(String chars) => [
      for (final c in chars.split('')) key(c),
    ];

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ...[for (final c in '[]0123456789'.split('')) key(c)],
              key('Bksp', flex: 4, onTap: onBackspace),
            ],
          ),
          Row(
            children: [
              key('@'),
              ...letters('QWERTYUIOP'),
              key('del', flex: 6, onTap: onClear),
            ],
          ),
          Row(
            children: [
              key('Shift', flex: 3, onTap: onShift, active: shift),
              ...letters('ASDFGHJKL'),
              key(';'),
              key("'"),
              key('Enter', flex: 3, onTap: () {}),
            ],
          ),
          Row(
            children: [
              key('? Tab', flex: 3, onTap: () {}),
              ...letters('ZXCVBNM'),
              key(','),
              key('.'),
              key(' ', flex: 6),
            ],
          ),
        ],
      ),
    );
  }
}
