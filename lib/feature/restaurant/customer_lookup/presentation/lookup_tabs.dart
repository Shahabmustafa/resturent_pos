import 'package:flutter/material.dart';
import '../data/customer_lookup_datasource.dart';
import 'on_screen_keyboard.dart';

const _gridBg = Color(0xFFEBEBEB);
const _label = Color(0xFF4B5563);
const _blue = Color(0xFF2A75E6);
const _green = Color(0xFF5CB85C);

// Tile colours cycle through this list, like the till's coloured postcode / street buttons.
const _tileColors = [
  Color(0xFF8E24AA),
  Color(0xFF00796B),
  Color(0xFF880E4F),
  Color(0xFF311B92),
  Color(0xFFB71C1C),
  Color(0xFF00897B),
  Color(0xFF2E7D32),
  Color(0xFF283593),
  Color(0xFFA1887F),
  Color(0xFF006064),
  Color(0xFFF44336),
  Color(0xFF6D4C41),
  Color(0xFF4E342E),
  Color(0xFF5E35B1),
  Color(0xFF1565C0),
  Color(0xFF00695C),
  Color(0xFFC62828),
  Color(0xFF558B2F),
];

String _normPostcode(String v) => v.replaceAll(' ', '').toUpperCase();

/// "82a Walton Road" -> "Walton Road".
String _streetOf(String address) {
  final s = address.trim().replaceFirst(
    RegExp(r'^\d+[a-zA-Z]?\s*[,\s]\s*'),
    '',
  );
  return s.isEmpty ? address.trim() : s;
}

/// Orders "3 Road", "11 Road" and "1a Road" the way a person would.
int _compareAddress(String a, String b) {
  int num(String s) =>
      int.tryParse(RegExp(r'^\d+').firstMatch(s.trim())?.group(0) ?? '') ??
      1 << 30;
  final d = num(a).compareTo(num(b));
  return d != 0 ? d : a.toLowerCase().compareTo(b.toLowerCase());
}

// ── Shared layout: pagination + search field + keyboard ───────────────────────

class _Pager extends StatelessWidget {
  final int page;
  final int pages;
  final ValueChanged<int> onPage;
  const _Pager({required this.page, required this.pages, required this.onPage});

  @override
  Widget build(BuildContext context) {
    Widget cell(String text, int? target, {bool selected = false}) => InkWell(
      canRequestFocus: false,
      onTap: target == null ? null : () => onPage(target),
      child: Container(
        width: 42,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _blue : Colors.white,
          border: Border.all(color: const Color(0xFFDDDDDD)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected
                ? Colors.white
                : (target == null ? Colors.black26 : _blue),
            fontSize: 15,
          ),
        ),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        cell('«', page > 0 ? page - 1 : null),
        for (var i = 0; i < pages; i++)
          cell('${i + 1}', i, selected: i == page),
        cell('»', page < pages - 1 ? page + 1 : null),
      ],
    );
  }
}

/// Search box that opens the on-screen keyboard while it has focus.
class _SearchScaffold extends StatefulWidget {
  final String hint;
  final Color? labelColor;
  final String? label;
  final int page;
  final int pages;
  final ValueChanged<int> onPage;
  final ValueChanged<String> onQuery;
  final Widget body;
  final Widget? left;
  final Widget? right;

  const _SearchScaffold({
    required this.hint,
    required this.page,
    required this.pages,
    required this.onPage,
    required this.onQuery,
    required this.body,
    this.label,
    this.labelColor,
    this.left,
    this.right,
  });

  @override
  State<_SearchScaffold> createState() => _SearchScaffoldState();
}

