import 'package:resturent_application/core/widget/status_pill.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../data/model/table_model.dart';

class TableDataWidget extends StatelessWidget {
  final List<TableModel> tables;
  final List<TableModel> allTables;
  final String filterStatus, filterFloor, searchQuery;
  final List<String> floors;
  final ValueChanged<String> onStatusChanged, onFloorChanged, onSearchChanged;
  final ValueChanged<TableModel> onStatusTap, onDelete;

  const TableDataWidget({
    super.key,
    required this.tables,
    required this.allTables,
    required this.filterStatus,
    required this.filterFloor,
    required this.floors,
    required this.searchQuery,
    required this.onStatusChanged,
    required this.onFloorChanged,
    required this.onSearchChanged,
    required this.onStatusTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000020), blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Toolbar ─────────────────────────────────────────────────
          _Toolbar(
            filterStatus:    filterStatus,
            filterFloor:     filterFloor,
            floors:          floors,
            searchQuery:     searchQuery,
            resultCount:     tables.length,
            totalCount:      allTables.length,
            onStatusChanged: onStatusChanged,
            onFloorChanged:  onFloorChanged,
            onSearchChanged: onSearchChanged,
          ),

          // ── Table Header ─────────────────────────────────────────────
          const _TableHeader(),

          // ── Rows ─────────────────────────────────────────────────────
          tables.isEmpty
              ? _EmptyRow()
              : Column(
            children: tables.asMap().entries.map((e) {
              return _TableRow(
                table:       e.value,
                isLast:      e.key == tables.length - 1,
                onStatusTap: onStatusTap,
                onDelete:    onDelete,
              );
            }).toList(),
          ),

          // ── Footer ───────────────────────────────────────────────────
          _Footer(showing: tables.length, total: allTables.length),
        ],
      ),
    );
  }
}

// ── Toolbar ────────────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  final String filterStatus, filterFloor, searchQuery;
  final List<String> floors;
  final int resultCount, totalCount;
  final ValueChanged<String> onStatusChanged, onFloorChanged, onSearchChanged;

  const _Toolbar({
    required this.filterStatus,
    required this.filterFloor,
    required this.floors,
    required this.searchQuery,
    required this.resultCount,
    required this.totalCount,
    required this.onStatusChanged,
    required this.onFloorChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + search
          Row(
            children: [
              const Text('Tables',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: kText)),
              const Spacer(),
              // Search box
              SizedBox(
                width: 220,
                height: 36,
                child: TextField(
                  onChanged: onSearchChanged,
                  style: const TextStyle(fontSize: 13, color: kText),
                  decoration: InputDecoration(
                    hintText: 'Search table...',
                    hintStyle: const TextStyle(color: kMuted, fontSize: 13),
                    prefixIcon:
                    const SvgIcon(AppIcons.searchRounded, color: kMuted, size: 18),
                    filled: true,
                    fillColor: kLight,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: kBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: kBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                        const BorderSide(color: kPrimary, width: 1.5)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Status chips + floor dropdown
          Row(
            children: [
              // Status filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Available', 'Reserved', 'Cleaning']
                      .map((s) => _StatusChip(
                    label:      s,
                    isSelected: filterStatus == s,
                    onTap:      () => onStatusChanged(s),
                  ))
                      .toList(),
                ),
              ),

              const SizedBox(width: 12),

              // Floor dropdown
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: kLight,
                  border: Border.all(color: kBorder),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: filterFloor,
                    isDense: true,
                    style:
                    const TextStyle(fontSize: 12, color: kText),
                    icon: const SvgIcon(AppIcons.expandMoreRounded,
                        size: 16, color: kMuted),
                    items: floors
                        .map((f) => DropdownMenuItem(
                        value: f, child: Text(f)))
                        .toList(),
                    onChanged: (v) => onFloorChanged(v!),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _StatusChip(
      {required this.label, required this.isSelected, required this.onTap});

  Color get _color {
    switch (label) {
      case 'Available': return kGreen;
      case 'Reserved':  return kPrimary;
      case 'Cleaning':  return kYellow;
      default:          return kBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:        isSelected ? _color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border:       Border.all(
              color: isSelected ? _color.withOpacity(0.4) : kBorder),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize:   12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color:      isSelected ? _color : kMuted)),
      ),
    );
  }
}

// ── Table Header ─────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FC),
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: const Row(
        children: [
          _HCell('#',           flex: 1),
          _HCell('Table No.',   flex: 2),
          _HCell('Floor',       flex: 2),
          _HCell('Section',     flex: 2),
          _HCell('Capacity',    flex: 2),
          _HCell('Status',      flex: 2),
          _HCell('Actions',     flex: 2),
        ],
      ),
    );
  }
}

