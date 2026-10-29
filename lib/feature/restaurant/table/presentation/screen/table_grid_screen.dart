import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resturent_application/feature/restaurant/auth/presentation/provider/branch_auth_provider.dart';
import '../provider/table_provider.dart';
import '../widget/table_dialog_widget.dart';

const _bg = Color(0xFF105275);
const _footer = Color(0xFFE9E9E9);

enum _Mode { none, swap, merge }

/// Touch table picker for dine-in: tap a table to start or continue its order.
class TableGridScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<String> onSelect;
  const TableGridScreen({
    super.key,
    required this.onBack,
    required this.onSelect,
  });

  @override
  ConsumerState<TableGridScreen> createState() => _TableGridScreenState();
}

class _TableGridScreenState extends ConsumerState<TableGridScreen> {
  _Mode _mode = _Mode.none;
  String? _first;
  Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _loadBusy();
  }

  String get _branchId => ref.read(branchAuthProvider).branch!.branchId;

  Future<void> _loadBusy() async {
    try {
      final busy = await ref
          .read(tableDatasourceProvider)
          .fetchBusyTableNumbers(_branchId);
      if (mounted) setState(() => _busy = busy);
    } catch (_) {}
  }

  void _addTable() => showDialog(
    context: context,
    builder: (_) => AddTableDialog(
      nextNumber: ref.read(tableProvider).tables.length + 1,
      onAdd: (number) => ref.read(tableProvider.notifier).addTable(number),
    ),
  );

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _setMode(_Mode m) => setState(() {
    _mode = _mode == m ? _Mode.none : m;
    _first = null;
  });

  Future<void> _tap(String number) async {
    if (_mode == _Mode.none) return widget.onSelect(number);
    if (_first == null) {
      if (!_busy.contains(number))
        return _snack('Table $number has no open order');
      return setState(() => _first = number);
    }
    if (_first == number) return setState(() => _first = null);

    final ds = ref.read(tableDatasourceProvider);
    final from = _first!;
    final merge = _mode == _Mode.merge;
    try {
      if (merge) {
        await ds.mergeTables(_branchId, from, number);
      } else {
        await ds.swapTables(_branchId, from, number);
      }
      ref.read(tablesRefreshProvider.notifier).state++;
      await ref.read(tableProvider.notifier).fetchTables();
      await _loadBusy();
      _snack(
        merge
            ? 'Table $from merged into $number'
            : 'Tables $from and $number swapped',
      );
    } catch (e) {
      _snack('Could not ${merge ? 'merge' : 'swap'} tables');
    }
    if (mounted)
      setState(() {
        _mode = _Mode.none;
        _first = null;
      });
  }

  Widget _bottomButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool selected = false,
  }) => Padding(
    padding: const EdgeInsets.only(left: 6),
    child: SizedBox(
      width: 112,
      height: double.infinity,
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: selected
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tableProvider);
    final hint = switch (_mode) {
      _Mode.none => null,
      _Mode.swap =>
        _first == null
            ? 'Swap: choose the first table'
            : 'Swap: choose the table to swap $_first with',
      _Mode.merge =>
        _first == null
            ? 'Merge: choose the table to move'
            : 'Merge: choose the table to merge $_first into',
    };

    return Column(
      children: [
        Expanded(
          child: Container(
            color: _bg,
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            padding: const EdgeInsets.all(8),
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 36,
                        child: Center(
                          child: Text(
                            hint ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, c) {
                            // T2 before T10: compare the number part as a number.
                            int numberOf(String n) =>
                                int.tryParse(n.replaceAll(RegExp(r'\D'), '')) ??
                                0;
                            final tables = [...state.tables]
                              ..sort((a, b) {
                                final byNumber = numberOf(
                                  a.tableNumber,
                                ).compareTo(numberOf(b.tableNumber));
                                return byNumber != 0
                                    ? byNumber
                                    : a.tableNumber.compareTo(b.tableNumber);
                              });
                            if (tables.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No tables yet',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }
                            const cols = 5;
                            final rowH = (c.maxHeight / 4).clamp(90.0, 180.0);
                            return GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cols,
                                    mainAxisExtent: rowH,
                                    crossAxisSpacing: 2,
                                    mainAxisSpacing: 4,
                                  ),
                              itemCount: tables.length,
                              itemBuilder: (_, i) {
                                final n = tables[i].tableNumber;
                                final busy = _busy.contains(n);
                                final picked = _first == n;
                                return Material(
                                  color: picked
                                      ? const Color(0xFFFFD54F)
                                      : busy
                                      ? const Color(0xFFE6E6E6)
                                      : Colors.white,
                                  elevation: 2,
                                  child: InkWell(
                                    onTap: () => _tap(n),
                                    child: Center(
                                      child: Text(
                                        n,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        Container(
          height: 84,
          color: _footer,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _bottomButton(
                'Back',
                Icons.arrow_back,
                Colors.black,
                widget.onBack,
              ),
              const Spacer(),
              _bottomButton(
                'Add Table',
                Icons.add,
                const Color(0xFF2E7D32),
                _addTable,
              ),
              _bottomButton(
                'Swap',
                Icons.swap_vert,
                const Color(0xFFD2691E),
                () => _setMode(_Mode.swap),
                selected: _mode == _Mode.swap,
              ),
              _bottomButton(
                'Merge',
                Icons.call_merge,
                const Color(0xFF2347D6),
                () => _setMode(_Mode.merge),
                selected: _mode == _Mode.merge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
