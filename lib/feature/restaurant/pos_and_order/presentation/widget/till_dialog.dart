import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';

// Touch-till dialogs: square corners, navy title bar, big buttons and keypads.

const _navy = Color(0xFF22337A);
const _panel = Color(0xFFEEF2F6);
const _keyBlue = Color(0xFF3A8EE6);
const _red = Color(0xFFB5525A);
const _green = Color(0xFF4CA67A);
const _label = Color(0xFF4B5563);
const _selected = Color(0xFF2346B8);

/// Dialog frame: title bar, content, and a row of big buttons.
class TillDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget> actions;
  final double width;

  const TillDialog({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.width = 460,
  });

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: _panel,
    insetPadding: const EdgeInsets.all(24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 52,
            width: double.infinity,
            color: _navy,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: child,
            ),
          ),
          if (actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Row(
                children: [
                  for (final (i, a) in actions.indexed) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: a),
                  ],
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

/// Big coloured button used in till dialogs.
class TillButton extends StatelessWidget {
  final String label;
  final AppIcon? icon;
  final Color color;
  final Color textColor;
  final double height;
  final VoidCallback? onTap;

  const TillButton({
    super.key,
    required this.label,
    this.icon,
    this.color = _keyBlue,
    this.textColor = Colors.white,
    this.height = 60,
    this.onTap,
  });

  const TillButton.cancel({super.key, this.onTap})
    : label = 'CANCEL',
      icon = AppIcons.closeRounded,
      color = _red,
      textColor = Colors.white,
      height = 60;

  const TillButton.ok({super.key, this.label = 'OK', this.onTap})
    : icon = AppIcons.checkRounded,
      color = _green,
      textColor = Colors.white,
      height = 60;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    elevation: 2,
    borderRadius: BorderRadius.circular(3),
    child: InkWell(
      borderRadius: BorderRadius.circular(3),
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              SvgIcon(icon, size: 20, color: textColor),
              const SizedBox(height: 2),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
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

InputDecoration tillFieldDecoration([String? label]) => InputDecoration(
  labelText: label,
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
    borderSide: const BorderSide(color: _selected, width: 1.5),
  ),
);

/// Pick one option from a grid of big tiles.
Future<T?> showTillChoice<T>(
  BuildContext context,
  String title,
  List<(T, String)> options, {
  T? current,
}) => showDialog<T>(
  context: context,
  builder: (ctx) => TillDialog(
    title: title,
    width: options.length > 4 ? 560 : 460,
    actions: [TillButton.cancel(onTap: () => Navigator.pop(ctx))],
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (final o in options)
          SizedBox(
            width: 160,
            child: TillButton(
              label: o.$2,
              height: 70,
              color: o.$1 == current ? _selected : Colors.white,
              textColor: o.$1 == current ? Colors.white : _label,
              onTap: () => Navigator.pop(ctx, o.$1),
            ),
          ),
      ],
    ),
  ),
);

/// Yes / no question.
Future<bool> showTillConfirm(
  BuildContext context,
  String title,
  Widget message, {
  String okLabel = 'OK',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => TillDialog(
        title: title,
        actions: [
          TillButton.cancel(onTap: () => Navigator.pop(ctx, false)),
          TillButton.ok(label: okLabel, onTap: () => Navigator.pop(ctx, true)),
        ],
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: _label, fontSize: 15),
          textAlign: TextAlign.center,
          child: Center(child: message),
        ),
      ),
    ) ??
    false;

/// Text fields with CANCEL / OK; returns true on OK.
Future<bool> showTillForm(
  BuildContext context,
  String title,
  List<Widget> fields,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => TillDialog(
        title: title,
        actions: [
          TillButton.cancel(onTap: () => Navigator.pop(ctx, false)),
          TillButton.ok(onTap: () => Navigator.pop(ctx, true)),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, f) in fields.indexed) ...[
              if (i > 0) const SizedBox(height: 12),
              f,
            ],
          ],
        ),
      ),
    ) ??
    false;

/// Number entry with an on-screen keypad. Returns null on cancel.
Future<double?> showTillNumberPad(
  BuildContext context,
  String title, {
  String initial = '',
  bool decimal = true,
}) => showDialog<double>(
  context: context,
  builder: (_) =>
      _NumberPadDialog(title: title, initial: initial, decimal: decimal),
);

class _NumberPadDialog extends StatefulWidget {
  final String title;
  final String initial;
  final bool decimal;
  const _NumberPadDialog({
    required this.title,
    required this.initial,
    required this.decimal,
  });

  @override
  State<_NumberPadDialog> createState() => _NumberPadDialogState();
}

class _NumberPadDialogState extends State<_NumberPadDialog> {
  late final _ctrl = TextEditingController(text: widget.initial);
  // The first key press replaces the starting value instead of appending to it.
  bool _fresh = true;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _press(String key) {
    var t = _fresh ? '' : _ctrl.text;
    _fresh = false;
    if (key == 'back') {
      t = _ctrl.text.isEmpty
          ? ''
          : _ctrl.text.substring(0, _ctrl.text.length - 1);
    } else if (key == 'clear') {
      t = '';
    } else if (key == '.' && t.contains('.')) {
      return;
    } else {
      t += key;
    }
    setState(() => _ctrl.text = t);
  }

  void _ok() => Navigator.pop(context, double.tryParse(_ctrl.text) ?? 0);

  @override
  Widget build(BuildContext context) {
    Widget key(
      String label,
      String value, {
      Color color = _keyBlue,
      Color text = Colors.white,
      AppIcon? icon,
    }) => Padding(
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        width: 110,
        child: Material(
          color: color,
          elevation: 2,
          borderRadius: BorderRadius.circular(3),
          child: InkWell(
            borderRadius: BorderRadius.circular(3),
            onTap: () => _press(value),
            child: SizedBox(
              height: 58,
              child: Center(
                child: icon != null
                    ? SvgIcon(icon, size: 24, color: text)
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
      ),
    );

    return TillDialog(
      title: widget.title,
      width: 400,
      actions: [
        TillButton.cancel(onTap: () => Navigator.pop(context)),
        TillButton.ok(onTap: _ok),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(
              decimal: widget.decimal,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(widget.decimal ? r'[0-9.]' : r'[0-9]'),
              ),
            ],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            decoration: tillFieldDecoration(),
            onChanged: (_) => _fresh = false,
            onSubmitted: (_) => _ok(),
          ),
          const SizedBox(height: 10),
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
              widget.decimal
                  ? key('.', '.')
                  : key(
                      'Delete',
                      'back',
                      color: Colors.white,
                      text: _label,
                      icon: AppIcons.arrowBackRounded,
                    ),
              key('0', '0'),
              key('Clear', 'clear', color: _red, icon: AppIcons.closeRounded),
            ],
          ),
          if (widget.decimal)
            key(
              'Delete',
              'back',
              color: Colors.white,
              text: _label,
              icon: AppIcons.arrowBackRounded,
            ),
        ],
      ),
    );
  }
}
