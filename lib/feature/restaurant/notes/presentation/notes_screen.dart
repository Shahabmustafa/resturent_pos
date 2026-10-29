import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'pos_notes';

class _Note {
  final String text;
  final DateTime createdAt;
  final int? notifyAfterMinutes;
  const _Note(this.text, this.createdAt, [this.notifyAfterMinutes]);

  Map<String, dynamic> toJson() => {
    'text': text,
    'at': createdAt.toIso8601String(),
    'notify': notifyAfterMinutes,
  };
  factory _Note.fromJson(Map<String, dynamic> j) => _Note(
    j['text'] as String,
    DateTime.parse(j['at'] as String),
    j['notify'] as int?,
  );
}

/// Staff notebook kept on this device (shift handover, reminders, supplier calls).
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _controller = TextEditingController();
  final _notifyController = TextEditingController();
  bool _shift = false;
  List<_Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _notifyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List)
        .map((e) => _Note.fromJson(e as Map<String, dynamic>))
        .toList();
    if (mounted) setState(() => _notes = list);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(_notes.map((n) => n.toJson()).toList()),
    );
  }

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final minutes = int.tryParse(_notifyController.text.trim());
    setState(() => _notes.insert(0, _Note(text, DateTime.now(), minutes)));
    _controller.clear();
    _notifyController.clear();
    _save();
  }

  void _delete(_Note note) {
    setState(() => _notes.remove(note));
    _save();
  }

  void _type(String key) {
    final v = _controller.value;
    final sel = v.selection.isValid
        ? v.selection
        : TextSelection.collapsed(offset: v.text.length);
    final text = v.text.replaceRange(sel.start, sel.end, key);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: sel.start + key.length),
    );
    if (_shift) setState(() => _shift = false);
  }

  void _backspace() {
    final v = _controller.value;
    final sel = v.selection.isValid
        ? v.selection
        : TextSelection.collapsed(offset: v.text.length);
    if (sel.start != sel.end) return _type('');
    if (sel.start == 0) return;
    _controller.value = TextEditingValue(
      text: v.text.replaceRange(sel.start - 1, sel.start, ''),
      selection: TextSelection.collapsed(offset: sel.start - 1),
    );
  }

  Widget _key(String label, {int flex = 1, VoidCallback? onTap}) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          onTap:
              onTap ??
              () => _type(
                label.length == 1 && _shift ? label : label.toLowerCase(),
              ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _row(List<Widget> keys) => Expanded(child: Row(children: keys));

  Widget _keyboard() {
    List<Widget> letters(String chars) =>
        chars.split('').map((c) => _key(c)).toList();
    return Container(
      height: 270,
      color: Colors.black,
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          _row([
            ...'[]0123456789'
                .split('')
                .map((c) => _key(c, onTap: () => _type(c))),
            _key('Bksp', flex: 2, onTap: _backspace),
          ]),
          _row([
            _key('@', onTap: () => _type('@')),
            ...letters('QWERTYUIOP'),
            _key('del', flex: 3, onTap: _controller.clear),
          ]),
          _row([
            _key(
              'Shift',
              flex: 2,
              onTap: () => setState(() => _shift = !_shift),
            ),
            ...letters('ASDFGHJKL'),
            _key(';', onTap: () => _type(';')),
            _key("'", onTap: () => _type("'")),
            _key('Enter', flex: 2, onTap: () => _type('\n')),
          ]),
          _row([
            _key('?', flex: 2, onTap: () => _type('?')),
            ...letters('ZXCVBNM'),
            _key(',', onTap: () => _type(',')),
            _key('.', onTap: () => _type('.')),
            _key('', flex: 5, onTap: () => _type(' ')),
          ]),
        ],
      ),
    );
  }

  Widget _panelHeader(String title) => Container(
    height: 40,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Color(0xFFF8F8F8),
      border: Border(bottom: BorderSide(color: Color(0xFFDDDDDD))),
    ),
    child: Text(title, style: const TextStyle(fontSize: 15)),
  );

  Widget _noteList() => _notes.isEmpty
      ? const Center(
          child: Text(
            'No notes yet',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        )
      : ListView.separated(
          padding: const EdgeInsets.all(10),
          itemCount: _notes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final n = _notes[i];
            final notify = n.notifyAfterMinutes;
            return Material(
              color: Colors.white,
              elevation: 1,
              borderRadius: BorderRadius.circular(3),
              child: ListTile(
                title: Text(n.text),
                subtitle: Text(
                  '${DateFormat('EEE dd.MM.yy, h:mm a').format(n.createdAt)}'
                  '${notify == null ? '' : '  ·  notify after $notify min'}',
                ),
                trailing: IconButton(
                  tooltip: 'Delete',
                  icon: const SvgIcon(
                    AppIcons.deleteOutlineRounded,
                    size: 22,
                    color: Color(0xFFB91C1C),
                  ),
                  onPressed: () => _delete(n),
                ),
              ),
            );
          },
        );

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFD4D4D4),
    child: Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    color: const Color(0xFFEAEAEA),
                    child: Column(
                      children: [
                        _panelHeader('Notes'),
                        Expanded(child: _noteList()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    color: const Color(0xFFEAEAEA),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            expands: true,
                            minLines: null,
                            maxLines: null,
                            textAlignVertical: TextAlignVertical.top,
                            keyboardType: TextInputType.none,
                            showCursor: true,
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFF1D4ED8),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Notify After',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 90,
                              child: TextField(
                                controller: _notifyController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Minutes',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _keyboard(),
        Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 150,
            height: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3AAA1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              onPressed: _add,
              icon: const Icon(Icons.check, size: 26),
              label: const Text('Add'),
            ),
          ),
        ),
      ],
    ),
  );
}
