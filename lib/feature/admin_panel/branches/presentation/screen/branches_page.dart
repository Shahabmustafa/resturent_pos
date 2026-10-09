import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../widget/shared_widget.dart';
import '../../data/datasource/branches_datasource.dart';
import '../../data/model/branches_model.dart';
import '../widget/branch_model_widget.dart';

class BranchesPage extends StatefulWidget {
  final String companyId;
  final BranchDatasource datasource;

  const BranchesPage({
    super.key,
    required this.companyId,
    required this.datasource,
  });

  @override
  State<BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends State<BranchesPage> {
  List<Branch> _branches = [];
  bool _loading = true;
  String _search = '';
  String _sortCol = 'name';
  bool _sortAsc = true;

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    setState(() => _loading = true);
    final data = await widget.datasource.fetchBranches(widget.companyId);
    setState(() {
      _branches = data;
      _loading = false;
    });
  }

  List<Branch> get _filtered {
    final q = _search.toLowerCase();
    var list = _branches.where((b) {
      return b.name.toLowerCase().contains(q) ||
          b.city.toLowerCase().contains(q) ||
          b.phone.toLowerCase().contains(q);
    }).toList();

    list.sort((a, b) {
      int cmp;
      switch (_sortCol) {
        case 'city':
          cmp = a.city.compareTo(b.city);
          break;
        case 'phone':
          cmp = a.phone.compareTo(b.phone);
          break;
        case 'tables':
          cmp = a.tables.compareTo(b.tables);
          break;
        case 'status':
          cmp = (a.isOpen ? 0 : 1).compareTo(b.isOpen ? 0 : 1);
          break;
        default:
          cmp = a.name.compareTo(b.name);
      }
      return _sortAsc ? cmp : -cmp;
    });
    return list;
  }

  void _setSort(String col) => setState(() {
    if (_sortCol == col) {
      _sortAsc = !_sortAsc;
    } else {
      _sortCol = col;
      _sortAsc = true;
    }
  });

  void _openModal([Branch? editing]) {
    showDialog(
      context: context,
      builder: (_) => BranchFormDialog(
        editing: editing,
        companyId: widget.companyId,
        usedColors: _branches.map((b) => b.color).toList(),
        onSave: (result) async {
          if (editing != null) {
            final updated = await widget.datasource.updateBranch(
              branchId: editing.id,
              name: result.branch.name,
              city: result.branch.city,
              address: result.branch.address,
              phone: result.branch.phone,
              ntn: result.branch.ntn,
              tables: result.branch.tables,
              isOpen: result.branch.isOpen,
              color: result.branch.color,
              adminUserId: editing.adminUser?.id,
              adminName: result.adminName,
              adminUsername: result.adminUsername,
              adminEmail: result.adminEmail,
              adminPhone: result.adminPhone,
              adminRole: result.adminRole,
              newPassword: result.newPassword,
            );
            setState(() {
              _branches = _branches
                  .map((b) => b.id == editing.id ? updated : b)
                  .toList();
            });
          } else {
            final added = await widget.datasource.addBranch(
              companyId: widget.companyId,
              name: result.branch.name,
              city: result.branch.city,
              address: result.branch.address,
              phone: result.branch.phone,
              ntn: result.branch.ntn,
              tables: result.branch.tables,
              colorIndex: _branches.length,
              adminName: result.adminName,
              adminUsername: result.adminUsername,
              adminEmail: result.adminEmail,
              adminPhone: result.adminPhone,
              adminPassword: result.newPassword ?? '',
              adminRole: result.adminRole,
            );
            setState(() {
              _branches = [..._branches, added];
            });
          }
        },
      ),
    );
  }

