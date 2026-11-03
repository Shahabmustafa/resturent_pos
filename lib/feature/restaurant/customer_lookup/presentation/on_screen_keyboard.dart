import 'package:flutter/material.dart';
import 'package:resturent_application/feature/restaurant/setup/pos_setup.dart';

const _keyColor = Color(0xFFFDFDFD);
const _actionKeyColor = Color(0xFFB8BEC8);

/// Phone-style touch keyboard that types into [controller].
/// Wrap it in a [TextFieldTapRegion] so tapping a key does not unfocus the field.
class OnScreenKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onChanged;
  final VoidCallback onEnter;

  /// Side padding; use a small value inside narrow dialogs.
  final double horizontalPadding;

  /// Opens on the number/symbol page (for phone and number fields).
  final bool startNumbers;

  const OnScreenKeyboard({
    super.key,
    required this.controller,
    required this.onEnter,
    this.onChanged,
    this.horizontalPadding = 80,
    this.startNumbers = false,
  });

  @override
  State<OnScreenKeyboard> createState() => _OnScreenKeyboardState();
}

class _OnScreenKeyboardState extends State<OnScreenKeyboard> {
  bool _shift = false;
  late bool _numbers = widget.startNumbers;

  static const _letters = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];
  static const _symbols = ['1234567890', '-/:;()£&@"', '.,?!\''];

  void _type(String s) {
    final c = widget.controller;
    c.value = TextEditingValue(
      text: c.text + s,
      selection: TextSelection.collapsed(offset: c.text.length + s.length),
    );
    if (_shift && !_numbers) setState(() => _shift = false);
    widget.onChanged?.call();
  }

  void _backspace() {
    final c = widget.controller;
    if (c.text.isEmpty) return;
    final t = c.text.substring(0, c.text.length - 1);
    c.value = TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
    widget.onChanged?.call();
  }

  Widget _key(
    Widget child,
    VoidCallback onTap, {
    int flex = 2,
    Color color = _keyColor,
  }) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: color,
        elevation: 1,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          canRequestFocus: false,
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: SizedBox(height: 50, child: Center(child: child)),
        ),
      ),
    ),
  );

  Widget _char(String ch) => _key(
    Text(
      _shift && !_numbers ? ch.toUpperCase() : ch,
      style: const TextStyle(fontSize: 20, color: Color(0xFF111111)),
    ),
    () => _type(_shift && !_numbers ? ch.toUpperCase() : ch),
  );

  @override
  Widget build(BuildContext context) {
    final rows = _numbers ? _symbols : _letters;
    return Container(
      color: const Color(0xFFD1D5DB),
      padding: EdgeInsets.symmetric(
        horizontal: widget.horizontalPadding,
        vertical: 6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [for (final ch in rows[0].split('')) _char(ch)]),
          Row(
            children: [
              const Spacer(flex: 1),
              for (final ch in rows[1].split('')) _char(ch),
              const Spacer(flex: 1),
            ],
          ),
          Row(
            children: [
              _key(
                Icon(
                  _numbers ? Icons.more_horiz : Icons.arrow_upward_rounded,
                  color: _shift ? Colors.blue : Colors.black87,
                ),
                () => setState(() => _shift = !_shift),
                flex: 3,
                color: _actionKeyColor,
              ),
              for (final ch in rows[2].split('')) _char(ch),
              _key(
                const Icon(Icons.backspace_outlined, color: Colors.black87),
                _backspace,
                flex: 3,
                color: _actionKeyColor,
              ),
            ],
          ),
          Row(
            children: [
              _key(
                Text(
                  _numbers ? 'ABC' : '123',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                () => setState(() => _numbers = !_numbers),
                flex: 3,
                color: _actionKeyColor,
              ),
              _key(
                const Text('space', style: TextStyle(fontSize: 16)),
                () => _type(' '),
                flex: 12,
              ),
              _key(
                const Icon(Icons.keyboard_return_rounded, color: Colors.white),
                widget.onEnter,
                flex: 3,
                color: const Color(0xFF2A75E6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shows the on-screen keyboard under [child] whenever a text field inside
/// [child] has focus (and the virtual keyboard is enabled in POS setup).
class KeyboardHost extends StatefulWidget {
  final Widget child;
  final double horizontalPadding;

  const KeyboardHost({
    super.key,
    required this.child,
    this.horizontalPadding = 80,
  });

  @override
  State<KeyboardHost> createState() => _KeyboardHostState();
}

class _KeyboardHostState extends State<KeyboardHost> {
  EditableTextState? _field;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocus);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    EditableTextState? found;
    if (ctx != null) {
      final f = ctx.findAncestorStateOfType<EditableTextState>();
      // Only react to fields that live inside this host.
      if (f != null &&
          f.context.findAncestorStateOfType<_KeyboardHostState>() == this) {
        found = f;
      }
    }
    if (found == _field) return;
    if (!mounted) return;
    setState(() => _field = found);
  }

  @override
  Widget build(BuildContext context) {
    final f = _field;
    final show =
        f != null && f.mounted && readPosSetup(context).virtualKeyboard;
    final type = f?.widget.keyboardType;
    final numeric =
        type == TextInputType.phone ||
        type == TextInputType.number ||
        (type?.index == 2); // number
    return Column(
      children: [
        Expanded(child: widget.child),
        if (show)
          TextFieldTapRegion(
            child: OnScreenKeyboard(
              key: ValueKey(f.widget.controller),
              controller: f.widget.controller,
              horizontalPadding: widget.horizontalPadding,
              startNumbers: numeric,
              onEnter: () => FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),
      ],
    );
  }
}