class _SearchScaffoldState extends State<_SearchScaffold> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed() {
    widget.onQuery(_ctrl.text.trim());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: _gridBg,
            margin: const EdgeInsets.fromLTRB(10, 4, 10, 0),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: widget.pages > 1
                          ? _Pager(
                              page: widget.page,
                              pages: widget.pages,
                              onPage: widget.onPage,
                            )
                          : const SizedBox(height: 40),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.label != null)
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            alignment: Alignment.center,
                            color: widget.labelColor,
                            child: Text(
                              widget.label!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        SizedBox(
                          width: 420,
                          height: 48,
                          child: TextField(
                            controller: _ctrl,
                            focusNode: _focus,
                            onChanged: (_) => _changed(),
                            style: const TextStyle(fontSize: 17),
                            decoration: InputDecoration(
                              hintText: widget.hint,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(
                                  color: Colors.blue.shade300,
                                ),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(
                                  color: Color(0xFFCCCCCC),
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(
                                  color: _blue,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.red.shade400,
                          child: InkWell(
                            canRequestFocus: false,
                            onTap: () {
                              _ctrl.clear();
                              _changed();
                            },
                            child: const SizedBox(
                              width: 50,
                              height: 48,
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.left != null) widget.left!,
                      Expanded(child: widget.body),
                      if (widget.right != null) widget.right!,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_focus.hasFocus)
          TextFieldTapRegion(
            child: OnScreenKeyboard(
              controller: _ctrl,
              onChanged: _changed,
              onEnter: _focus.unfocus,
            ),
          ),
      ],
    );
  }
}

/// Loads the customer list once and hands it to [builder].
class _CustomersLoader extends StatelessWidget {
  final Future<List<CustomerProfile>> all;
  final Widget Function(List<CustomerProfile>) builder;
  const _CustomersLoader({required this.all, required this.builder});

  @override
  Widget build(BuildContext context) => FutureBuilder<List<CustomerProfile>>(
    future: all,
    builder: (_, snap) {
      if (snap.hasError)
        return Center(child: Text('Could not load customers: ${snap.error}'));
      if (!snap.hasData)
        return const Center(child: CircularProgressIndicator());
      return builder(snap.data!);
    },
  );
}

// ── POSTCODES ─────────────────────────────────────────────────────────────────

class PostcodesTab extends StatefulWidget {
  final Future<List<CustomerProfile>> all;
  final ValueChanged<CustomerProfile> onCustomer;
  const PostcodesTab({super.key, required this.all, required this.onCustomer});

  @override
  State<PostcodesTab> createState() => _PostcodesTabState();
}

class _PostcodesTabState extends State<PostcodesTab> {
  String _query = '';
  int _page = 0;
  bool _sorted = true;

  @override
  Widget build(BuildContext context) => _CustomersLoader(
    all: widget.all,
    builder: (customers) {
      final byPostcode = <String, List<CustomerProfile>>{};
      for (final c in customers) {
        if (c.postcode.trim().isEmpty) continue;
        byPostcode
            .putIfAbsent(c.postcode.trim().toUpperCase(), () => [])
            .add(c);
      }
      var codes = byPostcode.keys
          .where((p) => _normPostcode(p).contains(_normPostcode(_query)))
          .toList();
      if (_sorted) codes.sort();
      return _TilesPage(
        hint: 'Search Postcode',
        label: 'Postcode',
        labelColor: const Color(0xFFFF6F00),
        count: codes.length,
        page: _page,
        onPage: (p) => setState(() => _page = p),
        onQuery: (q) => setState(() {
          _query = q;
          _page = 0;
        }),
        empty: 'No postcodes yet. They appear as customers are saved.',
        itemBuilder: (i) => _Tile(
          color: _tileColors[i % _tileColors.length],
          title: codes[i],
          onTap: () => _chooseAddress(
            context,
            byPostcode[codes[i]]!,
            widget.onCustomer,
            CustomerProfile(postcode: codes[i]),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SmallToggle(
              icon: Icons.sort_by_alpha_rounded,
              on: _sorted,
              onTap: () => setState(() => _sorted = !_sorted),
            ),
          ],
        ),
      );
    },
  );
}

// ── STREETS ───────────────────────────────────────────────────────────────────

class StreetsTab extends StatefulWidget {
  final Future<List<CustomerProfile>> all;
  final ValueChanged<CustomerProfile> onCustomer;
  const StreetsTab({super.key, required this.all, required this.onCustomer});

  @override
  State<StreetsTab> createState() => _StreetsTabState();
}

class _StreetsTabState extends State<StreetsTab> {
  String _query = '';
  int _page = 0;

  @override
  Widget build(BuildContext context) => _CustomersLoader(
    all: widget.all,
    builder: (customers) {
      // One tile per street + town; the tile opens every saved address on that street.
      final streets =
          <
            String,
            ({String name, String city, List<CustomerProfile> people})
          >{};
      for (final c in customers) {
        if (c.address.trim().isEmpty) continue;
        final name = _streetOf(c.address);
        final key = '${name.toLowerCase()}|${c.city.trim().toLowerCase()}';
        final cur = streets[key];
        if (cur == null) {
          streets[key] = (name: name, city: c.city.trim(), people: [c]);
        } else {
          cur.people.add(c);
        }
      }
      final list =
          streets.values
              .where((s) => s.name.toLowerCase().contains(_query.toLowerCase()))
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
      return _TilesPage(
        hint: 'Search Street',
        label: 'Street',
        labelColor: const Color(0xFF5BC0DE),
        count: list.length,
        page: _page,
        onPage: (p) => setState(() => _page = p),
        onQuery: (q) => setState(() {
          _query = q;
          _page = 0;
        }),
        empty: 'No streets yet. They appear as customers are saved.',
        itemBuilder: (i) => _Tile(
          color: _tileColors[i % _tileColors.length],
          title: list[i].name,
          subtitle: list[i].city,
          onTap: () => _chooseAddress(
            context,
            list[i].people,
            widget.onCustomer,
            CustomerProfile(city: list[i].city),
          ),
        ),
      );
    },
  );
}

/// 6-column grid of [_Tile]s with 5 rows per page.
class _TilesPage extends StatelessWidget {
  static const perPage = 30;
  final String hint;
  final String label;
  final Color labelColor;
  final int count;
  final int page;
  final ValueChanged<int> onPage;
  final ValueChanged<String> onQuery;
  final String empty;
  final Widget Function(int index) itemBuilder;
  final Widget? trailing;

  const _TilesPage({
    required this.hint,
    required this.label,
    required this.labelColor,
    required this.count,
    required this.page,
    required this.onPage,
    required this.onQuery,
    required this.empty,
    required this.itemBuilder,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final pages = (count / perPage).ceil();
    final current = page.clamp(0, pages == 0 ? 0 : pages - 1);
    final start = current * perPage;
    final end = (start + perPage).clamp(0, count);
    return _SearchScaffold(
      hint: hint,
      label: label,
      labelColor: labelColor,
      page: current,
      pages: pages,
      onPage: onPage,
      onQuery: onQuery,
      right: trailing,
      body: count == 0
          ? Center(
              child: Text(empty, style: const TextStyle(color: _label)),
            )
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisExtent: 66,
                crossAxisSpacing: 14,
                mainAxisSpacing: 12,
              ),
              itemCount: end - start,
              itemBuilder: (_, i) => itemBuilder(start + i),
            ),
    );
  }
}

class _Tile extends StatelessWidget {
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _Tile({
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      boxShadow: [BoxShadow(color: Colors.black54, offset: Offset(0, 2))],
    ),
    child: Material(
      color: color,
      child: InkWell(
        canRequestFocus: false,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SmallToggle extends StatelessWidget {
  final IconData icon;
  final bool on;
  final VoidCallback onTap;
  const _SmallToggle({
    required this.icon,
    required this.on,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    canRequestFocus: false,
    onTap: onTap,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: on ? Colors.white : const Color(0xFFF2F2F2),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      child: Icon(icon, size: 20, color: on ? _blue : Colors.black54),
    ),
  );
}

// ── CHOOSE ADDRESS ────────────────────────────────────────────────────────────

/// Full-screen list of the saved addresses behind a postcode or street.
/// Picking one opens that customer; SKIP goes back to the lookup screen.
Future<void> _chooseAddress(
  BuildContext context,
  List<CustomerProfile> people,
  ValueChanged<CustomerProfile> onCustomer,
  CustomerProfile fallback,
) async {
  final sorted = [...people]
    ..sort((a, b) => _compareAddress(a.address, b.address));
  final picked = await Navigator.of(context).push<CustomerProfile>(
    MaterialPageRoute(
      builder: (_) => _ChooseAddressPage(people: sorted, fallback: fallback),
    ),
  );
  if (picked != null) onCustomer(picked);
}

class _ChooseAddressPage extends StatefulWidget {
  final List<CustomerProfile> people;
  final CustomerProfile fallback;
  const _ChooseAddressPage({required this.people, required this.fallback});

  @override
  State<_ChooseAddressPage> createState() => _ChooseAddressPageState();
}

class _ChooseAddressPageState extends State<_ChooseAddressPage> {
  static const _perPage = 30;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final pages = (widget.people.length / _perPage).ceil().clamp(1, 1 << 20);
    final start = _page * _perPage;
    final shown = widget.people.skip(start).take(_perPage).toList();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            height: 56,
            width: double.infinity,
            color: const Color(0xFFF7F7F7),
            alignment: Alignment.center,
            child: const Text(
              'CHOOSE ADDRESS',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(30),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisExtent: 70,
                crossAxisSpacing: 8,
                mainAxisSpacing: 10,
              ),
              itemCount: shown.length,
              itemBuilder: (_, i) {
                final c = shown[i];
                return Container(
                  decoration: const BoxDecoration(
                    boxShadow: [
                      BoxShadow(color: Colors.black54, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Material(
                    color: Colors.white,
                    child: InkWell(
                      onTap: () => Navigator.pop(context, c),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            [
                              c.address,
                              if (c.fullName.isNotEmpty) '(${c.fullName})',
                            ].join(' '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            color: const Color(0xFFF7F7F7),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _Pager(
                  page: _page,
                  pages: pages,
                  onPage: (p) => setState(() => _page = p),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Material(
                    color: _green,
                    elevation: 3,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox(
                        width: 150,
                        height: 56,
                        child: Center(
                          child: Text(
                            'SKIP',
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ),
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

// ── CUSTOMERS ─────────────────────────────────────────────────────────────────

class CustomersTab extends StatefulWidget {
  final Future<List<CustomerProfile>> all;
  final ValueChanged<CustomerProfile> onCustomer;
  const CustomersTab({super.key, required this.all, required this.onCustomer});

  @override
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
  static const _perPage = 15;
  String _query = '';
  String? _letter;
  int _page = 0;

  Widget _letters(List<String> letters) => SizedBox(
    width: 56,
    child: Column(
      children: [
        for (final l in letters)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: InkWell(
              canRequestFocus: false,
              onTap: () => setState(() {
                _letter = _letter == l ? null : l;
                _page = 0;
              }),
              child: Container(
                width: 48,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _letter == l ? _blue : Colors.white,
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, offset: Offset(0, 2)),
                  ],
                ),
                child: Text(
                  l,
                  style: TextStyle(
                    fontSize: 18,
                    color: _letter == l ? Colors.white : _blue,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => _CustomersLoader(
    all: widget.all,
    builder: (customers) {
      final q = _query.toLowerCase();
      final qDigits = q.replaceAll(' ', '');
      final list = customers.where((c) {
        if (_letter != null && !c.fullName.toUpperCase().startsWith(_letter!))
          return false;
        if (q.isEmpty) return true;
        return c.fullName.toLowerCase().contains(q) ||
            [
              c.phone,
              c.phone2,
              c.phone3,
            ].any((p) => p.replaceAll(' ', '').contains(qDigits));
      }).toList();
      final pages = (list.length / _perPage).ceil();
      final current = _page.clamp(0, pages == 0 ? 0 : pages - 1);
      final shown = list.skip(current * _perPage).take(_perPage).toList();
      const abc = [
        'A',
        'B',
        'C',
        'D',
        'E',
        'F',
        'G',
        'H',
        'I',
        'J',
        'K',
        'L',
        'M',
        'N',
        'O',
        'P',
        'Q',
        'R',
        'S',
        'T',
        'U',
        'V',
        'W',
        'X',
        'Y',
        'Z',
      ];
      return _SearchScaffold(
        hint: 'Search Customer',
        page: current,
        pages: pages,
        onPage: (p) => setState(() => _page = p),
        onQuery: (v) => setState(() {
          _query = v;
          _page = 0;
        }),
        left: _letters(abc.sublist(0, 13)),
        right: _letters(abc.sublist(13)),
        body: list.isEmpty
            ? const Center(
                child: Text(
                  'No customers found',
                  style: TextStyle(color: _label),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisExtent: 116,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: shown.length,
                itemBuilder: (_, i) {
                  final c = shown[i];
                  return Container(
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(color: Colors.black54, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Material(
                      color: Colors.white,
                      child: InkWell(
                        canRequestFocus: false,
                        onTap: () => widget.onCustomer(c),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.fullName.isEmpty ? 'No Name' : c.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                c.phone,
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                c.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                c.postcode,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      );
    },
  );
}