  void _confirmDelete(Branch b) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Branch',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete "${b.name}"?',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.dangerLt,
                  borderRadius: BorderRadius.circular(8)),
              child: const Row(children: [
                SvgIcon(AppIcons.warningAmberRounded,
                    color: AppColors.danger, size: 14),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'All of the branch\'s users and data will also be deleted.',
                    style: TextStyle(fontSize: 11, color: AppColors.danger),
                  ),
                ),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await widget.datasource.deleteBranch(b.id);
              setState(() {
                _branches = _branches.where((x) => x.id != b.id).toList();
              });
            },
            child: const Text('Delete', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final filtered = _filtered;
    final openCount = _branches.where((b) => b.isOpen).length;
    final closedCount = _branches.length - openCount;
    final totalTables = _branches.fold(0, (s, b) => s + b.tables);

    return Column(
      children: [
        AdminTopBar(
          title: 'Branches',
          subtitle: '${_branches.length} locations registered',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _openModal(),
              icon: const SvgIcon(AppIcons.add, size: 15),
              label: const Text('Add Branch',
                  style:
                  TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── KPI Row ────────────────────────────────────────────
                Row(children: [
                  Expanded(
                      child: KpiCard(
                          label: 'Total Branches',
                          value: '${_branches.length}',
                          icon: AppIcons.storeOutlined,
                          color: AppColors.primary)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: KpiCard(
                          label: 'Open',
                          value: '$openCount',
                          icon: AppIcons.checkCircleOutline,
                          color: AppColors.success)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: KpiCard(
                          label: 'Closed',
                          value: '$closedCount',
                          icon: AppIcons.cancelOutlined,
                          color: AppColors.danger)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: KpiCard(
                          label: 'Total Tables',
                          value: '$totalTables',
                          icon: AppIcons.tableRestaurantOutlined,
                          color: const Color(0xFF8B5CF6))),
                ]),

                const SizedBox(height: 22),

                // ── Table ──────────────────────────────────────────────
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      // Toolbar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Row(children: [
                          const Text('All Branches',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.dark)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${_branches.length}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary)),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 230,
                            height: 34,
                            child: TextField(
                              onChanged: (v) =>
                                  setState(() => _search = v),
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.dark),
                              decoration: InputDecoration(
                                hintText: 'Search name, city, phone...',
                                hintStyle: const TextStyle(
                                    fontSize: 12, color: AppColors.grey),
                                prefixIcon: const SvgIcon(AppIcons.search,
                                    size: 15, color: AppColors.grey),
                                filled: true,
                                fillColor: AppColors.bg,
                                contentPadding:
                                const EdgeInsets.symmetric(
                                    vertical: 0, horizontal: 10),
                                border: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: AppColors.border)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: AppColors.border)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: AppColors.primary,
                                        width: 1.5)),
                                isDense: true,
                              ),
                            ),
                          ),
                        ]),
                      ),

                      filtered.isEmpty
                          ? Padding(
                        padding: const EdgeInsets.all(48),
                        child: Center(
                          child: Column(children: [
                            SvgIcon(AppIcons.storeOutlined,
                                size: 40, color: AppColors.greyLt),
                            const SizedBox(height: 10),
                            Text(
                              _search.isEmpty
                                  ? 'No branches yet'
                                  : 'No results found',
                              style: const TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 13),
                            ),
                          ]),
                        ),
                      )
                          : Column(
                        children: [
                          // ── Header ──────────────────────────
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: const BoxDecoration(
                              color: AppColors.bg,
                              border: Border(
                                top: BorderSide(
                                    color: AppColors.border,
                                    width: 0.5),
                                bottom: BorderSide(
                                    color: AppColors.border,
                                    width: 0.5),
                              ),
                            ),
                            child: Row(children: [
                              _Th(
                                  label: 'Branch',
                                  col: 'name',
                                  flex: 3,
                                  sortCol: _sortCol,
                                  asc: _sortAsc,
                                  onSort: _setSort),
                              _Th(
                                  label: 'City',
                                  col: 'city',
                                  flex: 2,
                                  sortCol: _sortCol,
                                  asc: _sortAsc,
                                  onSort: _setSort),
                              _Th(
                                  label: 'Phone',
                                  col: 'phone',
                                  flex: 2,
                                  sortCol: _sortCol,
                                  asc: _sortAsc,
                                  onSort: _setSort),
                              _Th(
                                  label: 'Tables',
                                  col: 'tables',
                                  flex: 1,
                                  sortCol: _sortCol,
                                  asc: _sortAsc,
                                  onSort: _setSort),
                              _Th(
                                  label: 'Status',
                                  col: 'status',
                                  flex: 1,
                                  sortCol: _sortCol,
                                  asc: _sortAsc,
                                  onSort: _setSort),
                              const SizedBox(width: 80),
                            ]),
                          ),

                          // ── Rows ────────────────────────────
                          ...filtered.asMap().entries.map(
                                (e) => _BranchRow(
                              branch: e.value,
                              isEven: e.key % 2 == 0,
                              onEdit: () => _openModal(e.value),
                              onDelete: () =>
                                  _confirmDelete(e.value),
                              onToggle: () async {
                                await widget.datasource
                                    .toggleBranchStatus(
                                    e.value.id,
                                    !e.value.isOpen);
                                setState(() {
                                  _branches = _branches
                                      .map((b) => b.id ==
                                      e.value.id
                                      ? b.copyWith(
                                      isOpen: !b.isOpen)
                                      : b)
                                      .toList();
                                });
                              },
                            ),
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
      ],
    );
  }
}

