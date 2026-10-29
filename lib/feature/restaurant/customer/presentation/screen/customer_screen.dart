import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:resturent_application/feature/restaurant/auth/presentation/provider/branch_auth_provider.dart';
import 'package:resturent_application/feature/restaurant/customer_lookup/data/customer_lookup_datasource.dart';
import 'package:resturent_application/feature/restaurant/customer_lookup/presentation/collection_flow.dart';
import 'customer_details_screen.dart';
import 'package:resturent_application/feature/restaurant/live_orders/presentation/live_orders_screen.dart';

const _bg = Color(0xFFD9D9D7);
const _perPage = 15; // 3 columns x 5 rows
const _letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

// Letter buttons take the colours of the reference POS.
const _letterColors = [
  Color(0xFF2A9D8F),
  Color(0xFF3F51B5),
  Color(0xFFD9534F),
  Color(0xFF6A1B9A),
  Color(0xFF00897B),
  Color(0xFFB5541E),
];

/// Touch customer list: A–Z rails, search, 3-column cards. Tap a card to edit, New to add.
class CustomerPage extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final StartCustomerSale onStartSale;
  final void Function(CustomerProfile customer, CustomerOrderSummary order)
  onReorder;
  const CustomerPage({
    super.key,
    required this.onBack,
    required this.onStartSale,
    required this.onReorder,
  });

  @override
  ConsumerState<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends ConsumerState<CustomerPage> {
  final _search = TextEditingController();
  List<CustomerProfile> _all = [];
  bool _loading = true;
  String? _error;
  String? _letter = 'A';
  int _page = 0;
  CustomerProfile? _editing; // details form open for this customer

  String get _branchId => ref.read(branchAuthProvider).branch!.branchId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final all = await ref
          .read(customerLookupDatasourceProvider)
          .fetchAll(_branchId);
      if (!mounted) return;
      setState(() {
        _all = all
          ..sort(
            (a, b) =>
                a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
          );
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// A typed search looks through everyone; otherwise the chosen letter filters by first name.
  List<CustomerProfile> get _shown {
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      final digits = q.replaceAll(RegExp(r'\D'), '');
      return _all.where((c) {
        return c.fullName.toLowerCase().contains(q) ||
            c.address.toLowerCase().contains(q) ||
            c.postcode
                .toLowerCase()
                .replaceAll(' ', '')
                .contains(q.replaceAll(' ', '')) ||
            (digits.isNotEmpty && c.hasPhone(digits)) ||
            c.phone.contains(q);
      }).toList();
    }
    if (_letter == null) return _all;
    return _all
        .where(
          (c) =>
              c.fullName.isNotEmpty && c.fullName[0].toUpperCase() == _letter,
        )
        .toList();
  }

  void _pickLetter(String l) => setState(() {
    _letter = _letter == l ? null : l; // tap again to show everyone
    _search.clear();
    _page = 0;
  });

  @override
  Widget build(BuildContext context) {
    final editing = _editing;
    if (editing != null) {
      return CustomerDetailsScreen(
        // A fresh key per customer so the form never keeps another customer's text.
        key: ValueKey(editing.id ?? 'new'),
        customer: editing,
        datasource: ref.read(customerLookupDatasourceProvider),
        branchId: _branchId,
        onCancel: () => setState(() => _editing = null),
        onChanged: _load,
        onStartSale: widget.onStartSale,
        onReorder: widget.onReorder,
      );
    }

    final shown = _shown;
    final pages = (shown.length / _perPage).ceil().clamp(1, 99999);
    final page = _page.clamp(0, pages - 1);
    final items = shown.skip(page * _perPage).take(_perPage).toList();

    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LetterRail(
                  letters: _letters.substring(0, 13),
                  selected: _letter,
                  onTap: _pickLetter,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 620,
                            height: 48,
                            child: TextField(
                              controller: _search,
                              onChanged: (_) => setState(() => _page = 0),
                              decoration: const InputDecoration(
                                hintText: 'Search Customer',
                                filled: true,
                                fillColor: Color(0xFFF2F2F2),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          Material(
                            color: const Color(0xFFD9534F),
                            child: InkWell(
                              onTap: () => setState(() {
                                _search.clear();
                                _page = 0;
                              }),
                              child: const SizedBox(
                                width: 56,
                                height: 48,
                                child: Center(
                                  child: SvgIcon(
                                    AppIcons.closeRounded,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          _Pager(
                            page: page,
                            pages: pages,
                            onPage: (p) => setState(() => _page = p),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(child: _body(items)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _LetterRail(
                  letters: _letters.substring(13),
                  selected: _letter,
                  onTap: _pickLetter,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 6),
              const TimeBox(),
              const SizedBox(width: 10),
              _BottomButton(
                label: 'Back',
                icon: AppIcons.arrowBackRounded,
                color: Colors.black,
                width: 230,
                onTap: widget.onBack,
              ),
              const Spacer(),
              _BottomButton(
                label: 'New',
                icon: AppIcons.addRounded,
                color: const Color(0xFF3DBB16),
                width: 230,
                onTap: () => setState(() => _editing = CustomerProfile()),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ],
      ),
    );
  }

  Widget _body(List<CustomerProfile> items) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Text(
          'Could not load customers: $_error',
          style: const TextStyle(color: Color(0xFFB91C1C)),
        ),
      );
    }
    if (items.isEmpty)
      return const Center(
        child: Text(
          'No customers found',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    return LayoutBuilder(
      builder: (context, c) {
        final rowH = (c.maxHeight / 5).clamp(90.0, 200.0);
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisExtent: rowH,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _CustomerCard(
            customer: items[i],
            onTap: () => setState(() => _editing = items[i]),
          ),
        );
      },
    );
  }
}

class _LetterRail extends StatelessWidget {
  final String letters;
  final String? selected;
  final ValueChanged<String> onTap;
  const _LetterRail({
    required this.letters,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 84,
    child: Column(
      children: [
        for (final l in letters.split(''))
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: selected == l ? const Color(0xFF8E44AD) : Colors.white,
                elevation: 2,
                borderRadius: BorderRadius.circular(3),
                child: InkWell(
                  onTap: () => onTap(l),
                  child: Center(
                    child: Text(
                      l,
                      style: TextStyle(
                        fontSize: 22,
                        color: selected == l
                            ? Colors.white
                            : _letterColors[_letters.indexOf(l) %
                                  _letterColors.length],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _Pager extends StatelessWidget {
  final int page;
  final int pages;
  final ValueChanged<int> onPage;
  const _Pager({required this.page, required this.pages, required this.onPage});

  @override
  Widget build(BuildContext context) {
    Widget btn(String label, VoidCallback? onTap) => Material(
      color: const Color(0xFFF2F2F2),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 50,
          height: 42,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                color: onTap == null ? Colors.black26 : const Color(0xFF3A8EE6),
              ),
            ),
          ),
        ),
      ),
    );
    return Row(
      children: [
        btn('«', page > 0 ? () => onPage(page - 1) : null),
        Container(
          width: 50,
          height: 42,
          color: const Color(0xFF1E7BC6),
          alignment: Alignment.center,
          child: Text(
            '${page + 1}',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        btn('»', page < pages - 1 ? () => onPage(page + 1) : null),
      ],
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final CustomerProfile customer;
  final VoidCallback onTap;
  const _CustomerCard({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const line = TextStyle(
      fontSize: 16,
      color: Color(0xFF1F2937),
      height: 1.35,
    );
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.fullName.isEmpty ? 'No Name' : customer.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: line.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                customer.phone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: line,
              ),
              // Keep the postcode on its own line even when there is no street.
              Text(
                customer.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: line,
              ),
              Text(
                customer.postcode,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: line,
              ),
              if (customer.blacklisted)
                const Text(
                  'BLACKLISTED',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFD9534F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final String label;
  final AppIcon icon;
  final Color color;
  final double width;
  final VoidCallback onTap;
  const _BottomButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    elevation: 4,
    shadowColor: Colors.black,
    borderRadius: BorderRadius.circular(3),
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgIcon(icon, size: 28, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );
}
