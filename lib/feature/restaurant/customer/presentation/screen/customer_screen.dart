import 'package:resturent_application/core/widget/page_skeleton.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/model/customer_model.dart';
import '../provider/customer_provider.dart';
import 'package:resturent_application/core/constants/currency.dart';

class CustomerPage extends ConsumerStatefulWidget {
  const CustomerPage({super.key});

  @override
  ConsumerState<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends ConsumerState<CustomerPage> {

  static const kPrimary   = Color(0xFFB91C1C);
  static const kBg        = Color(0xFFF5F6FA);
  static const kCard      = Color(0xFFFFFFFF);
  static const kBorder    = Color(0xFFE8EAF0);
  static const kTextDark  = Color(0xFF1A1D3A);
  static const kTextMid   = Color(0xFF5A5E80);
  static const kTextLight = Color(0xFF9396B0);

  List<CustomerModel> _filtered = [];
  final _searchCtrl = TextEditingController();
  String _typeFilter    = 'all';
  String _loyaltyFilter = 'all';
  String _sortKey       = 'name';
  bool   _sortAsc       = true;
  int    _page          = 0;
  static const _perPage = 8;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters([List<CustomerModel>? source]) {
    final all = source ?? ref.read(customerProvider).customers;
    final q   = _searchCtrl.text.toLowerCase();

    var list = all.where((c) {
      final matchQ = q.isEmpty || c.name.toLowerCase().contains(q) || c.phone.contains(q);
      final matchT = _typeFilter == 'all'
          || (_typeFilter == 'walkin' && c.type == CustomerType.walkIn)
          || (_typeFilter == 'credit' && c.type == CustomerType.credit)
          || (_typeFilter == 'online' && c.type == CustomerType.online);
      final matchL = _loyaltyFilter == 'all' || c.loyaltyLabel.toLowerCase() == _loyaltyFilter;
      return matchQ && matchT && matchL;
    }).toList();

    list.sort((a, b) {
      int cmp;
      switch (_sortKey) {
        case 'orders':  cmp = a.orders.compareTo(b.orders); break;
        case 'spent':   cmp = a.spent.compareTo(b.spent); break;
        case 'balance': cmp = a.balance.compareTo(b.balance); break;
        case 'loyalty':
          const o = {LoyaltyTier.regular: 0, LoyaltyTier.silver: 1, LoyaltyTier.gold: 2};
          cmp = o[a.loyalty]!.compareTo(o[b.loyalty]!); break;
        default:        cmp = a.name.compareTo(b.name);
      }
      return _sortAsc ? cmp : -cmp;
    });

    setState(() { _filtered = list; _page = 0; });
  }

  void _setSort(String key) {
    setState(() {
      _sortKey = key == _sortKey ? _sortKey : key;
      _sortAsc = key == _sortKey ? !_sortAsc : true;
    });
    _applyFilters();
  }

  List<CustomerModel> get _pageItems {
    final s = _page * _perPage;
    final e = (s + _perPage).clamp(0, _filtered.length);
    return _filtered.sublist(s, e);
  }

  int get _totalPages => (_filtered.length / _perPage).ceil().clamp(1, 99999);

  int    _totalCount(List<CustomerModel> all)   => all.length;
  int    _creditCount(List<CustomerModel> all)  => all.where((c) => c.type == CustomerType.credit).length;
  double _totalBalance(List<CustomerModel> all) => all.fold(0, (s, c) => s + c.balance);
  int    _loyalCount(List<CustomerModel> all)   => all.where((c) => c.loyalty != LoyaltyTier.regular).length;

  static const _avColors = [
    [Color(0xFFEEF2FF), Color(0xFF4338CA)],
    [Color(0xFFF0FDF4), Color(0xFF15803D)],
    [Color(0xFFFFFBEB), Color(0xFFB45309)],
    [Color(0xFFFEF2F2), Color(0xFFB91C1C)],
    [Color(0xFFEFF6FF), Color(0xFF1D4ED8)],
    [Color(0xFFFDF4FF), Color(0xFF7E22CE)],
  ];
  Color _avBg(int i)   => _avColors[i % _avColors.length][0];
  Color _avText(int i) => _avColors[i % _avColors.length][1];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProvider);