// ─── Table Header ─────────────────────────────────────────────────────────────
class _Th extends StatelessWidget {
  final String label, col, sortCol;
  final bool asc;
  final int flex;
  final ValueChanged<String> onSort;

  const _Th({
    required this.label,
    required this.col,
    required this.sortCol,
    required this.asc,
    required this.flex,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final active = sortCol == col;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => onSort(col),
        child: Row(children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.primary : AppColors.grey,
                  letterSpacing: 0.3)),
          const SizedBox(width: 3),
          SvgIcon(
            active
                ? (asc ? AppIcons.arrowUpward : AppIcons.arrowDownward)
                : AppIcons.unfoldMore,
            size: 12,
            color: active ? AppColors.primary : AppColors.greyLt,
          ),
        ]),
      ),
    );
  }
}

// ─── Branch Row ───────────────────────────────────────────────────────────────
class _BranchRow extends StatefulWidget {
  final Branch branch;
  final bool isEven;
  final VoidCallback onEdit, onDelete, onToggle;

  const _BranchRow({
    required this.branch,
    required this.isEven,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  State<_BranchRow> createState() => _BranchRowState();
}

class _BranchRowState extends State<_BranchRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.branch;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: _hover
              ? b.color.withOpacity(0.04)
              : widget.isEven
              ? AppColors.white
              : AppColors.bg.withOpacity(0.4),
          border: const Border(
              bottom: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            // ── Branch name + color dot ──────────────────────────────
            Expanded(
              flex: 3,
              child: Row(children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: b.color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                      color: b.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(7)),
                  child: SvgIcon(AppIcons.storeOutlined,
                      color: b.color, size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.name,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.dark),
                            overflow: TextOverflow.ellipsis),
                        Text(b.ntn.isEmpty ? '—' : b.ntn,
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.grey)),
                      ]),
                ),
              ]),
            ),

            // ── City ────────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: Text(b.city,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.dark)),
            ),

            // ── Phone ───────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: Text(b.phone.isEmpty ? '—' : b.phone,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.dark)),
            ),

            // ── Tables ──────────────────────────────────────────────
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: AppColors.infoLt,
                    borderRadius: BorderRadius.circular(6)),
                child: Text('${b.tables}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info),
                    textAlign: TextAlign.center),
              ),
            ),

            // ── Status ──────────────────────────────────────────────
            Expanded(flex: 1, child: StatusBadge(isOpen: b.isOpen)),

            // ── Actions ─────────────────────────────────────────────
            SizedBox(
              width: 80,
              child: AnimatedOpacity(
                opacity: _hover ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _IconBtn(
                      icon: b.isOpen
                          ? AppIcons.toggleOnRounded
                          : AppIcons.toggleOffRounded,
                      color: b.isOpen
                          ? AppColors.success
                          : AppColors.grey,
                      tooltip: b.isOpen ? 'Mark Closed' : 'Mark Open',
                      onTap: widget.onToggle,
                    ),
                    const SizedBox(width: 2),
                    _IconBtn(
                      icon: AppIcons.editOutlined,
                      color: AppColors.primary,
                      tooltip: 'Edit',
                      onTap: widget.onEdit,
                    ),
                    const SizedBox(width: 2),
                    _IconBtn(
                      icon: AppIcons.deleteOutlineRounded,
                      color: AppColors.danger,
                      tooltip: 'Delete',
                      onTap: widget.onDelete,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Icon Button ──────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final AppIcon icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6)),
        child: SvgIcon(icon, size: 13, color: color),
      ),
    ),
  );
}