class _HCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text,
          style: const TextStyle(
              fontSize:      11,
              fontWeight:    FontWeight.w700,
              color:         kMuted,
              letterSpacing: 0.4)),
    );
  }
}

// ── Table Row ─────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  final TableModel table;
  final bool isLast;
  final ValueChanged<TableModel> onStatusTap, onDelete;

  const _TableRow({
    required this.table,
    required this.isLast,
    required this.onStatusTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = table.status.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF0F2F8))),
      ),
      child: Row(
        children: [
          // # index
          Expanded(
            flex: 1,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: kLight,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                table.tableNumber.replaceAll('T-', ''),
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: kMuted),
              ),
            ),
          ),

          // Table number
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: SvgIcon(AppIcons.tableRestaurantRounded,
                      color: statusColor, size: 14),
                ),
                const SizedBox(width: 8),
                Text(table.tableNumber,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kText)),
              ],
            ),
          ),

          // Floor
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const SvgIcon(AppIcons.layersOutlined, size: 13, color: kMuted),
                const SizedBox(width: 5),
                Text(table.floor.label,
                    style: const TextStyle(fontSize: 13, color: kSub)),
              ],
            ),
          ),

          // Section
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const SvgIcon(AppIcons.locationOnOutlined, size: 13, color: kMuted),
                const SizedBox(width: 5),
                Text(table.section.label,
                    style: const TextStyle(fontSize: 13, color: kSub)),
              ],
            ),
          ),

          // Capacity
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const SvgIcon(AppIcons.peopleOutlineRounded, size: 14, color: kMuted),
                const SizedBox(width: 5),
                Text('${table.capacity} seats',
                    style: const TextStyle(fontSize: 13, color: kSub)),
              ],
            ),
          ),

          // Status badge (tappable)
          Expanded(
            flex: 2,
            child: StatusPill(
              label:    table.status.label,
              color:    statusColor,
              icon:     table.status.icon,
              trailing: AppIcons.editRounded,
              tooltip:  'Change Status',
              onTap:    () => onStatusTap(table),
            ),
          ),

          // Actions
          Expanded(
            flex: 2,
            child: Row(
              children: [
                // Change status button
                _ActionBtn(
                  icon:    AppIcons.swapHorizRounded,
                  color:   kBlue,
                  tooltip: 'Change Status',
                  onTap:   () => onStatusTap(table),
                ),
                const SizedBox(width: 6),
                // Delete button
                _ActionBtn(
                  icon:    AppIcons.deleteOutlineRounded,
                  color:   Colors.redAccent,
                  tooltip: 'Delete',
                  onTap:   () => onDelete(table),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final AppIcon icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
        required this.color,
        required this.tooltip,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: SvgIcon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────

class _EmptyRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const SvgIcon(AppIcons.tableRestaurantRounded,
                  size: 40, color: kPrimary),
            ),
            const SizedBox(height: 14),
            const Text('No tables found',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
            const SizedBox(height: 6),
            const Text('Try changing the filter or add a new table',
                style: TextStyle(fontSize: 13, color: kMuted)),
          ],
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final int showing, total;
  const _Footer({required this.showing, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FC),
        border: Border(top: BorderSide(color: kBorder)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Text('Showing $showing of $total tables',
              style: const TextStyle(fontSize: 12, color: kMuted)),
        ],
      ),
    );
  }
}