    ref.listen<CustomerState>(customerProvider, (_, next) {
      _applyFilters(next.customers);
    });

    if (_filtered.isEmpty && state.customers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilters(state.customers));
    }

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: kBg,
        body: PageSkeleton(statCount: 4, rows: 8, columns: 5),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            const SizedBox(height: 16),
            _buildStatsRow(state.customers),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 8),
              _errorBanner(state.errorMessage!),
            ],
            const SizedBox(height: 16),
            _buildFilterBar(),
            const SizedBox(height: 12),
            Expanded(child: _buildTable(state.customers)),
          ],
        ),
      ),
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const SvgIcon(AppIcons.errorOutlineRounded, size: 16, color: Color(0xFFEF4444)),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C)))),
          GestureDetector(
            onTap: () => ref.read(customerProvider.notifier).clearError(),
            child: const SvgIcon(AppIcons.closeRounded, size: 16, color: Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer Management',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kTextDark)),
            SizedBox(height: 2),
            Text('Manage customers, credit accounts & loyalty',
                style: TextStyle(fontSize: 12, color: kTextLight)),
          ],
        ),
        const Spacer(),
        _outlineBtn(icon: AppIcons.downloadRounded, label: 'Export', onTap: _onExport),
        const SizedBox(width: 10),
        _primaryBtn(icon: AppIcons.addRounded, label: 'Add Customer', onTap: () => _showFormDialog(null)),
      ],
    );
  }

  void _onExport() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Export feature coming soon')));
  }

  Widget _buildStatsRow(List<CustomerModel> all) {
    return Row(
      children: [
        _statCard(icon: AppIcons.peopleRounded,
            iconBg: const Color(0xFFEEF2FF), iconColor: const Color(0xFF6366F1),
            label: 'Total Customers', value: '${_totalCount(all)}', sub: 'Registered'),
        const SizedBox(width: 12),
        _statCard(icon: AppIcons.fileCopyRounded,
            iconBg: const Color(0xFFFEF2F2), iconColor: const Color(0xFFEF4444),
            label: 'Credit Accounts', value: '${_creditCount(all)}', sub: 'Active accounts'),
        const SizedBox(width: 12),
        _statCard(icon: AppIcons.accountBalanceWalletRounded,
            iconBg: const Color(0xFFFFFBEB), iconColor: const Color(0xFFF59E0B),
            label: 'Credit Balance',
            value: formatMoney(_totalBalance(all)), sub: 'Outstanding'),
        const SizedBox(width: 12),
        _statCard(icon: AppIcons.starRounded,
            iconBg: const Color(0xFFF0FDF4), iconColor: const Color(0xFF22C55E),
            label: 'Loyal Customers', value: '${_loyalCount(all)}', sub: 'Gold + Silver'),
      ],
    );
  }

  Widget _statCard({
    required AppIcon icon, required Color iconBg, required Color iconColor,
    required String label, required String value, required String sub,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: SvgIcon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontSize: 11, color: kTextLight)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kTextDark)),
                Text(sub,   style: const TextStyle(fontSize: 11, color: Color(0xFFD1D5DB))),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        SizedBox(
          width: 240, height: 38,
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(fontSize: 13, color: kTextDark),
            decoration: const InputDecoration(
              hintText: 'Search by name or phone...',
              hintStyle: TextStyle(fontSize: 13, color: kTextLight),
              prefixIcon: SvgIcon(AppIcons.searchRounded, size: 18, color: kTextLight),
              contentPadding: EdgeInsets.zero,
              filled: true, fillColor: kCard,
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: kPrimary)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _dropFilter(
          value: _typeFilter,
          items: const {'all': 'All Types', 'walkin': 'Walk-in', 'credit': 'Credit', 'online': 'Online'},
          onChanged: (v) { setState(() => _typeFilter = v!); _applyFilters(); },
        ),
        const SizedBox(width: 10),
        _dropFilter(
          value: _loyaltyFilter,
          items: const {'all': 'All Loyalty', 'gold': 'Gold', 'silver': 'Silver', 'regular': 'Regular'},
          onChanged: (v) { setState(() => _loyaltyFilter = v!); _applyFilters(); },
        ),
        const Spacer(),
        Text('${_filtered.length} results', style: const TextStyle(fontSize: 12, color: kTextLight)),
      ],
    );
  }

  Widget _dropFilter({required String value, required Map<String, String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: const TextStyle(fontSize: 13, color: kTextDark),
          icon: const SvgIcon(AppIcons.keyboardArrowDownRounded, size: 18, color: kTextLight),
          onChanged: onChanged,
          items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
        ),
      ),
    );
  }

  Widget _buildTable(List<CustomerModel> all) {
    return Container(
      decoration: BoxDecoration(
        color: kCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: kBorder)),
            ),
            child: _tableHeader(),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? _emptyState()
                : ListView.builder(
              itemCount: _pageItems.length,
              itemBuilder: (_, i) => _tableRow(_pageItems[i], i, all),
            ),
          ),
          _pagination(),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        const SizedBox(width: 32),
        _hCell('Customer',  flex: 4, key: 'name'),
        _hCell('Type',      flex: 2, key: 'type'),
        _hCell('Orders',    flex: 2, key: 'orders'),
        _hCell('Spent',     flex: 3, key: 'spent'),
        _hCell('Balance',   flex: 3, key: 'balance'),
        _hCell('Loyalty',   flex: 3, key: 'loyalty'),
        const Expanded(flex: 2, child: Text('DISCOUNT',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kTextLight, letterSpacing: 0.5))),
        const Expanded(flex: 2, child: Text('ACTIONS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kTextLight, letterSpacing: 0.5))),
      ]),
    );
  }

  Widget _hCell(String label, {required int flex, required String key}) {
    final active = _sortKey == key;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => _setSort(key),
        child: Row(children: [
          Text(label.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5,
                  color: active ? kPrimary : kTextLight)),
          const SizedBox(width: 3),
          SvgIcon(
            active ? (_sortAsc ? AppIcons.arrowUpwardRounded : AppIcons.arrowDownwardRounded)
                : AppIcons.unfoldMoreRounded,
            size: 13, color: active ? kPrimary : const Color(0xFFD1D5DB),
          ),
        ]),
      ),
    );
  }

  Widget _tableRow(CustomerModel c, int i, List<CustomerModel> all) {
    final idx         = all.indexOf(c);
    final globalIndex = _page * _perPage + i;
    return Container(
      decoration: BoxDecoration(
        border: const Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 0.8)),
        color: i.isEven ? kCard : const Color(0xFFFAFAFB),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          SizedBox(width: 32,
              child: Text('${globalIndex + 1}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFD1D5DB), fontWeight: FontWeight.w500))),
          Expanded(flex: 4,
            child: Row(children: [
              CircleAvatar(radius: 17, backgroundColor: _avBg(idx),
                  child: Text(c.initials,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _avText(idx)))),
              const SizedBox(width: 9),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextDark),
                      overflow: TextOverflow.ellipsis),
                  Row(children: [
                    const SvgIcon(AppIcons.phoneRounded, size: 10, color: kTextLight),
                    const SizedBox(width: 3),
                    Text(c.phone, style: const TextStyle(fontSize: 11, color: kTextLight)),
                  ]),
                ]),
              ),
            ]),
          ),
          Expanded(flex: 2, child: _typeBadge(c.type)),
          Expanded(flex: 2,
              child: Text('${c.orders}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextDark))),
          Expanded(flex: 3,
              child: Text(formatMoney(c.spent),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF374151)))),
          Expanded(flex: 3,
              child: c.balance > 0 ? _balanceBadge(c.balance)
                  : const Text('—', style: TextStyle(color: Color(0xFFD1D5DB)))),
          Expanded(flex: 3, child: _loyaltyWidget(c.loyalty)),
          Expanded(flex: 2,
              child: c.discount > 0
                  ? _chip('${c.discount.toInt()}%', const Color(0xFFF0FDF4), const Color(0xFF15803D))
                  : const Text('—', style: TextStyle(color: Color(0xFFD1D5DB)))),
          Expanded(flex: 2,
            child: Row(children: [
              _iconBtn(AppIcons.historyRounded,        'History', () => _showHistory(c, idx)),
              const SizedBox(width: 4),
              _iconBtn(AppIcons.editRounded,           'Edit',    () => _showFormDialog(c)),
              const SizedBox(width: 4),
              _iconBtn(AppIcons.deleteOutlineRounded, 'Delete',  () => _confirmDelete(c), danger: true),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _pagination() {
    final start = _filtered.isEmpty ? 0 : _page * _perPage + 1;
    final end   = ((_page + 1) * _perPage).clamp(0, _filtered.length);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFB),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          Text(
            _filtered.isEmpty ? 'No results' : '$start–$end of ${_filtered.length} customers',
            style: const TextStyle(fontSize: 12, color: kTextLight),
          ),
          const Spacer(),
          _pageBtn(AppIcons.chevronLeftRounded,  _page > 0,              () => setState(() => _page--)),
          const SizedBox(width: 4),
          ...List.generate(_totalPages.clamp(0, 7), (i) {
            final active = i == _page;
            return GestureDetector(
              onTap: () => setState(() => _page = i),
              child: Container(
                margin: const EdgeInsets.only(left: 4),
                width: 30, height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? kPrimary : kCard,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: active ? kPrimary : kBorder),
                ),
                child: Text('${i + 1}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                        color: active ? Colors.white : kTextMid)),
              ),
            );
          }),
          const SizedBox(width: 4),
          _pageBtn(AppIcons.chevronRightRounded, _page < _totalPages - 1, () => setState(() => _page++)),
        ],
      ),
    );
  }

  Widget _pageBtn(AppIcon icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30, height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kCard, borderRadius: BorderRadius.circular(7),
          border: Border.all(color: kBorder),
        ),
        child: SvgIcon(icon, size: 16, color: enabled ? kTextMid : const Color(0xFFD1D5DB)),
      ),
    );
  }

  Widget _typeBadge(CustomerType type) => switch (type) {
    CustomerType.credit => _chip('Credit', const Color(0xFFFEF2F2), const Color(0xFFB91C1C),
        icon: AppIcons.fileCopyRounded),
    CustomerType.online => _chip('Online', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8),
        icon: AppIcons.phoneAndroidRounded),
    CustomerType.walkIn => _chip('Walk-in', const Color(0xFFF0FDF4), const Color(0xFF15803D),
        icon: AppIcons.directionsWalkRounded),
  };

  Widget _balanceBadge(double balance) {
    return _chip(formatMoney(balance),
        const Color(0xFFFEF2F2), const Color(0xFFB91C1C),
        icon: AppIcons.warningAmberRounded);
  }

  Widget _loyaltyWidget(LoyaltyTier tier) {
    final map = {
      LoyaltyTier.gold:    [const Color(0xFFFFFBEB), const Color(0xFFB45309), AppIcons.starRounded, 1.0],
      LoyaltyTier.silver:  [const Color(0xFFEFF6FF), const Color(0xFF1D4ED8), AppIcons.militaryTechRounded, 0.6],
      LoyaltyTier.regular: [const Color(0xFFF9FAFB), const Color(0xFF6B7280), AppIcons.personOutlineRounded, 0.25],
    };
    final cfg = map[tier]!;
    return Row(children: [
      _chip(tier.name[0].toUpperCase() + tier.name.substring(1),
          cfg[0] as Color, cfg[1] as Color, icon: cfg[2] as AppIcon),
      const SizedBox(width: 6),
      SizedBox(
        width: 40, height: 5,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: cfg[3] as double,
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: AlwaysStoppedAnimation<Color>(cfg[1] as Color),
          ),
        ),
      ),
    ]);
  }

  Widget _chip(String label, Color bg, Color fg, {AppIcon? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[SvgIcon(icon, size: 11, color: fg), const SizedBox(width: 3)],
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
      ]),
    );
  }

  Widget _iconBtn(AppIcon icon, String tooltip, VoidCallback onTap, {bool danger = false}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(7)),
          child: SvgIcon(icon, size: 14, color: danger ? const Color(0xFFEF4444) : kTextLight),
        ),
      ),
    );
  }

  Widget _primaryBtn({required AppIcon icon, required String label, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap, icon: SvgIcon(icon, size: 16), label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary, foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0,
      ),
    );
  }

  Widget _outlineBtn({required AppIcon icon, required String label, required VoidCallback onTap}) {
    return OutlinedButton.icon(
      onPressed: onTap, icon: SvgIcon(icon, size: 16), label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: kTextDark, textStyle: const TextStyle(fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: kBorder),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SvgIcon(AppIcons.peopleOutlineRounded, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        const Text('No customers found', style: TextStyle(color: kTextLight, fontSize: 14)),
        const SizedBox(height: 6),
        const Text('Change filters or add a new customer',
            style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 12)),
      ]),
    );
  }

  // ── Add / Edit Dialog ─────────────────────────────────────────────────────
  void _showFormDialog(CustomerModel? existing) {
    final nameCtrl  = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final discCtrl  = TextEditingController(text: existing?.discount.toInt().toString() ?? '0');
    var   type      = existing?.type ?? CustomerType.walkIn;
    var   loyalty   = existing?.loyalty ?? LoyaltyTier.regular;
    final formKey   = GlobalKey<FormState>();
    bool  saving    = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: kCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
              child: const SvgIcon(AppIcons.personAddRounded, size: 18, color: kPrimary),
            ),
            const SizedBox(width: 10),
            Text(existing == null ? 'Add Customer' : 'Edit Customer',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTextDark)),
          ]),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _formField('Full Name', nameCtrl, 'e.g. Ahmed Khan',
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                _formField('Phone Number', phoneCtrl, '03XX-XXXXXXX',
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _dialogLabel('Customer Type'),
                const SizedBox(height: 5),
                Row(children: [
                  _typeToggle('Walk-in',        CustomerType.walkIn, type,
                      AppIcons.directionsWalkRounded, () => setS(() => type = CustomerType.walkIn)),
                  const SizedBox(width: 8),
                  _typeToggle('Credit Account', CustomerType.credit, type,
                      AppIcons.fileCopyRounded,       () => setS(() => type = CustomerType.credit)),
                  const SizedBox(width: 8),
                  _typeToggle('Online',         CustomerType.online, type,
                      AppIcons.phoneAndroidRounded,   () => setS(() => type = CustomerType.online)),
                ]),
                const SizedBox(height: 12),
                _dialogLabel('Loyalty Tier'),
                const SizedBox(height: 5),
                Row(children: [
                  _loyaltyToggle('Regular', LoyaltyTier.regular, loyalty, const Color(0xFF6B7280),
                          () => setS(() => loyalty = LoyaltyTier.regular)),
                  const SizedBox(width: 8),
                  _loyaltyToggle('Silver',  LoyaltyTier.silver,  loyalty, const Color(0xFF1D4ED8),
                          () => setS(() => loyalty = LoyaltyTier.silver)),
                  const SizedBox(width: 8),
                  _loyaltyToggle('Gold',    LoyaltyTier.gold,    loyalty, const Color(0xFFB45309),
                          () => setS(() => loyalty = LoyaltyTier.gold)),
                ]),
                const SizedBox(height: 12),
                _formField('Discount %', discCtrl, '0',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 0 || n > 100) return 'Enter a value between 0–100';
                      return null;
                    }),
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: kTextLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0,
              ),
              onPressed: saving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setS(() => saving = true);
                if (existing == null) {
                  final newC = CustomerModel(
                    id:       DateTime.now().millisecondsSinceEpoch.toString(),
                    branchId: '',
                    name:     nameCtrl.text.trim(),
                    phone:    phoneCtrl.text.trim(),
                    type:     type,
                    loyalty:  loyalty,
                    discount: double.tryParse(discCtrl.text) ?? 0,
                  );
                  await ref.read(customerProvider.notifier).addCustomer(newC);
                } else {
                  existing.name     = nameCtrl.text.trim();
                  existing.phone    = phoneCtrl.text.trim();
                  existing.type     = type;
                  existing.loyalty  = loyalty;
                  existing.discount = double.tryParse(discCtrl.text) ?? 0;
                  await ref.read(customerProvider.notifier).updateCustomer(existing);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: saving
                  ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeToggle(String label, CustomerType value, CustomerType current,
      AppIcon icon, VoidCallback onTap) {
    final active = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFEE2E2) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? kPrimary : kBorder, width: active ? 1.5 : 1),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SvgIcon(icon, size: 18, color: active ? kPrimary : kTextLight),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                color: active ? kPrimary : kTextMid)),
          ]),
        ),
      ),
    );
  }

  Widget _loyaltyToggle(String label, LoyaltyTier value, LoyaltyTier current,
      Color color, VoidCallback onTap) {
    final active = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.08) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? color : kBorder, width: active ? 1.5 : 1),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                  color: active ? color : kTextMid)),
        ),
      ),
    );
  }

  Widget _dialogLabel(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextMid)),
  );

  Widget _formField(String label, TextEditingController ctrl, String hint, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextMid)),
      const SizedBox(height: 5),
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 13, color: kTextDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: kTextLight),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimary)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.redAccent)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.redAccent)),
        ),
      ),
    ]);
  }

  // ── Delete Dialog ─────────────────────────────────────────────────────────
  void _confirmDelete(CustomerModel c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Customer?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTextDark)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const SvgIcon(AppIcons.warningAmberRounded, color: Color(0xFFEF4444), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Permanently delete "${c.name}"?',
                    style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C))),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          const Text('This action cannot be undone.',
              style: TextStyle(fontSize: 12, color: kTextLight)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kTextLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0,
            ),
            onPressed: () async {
              await ref.read(customerProvider.notifier).deleteCustomer(c.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── History Dialog ────────────────────────────────────────────────────────
  void _showHistory(CustomerModel c, int idx) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          CircleAvatar(radius: 20, backgroundColor: _avBg(idx),
              child: Text(c.initials,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _avText(idx)))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTextDark)),
            Text(c.phone, style: const TextStyle(fontSize: 12, color: kTextLight)),
          ]),
        ]),
        content: SizedBox(
          width: 340,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(children: [
              _miniStatCard('Total Orders', '${c.orders}', AppIcons.shoppingBagRounded, const Color(0xFF6366F1)),
              const SizedBox(width: 10),
              _miniStatCard('Total Spent', formatMoney(c.spent),
                  AppIcons.paymentsRounded, const Color(0xFF22C55E)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _miniStatCard('Credit Balance',
                  c.balance > 0 ? formatMoney(c.balance) : 'Clear',
                  AppIcons.accountBalanceWalletRounded,
                  c.balance > 0 ? const Color(0xFFEF4444) : const Color(0xFF22C55E)),
              const SizedBox(width: 10),
              _miniStatCard('Discount', '${c.discount.toInt()}%', AppIcons.localOfferRounded, kPrimary),
            ]),
            const SizedBox(height: 14),
            _historyRow(AppIcons.categoryRounded,      'Type',    c.typeLabel),
            _historyRow(AppIcons.starRounded,           'Loyalty', c.loyaltyLabel),
            _historyRow(AppIcons.calendarTodayRounded, 'Joined',
                '${c.joinedAt.day}/${c.joinedAt.month}/${c.joinedAt.year}'),
          ]),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () { Navigator.pop(context); _showFormDialog(c); },
            icon: const SvgIcon(AppIcons.editRounded, size: 14),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kTextDark, side: const BorderSide(color: kBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _miniStatCard(String label, String value, AppIcon icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(children: [
          SvgIcon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _historyRow(AppIcon icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SvgIcon(icon, size: 15, color: kPrimary),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: kTextMid)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextDark)),
      ]),
    );
  }
}