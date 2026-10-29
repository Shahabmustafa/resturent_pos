import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resturent_application/core/constants/currency.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/feature/restaurant/customer_lookup/presentation/on_screen_keyboard.dart';
import '../widget/till_dialog.dart';

const _bg = Color(0xFF10527A);
const _keyRed = Color(0xFFD9534F);
const _keyOrange = Color(0xFFF0AD4E);
const _panel = Color(0xFFF3F3F3);
const _prefsKey = 'adhoc_products';

/// One-off item that is not on the menu: a name and a price typed at the till.
/// Saved items are listed on the left and never go to the menu; tap one to add it.
/// Pops with `(name, price)`, or null when cancelled.
class AdhocScreen extends StatefulWidget {
  const AdhocScreen({super.key});

  @override
  State<AdhocScreen> createState() => _AdhocScreenState();
}

class _AdhocScreenState extends State<AdhocScreen> {
  final _name = TextEditingController();
  final _focus = FocusNode();
  String _price = '';
  List<(String, double)> _saved = [];

  Future<void> _load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_prefsKey);
    if (raw == null || !mounted) return;
    setState(
      () => _saved = [
        for (final m in jsonDecode(raw) as List)
          ((m['name'] as String), (m['price'] as num).toDouble()),
      ],
    );
  }

  Future<void> _store() async =>
      (await SharedPreferences.getInstance()).setString(
        _prefsKey,
        jsonEncode([
          for (final i in _saved) {'name': i.$1, 'price': i.$2},
        ]),
      );

  Future<void> _remove((String, double) item) async {
    final ok = await showTillConfirm(
      context,
      'Remove item',
      Text('Remove ${item.$1} from this list?'),
      okLabel: 'REMOVE',
    );
    if (!ok || !mounted) return;
    setState(() => _saved.remove(item));
    await _store();
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _press(String key) => setState(() {
    if (key == 'c') {
      _price = '';
    } else if (key == '.') {
      if (!_price.contains('.')) _price = _price.isEmpty ? '0.' : '$_price.';
    } else {
      final dot = _price.indexOf('.');
      if (dot < 0 || _price.length - dot <= 2) _price += key;
    }
  });

  Future<void> _ok() async {
    final price = double.tryParse(_price);
    if (_name.text.trim().isEmpty || price == null || price <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a name and a price')));
      return;
    }
    final item = (_name.text.trim(), price);
    if (!_saved.contains(item)) {
      _saved.add(item);
      await _store();
    }
    if (mounted) Navigator.pop(context, item);
  }

  Widget _key(String label, Color color, {Color text = Colors.white}) =>
      Padding(
        padding: const EdgeInsets.all(5),
        child: Material(
          color: color,
          elevation: 3,
          borderRadius: BorderRadius.circular(3),
          child: InkWell(
            borderRadius: BorderRadius.circular(3),
            onTap: () => _press(label),
            child: SizedBox(
              width: 110,
              height: 52,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: text,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _tile((String, double) i) => Material(
    color: const Color(0xFF6A3FB5),
    elevation: 3,
    borderRadius: BorderRadius.circular(3),
    child: InkWell(
      borderRadius: BorderRadius.circular(3),
      onTap: () => Navigator.pop(context, i),
      onLongPress: () => _remove(i),
      child: SizedBox(
        width: 150,
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                i.$1.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatMoney(i.$2),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ColoredBox(
                    color: _bg,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(10),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [for (final i in _saved) _tile(i)],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 660,
                  color: _panel,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          height: 56,
                          alignment: Alignment.center,
                          color: const Color(0xFFF8F8F8),
                          child: const Text(
                            'Adhoc Product',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(40, 18, 40, 8),
                          child: Row(
                            children: [
                              Container(
                                width: 90,
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDEDED),
                                  border: Border.all(
                                    color: const Color(0xFFCCCCCC),
                                  ),
                                ),
                                child: const Text('Name'),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _name,
                                  focusNode: _focus,
                                  autofocus: true,
                                  textCapitalization: TextCapitalization.words,
                                  style: const TextStyle(fontSize: 18),
                                  decoration: tillFieldDecoration(''),
                                  onSubmitted: (_) => _ok(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          color: const Color(0xFFEDEDED),
                          child: Row(
                            children: [
                              const Text(
                                'Price',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 60),
                              Text(
                                _price.isEmpty ? '?' : '£$_price',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFieldTapRegion(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final row in const [
                                ['1', '2', '3'],
                                ['4', '5', '6'],
                                ['7', '8', '9'],
                              ])
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (final d in row) _key(d, _keyRed),
                                  ],
                                ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _key('.', _keyOrange),
                                  _key('0', _keyRed),
                                  _key('c', Colors.white, text: Colors.black87),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_focus.hasFocus)
            TextFieldTapRegion(
              child: SizedBox(
                height: 270,
                child: OnScreenKeyboard(
                  controller: _name,
                  onChanged: () => setState(() {}),
                  onEnter: _focus.unfocus,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                SizedBox(
                  width: 230,
                  child: TillButton(
                    label: 'CANCEL',
                    icon: AppIcons.closeRounded,
                    color: Colors.black,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 230,
                  child: TillButton.ok(label: 'OK', onTap: _ok),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
