import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/provider/branch_auth_provider.dart';
import '../../data/model/menu_model.dart';
import '../provider/menu_provider.dart';
import 'package:resturent_application/core/constants/currency.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────
InputDecoration _dec({String hint = ''}) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFFBBBDCC)),
  filled: true,
  fillColor: kLight,
  contentPadding:
  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kBorder)),
  enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kBorder)),
  focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kPrimary, width: 1.5)),
);

Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: kSub)));

// ── Image picking — bytes based (Web + Desktop + Mobile) ────────────────────
Future<List<PickedImage>> _pickImages() async {
  const typeGroup =
  XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png', 'webp']);
  final files = await openFiles(acceptedTypeGroups: [typeGroup]);
  return [
    for (final file in files)
      PickedImage(
        bytes: await file.readAsBytes(),
        mimeType: file.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg',
      ),
  ];
}

// ── Sizes Editor Widget ───────────────────────────────────────────────────────
class SizesEditorWidget extends StatefulWidget {
  final List<ItemSize> initialSizes;
  final ValueChanged<List<ItemSize>> onChanged;
  final String priceLabel;
  final String title;
  final String hint;
  final String emptyText;

  const SizesEditorWidget({
    super.key,
    required this.initialSizes,
    required this.onChanged,
    this.priceLabel = 'Price',
    this.title = 'Sizes (optional)',
    this.hint = 'Add sizes if applicable (Small/Medium/Large or 6"/8"/12")',
    this.emptyText = 'No sizes — single price will be used',
  });

  @override
  State<SizesEditorWidget> createState() => _SizesEditorWidgetState();
}

class _SizesEditorWidgetState extends State<SizesEditorWidget> {
  late List<_SizeRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = widget.initialSizes
        .map((s) => _SizeRow(
      nameCtrl: TextEditingController(text: s.name),
      priceCtrl:
      TextEditingController(text: s.price > 0 ? amountInputText(s.price) : ''),
    ))
        .toList();
  }

  void _addRow() {
    setState(() => _rows.add(_SizeRow(
        nameCtrl: TextEditingController(),
        priceCtrl: TextEditingController())));
    _notify();
  }

  void _removeRow(int i) {
    setState(() => _rows.removeAt(i));
    _notify();
  }

  void _notify() {
    final sizes = _rows
        .map((r) => ItemSize.temp(
      name: r.nameCtrl.text.trim(),
      price: double.tryParse(r.priceCtrl.text) ?? 0,
      sortOrder: _rows.indexOf(r),
    ))
        .where((s) => s.name.isNotEmpty)
        .toList();
    widget.onChanged(sizes);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const SvgIcon(AppIcons.straightenRounded, size: 14, color: kPrimary),
        const SizedBox(width: 6),
        _label(widget.title),
        const Spacer(),
        GestureDetector(
          onTap: _addRow,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kPrimary.withOpacity(0.3)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              SvgIcon(AppIcons.addRounded, size: 14, color: kPrimary),
              SizedBox(width: 4),
              Text('Add Size',
                  style: TextStyle(
                      fontSize: 12,
                      color: kPrimary,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 4),
      Text(widget.hint, style: const TextStyle(fontSize: 11, color: kMuted)),
      const SizedBox(height: 8),
      if (_rows.isEmpty)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: kLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kBorder)),
          child: Row(children: [
            const SvgIcon(AppIcons.infoOutlineRounded, size: 14, color: kMuted),
            const SizedBox(width: 8),
            Text(widget.emptyText, style: const TextStyle(fontSize: 12, color: kMuted)),
          ]),
        )
      else
        Column(children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              const Expanded(
                  flex: 2,
                  child: Text('Size Name',
                      style: TextStyle(
                          fontSize: 11,
                          color: kMuted,
                          fontWeight: FontWeight.w600))),
              const SizedBox(width: 8),
              Expanded(
                  flex: 2,
                  child: Text(widget.priceLabel,
                      style: const TextStyle(
                          fontSize: 11,
                          color: kMuted,
                          fontWeight: FontWeight.w600))),
              const SizedBox(width: 32),
            ]),
          ),
          ..._rows.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(
                    flex: 2,
                    child: TextField(
                        controller: row.nameCtrl,
                        onChanged: (_) => _notify(),
                        style: const TextStyle(fontSize: 13, color: kText),
                        decoration: _dec(hint: 'e.g. Small, 6"'))),
                const SizedBox(width: 8),
                Expanded(
                    flex: 2,
                    child: TextField(
                        controller: row.priceCtrl,
                        onChanged: (_) => _notify(),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13, color: kText),
                        decoration: _dec(hint: '8.50'))),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _removeRow(i),
                  icon: const SvgIcon(AppIcons.removeCircleOutlineRounded,
                      size: 18, color: Colors.redAccent),
                  padding: EdgeInsets.zero,
                  constraints:
                  const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ]),
            );
          }),
        ]),
    ]);
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.nameCtrl.dispose();
      r.priceCtrl.dispose();
    }
    super.dispose();
  }
}

class _SizeRow {
  final TextEditingController nameCtrl, priceCtrl;
  _SizeRow({required this.nameCtrl, required this.priceCtrl});
}

// ── CATEGORY DIALOG ───────────────────────────────────────────────────────────
class CategoryDialog extends ConsumerStatefulWidget {
  final MenuCategory? existing;
  final Function(MenuCategory) onSave;
  const CategoryDialog({super.key, this.existing, required this.onSave});

  @override
  ConsumerState<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<CategoryDialog> {
  late TextEditingController _name, _desc;
  int _colorIdx = 0;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _desc = TextEditingController(text: widget.existing?.description ?? '');
    _colorIdx = widget.existing?.colorIndex ?? 0;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        SvgIcon(
            widget.existing == null
                ? AppIcons.addCircleRounded
                : AppIcons.editRounded,
            color: kPrimary,
            size: 20),
        const SizedBox(width: 8),
        Text(
            widget.existing == null ? 'Add Category' : 'Edit Category',
            style: const TextStyle(
                color: kText,
                fontWeight: FontWeight.w800,
                fontSize: 16)),
      ]),
      content: SizedBox(
        width: 380,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Category Name *'),
              TextField(
                  controller: _name,
                  style: const TextStyle(fontSize: 14, color: kText),
                  decoration: _dec(hint: 'e.g. Pizza, BBQ, Drinks')),
              const SizedBox(height: 14),
              _label('Description'),
              TextField(
                  controller: _desc,
                  style: const TextStyle(fontSize: 14, color: kText),
                  decoration: _dec(hint: 'Short description')),
              const SizedBox(height: 14),
              _label('Select Color'),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(kCategoryShades.length, (i) {
                  final c = kCategoryShades[i];
                  final sel = _colorIdx == i;
                  return GestureDetector(
                    onTap: () => setState(() => _colorIdx = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: sel ? kText : Colors.transparent,
                            width: 2.5),
                        boxShadow: sel
                            ? [BoxShadow(
                            color: c.withOpacity(0.5), blurRadius: 6)]
                            : [],
                      ),
                      child: sel
                          ? const SvgIcon(AppIcons.checkRounded,
                          color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }),
              ),
            ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            const Text('Cancel', style: TextStyle(color: kMuted))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            final branchId = widget.existing?.branchId ??
                ref.read(branchAuthProvider).branch!.branchId;
            widget.onSave(MenuCategory(
              id: widget.existing?.id ?? '',
              branchId: branchId,
              name: _name.text.trim(),
              description: _desc.text.trim(),
              colorIndex: _colorIdx,
            ));
            Navigator.pop(context);
          },
          child: const Text('Save',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ── MENU ITEM DIALOG ──────────────────────────────────────────────────────────
/// One photo in the item form: already uploaded ([url]) or just picked ([picked]).
class _Photo {
  final String? url;
  final PickedImage? picked;
  const _Photo.url(String this.url) : picked = null;
  const _Photo.picked(PickedImage this.picked) : url = null;
}

class MenuItemDialog extends ConsumerStatefulWidget {
  final MenuItem? existing;
  /// Receives the item, photos still to upload, and uploaded photos that were removed.
  final void Function(MenuItem item, List<PickedImage> newImages, List<String> removedUrls) onSave;
  const MenuItemDialog({super.key, this.existing, required this.onSave});

  @override
  ConsumerState<MenuItemDialog> createState() => _MenuItemDialogState();
}

class _MenuItemDialogState extends ConsumerState<MenuItemDialog> {
  late final TextEditingController _name;
  String? _catId;
  late List<_Photo> _photos;
  bool _picking = false;
  late List<ItemSize> _sizes;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _catId = e?.categoryId;
    _photos = [for (final url in e?.imageUrls ?? const <String>[]) _Photo.url(url)];
    // Items saved without sizes had one price; show it as a single "Regular" size.
    _sizes = e == null
        ? [ItemSize.temp(name: 'Small', price: 0), ItemSize.temp(name: 'Large', price: 0, sortOrder: 1)]
        : e.sizes.isNotEmpty
            ? List.of(e.sizes)
            : [ItemSize.temp(name: 'Regular', price: e.price)];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    setState(() => _picking = true);
    try {
      final picked = await _pickImages();
      if (picked.isNotEmpty) setState(() => _photos.addAll(picked.map(_Photo.picked)));
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
    if (mounted) setState(() => _picking = false);
  }

  bool get _canSave =>
      _name.text.trim().isNotEmpty && _sizes.isNotEmpty && _sizes.every((s) => s.price > 0);

  void _save() {
    if (!_canSave) return;
    final cats = ref.read(menuProvider).categories;
    final existing = widget.existing;
    final keptUrls = [for (final p in _photos) if (p.url != null) p.url!];
    final item = MenuItem(
      id: existing?.id ?? '',
      branchId: existing?.branchId ?? ref.read(branchAuthProvider).branch!.branchId,
      name: _name.text.trim(),
      // Base price = cheapest size, so lists and "from" prices stay correct.
      price: _sizes.map((s) => s.price).reduce((a, b) => a < b ? a : b),
      costPrice: existing?.costPrice ?? 0,
      imageUrl: keptUrls.isEmpty ? null : keptUrls.first,
      imageUrls: keptUrls,
      categoryId: _catId ?? (cats.isNotEmpty ? cats.first.id : null),
      isAvailable: existing?.isAvailable ?? true,
      sizes: _sizes,
      ingredients: existing?.ingredients ?? const [],
    );
    widget.onSave(
      item,
      [for (final p in _photos) if (p.picked != null) p.picked!],
      [for (final url in existing?.imageUrls ?? const <String>[]) if (!keptUrls.contains(url)) url],
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.read(menuProvider).categories;
    if (_catId == null && cats.isNotEmpty) _catId = cats.first.id;

    return AlertDialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        SvgIcon(widget.existing == null ? AppIcons.addCircleRounded : AppIcons.editRounded,
            color: kPrimary, size: 20),
        const SizedBox(width: 8),
        Text(widget.existing == null ? 'Add Menu Item' : 'Edit Item',
            style: const TextStyle(color: kText, fontWeight: FontWeight.w800, fontSize: 16)),
      ]),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Images ──
              _label('Images'),
              Wrap(spacing: 10, runSpacing: 10, children: [
                for (var i = 0; i < _photos.length; i++)
                  _PhotoTile(
                    photo: _photos[i],
                    isCover: i == 0,
                    onRemove: () => setState(() => _photos.removeAt(i)),
                  ),
                _AddPhotoTile(loading: _picking, onTap: _picking ? null : _addPhotos),
              ]),
              const SizedBox(height: 6),
              const Text('You can pick several photos at once. The first one is the cover.',
                  style: TextStyle(fontSize: 11, color: kMuted)),
              const SizedBox(height: 16),

              // ── Name ──
              _label('Item Name *'),
              TextField(
                controller: _name,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 14, color: kText),
                decoration: _dec(hint: 'e.g. Chicken Tikka Pizza'),
              ),
              const SizedBox(height: 14),

              // ── Category ──
              _label('Category *'),
              DropdownButtonFormField<String>(
                value: cats.any((c) => c.id == _catId) ? _catId : (cats.isNotEmpty ? cats.first.id : null),
                decoration: _dec(),
                style: const TextStyle(fontSize: 14, color: kText),
                items: cats
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Row(children: [
                            Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: c.color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(c.name),
                          ]),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _catId = v),
              ),
              const SizedBox(height: 16),

              // ── Sizes & prices ──
              const Divider(color: kBorder),
              const SizedBox(height: 8),
              SizesEditorWidget(
                initialSizes: _sizes,
                title: 'Sizes & Prices *',
                hint: 'Set a price for each size. Add or remove sizes as needed.',
                emptyText: 'Add at least one size with a price',
                priceLabel: 'Price (£)',
                onChanged: (sizes) => setState(() => _sizes = sizes),
              ),

              if (!_canSave && _name.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2))),
                  child: const Row(children: [
                    SvgIcon(AppIcons.errorOutlineRounded, size: 14, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Every size needs a name and a price',
                          style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                    ),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kMuted))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _canSave ? kPrimary : kMuted,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _canSave ? _save : null,
          child: const Text('Save Item', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final _Photo photo;
  final bool isCover;
  final VoidCallback onRemove;

  const _PhotoTile({required this.photo, required this.isCover, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    const size = 96.0;
    final image = photo.picked != null
        ? Image.memory(photo.picked!.bytes, fit: BoxFit.cover, width: size, height: size)
        : Image.network(photo.url!,
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorBuilder: (_, _, _) => const Center(
                child: SvgIcon(AppIcons.addPhotoAlternateRounded, size: 22, color: kMuted)));

    return SizedBox(
      width: size,
      height: size,
      child: Stack(children: [
        Container(
          decoration: BoxDecoration(
            color: kLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isCover ? kPrimary : kBorder, width: isCover ? 1.5 : 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: image,
        ),
        if (isCover)
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(6)),
              child: const Text('Cover',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(3),
                child: SvgIcon(AppIcons.closeRounded, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;

  const _AddPhotoTile({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: kLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kPrimary.withValues(alpha: 0.35)),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)))
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                SvgIcon(AppIcons.addPhotoAlternateRounded, size: 28, color: kPrimary.withValues(alpha: 0.7)),
                const SizedBox(height: 4),
                const Text('Add photos', style: TextStyle(fontSize: 11, color: kMuted)),
              ]),
      ),
    );
  }
}

// ── DEAL DIALOG ───────────────────────────────────────────────────────────────
class DealDialog extends ConsumerStatefulWidget {
  final Deal? existing;
  final Function(Deal) onSave;
  const DealDialog({super.key, this.existing, required this.onSave});

  @override
  ConsumerState<DealDialog> createState() => _DealDialogState();
}

class _DealDialogState extends ConsumerState<DealDialog> {
  late TextEditingController _name, _price, _desc;
  late Set<String> _selectedIds;
  List<ItemSize> _sizes = [];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _price = TextEditingController(
        text: widget.existing?.dealPrice != null &&
            widget.existing!.dealPrice > 0
            ? amountInputText(widget.existing!.dealPrice)
            : '');
    _desc =
        TextEditingController(text: widget.existing?.description ?? '');
    _selectedIds = Set.from(widget.existing?.itemIds ?? []);
    _sizes = List.from(widget.existing?.sizes ?? []);
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _desc.dispose();
    super.dispose();
  }

  double _origTotal(List<MenuItem> menuItems) =>
      _selectedIds.fold(0.0, (s, id) {
        final m = menuItems.firstWhere((m) => m.id == id,
            orElse: () => MenuItem(
                id: '', branchId: '', name: '', price: 0, costPrice: 0));
        return s + m.effectivePrice;
      });

  @override
  Widget build(BuildContext context) {
    final state = ref.read(menuProvider);
    final items = state.menuItems;
    final orig = _origTotal(items);
    final dealPr = _sizes.isNotEmpty
        ? _sizes.map((s) => s.price).reduce((a, b) => a < b ? a : b)
        : (double.tryParse(_price.text) ?? 0);
    final savings = orig - dealPr;

    return AlertDialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [
        SvgIcon(AppIcons.localOfferRounded, color: kPrimary, size: 20),
        SizedBox(width: 8),
        Text('Create Deal',
            style: TextStyle(
                color: kText,
                fontWeight: FontWeight.w800,
                fontSize: 16)),
      ]),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Deal Name *'),
                TextField(
                    controller: _name,
                    style: const TextStyle(fontSize: 14, color: kText),
                    decoration: _dec(hint: 'e.g. Family Deal #1')),
                const SizedBox(height: 14),

                _label('Description'),
                TextField(
                    controller: _desc,
                    style: const TextStyle(fontSize: 14, color: kText),
                    decoration:
                    _dec(hint: 'e.g. Pizza + Pasta + Wings')),
                const SizedBox(height: 14),

                _label(_sizes.isNotEmpty
                    ? 'Base Price (£) — overridden by sizes'
                    : 'Deal Price (£) *'),
                TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  enabled: _sizes.isEmpty,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                      fontSize: 14,
                      color: _sizes.isNotEmpty ? kMuted : kText),
                  decoration: _dec(hint: '2499'),
                ),
                const SizedBox(height: 14),

                if ((_price.text.isNotEmpty || _sizes.isNotEmpty) &&
                    _selectedIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: savings > 0
                          ? kPrimary.withOpacity(0.07)
                          : Colors.redAccent.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: savings > 0
                              ? kPrimary.withOpacity(0.2)
                              : Colors.redAccent.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      SvgIcon(
                          savings > 0
                              ? AppIcons.savingsRounded
                              : AppIcons.warningRounded,
                          size: 14,
                          color: savings > 0
                              ? kPrimary
                              : Colors.redAccent),
                      const SizedBox(width: 6),
                      Text('Original: ${formatMoney(orig)}',
                          style:
                          const TextStyle(fontSize: 12, color: kSub)),
                      const SizedBox(width: 8),
                      Text(
                          savings > 0
                              ? 'Savings: ${formatMoney(savings)}'
                              : 'Deal price is higher!',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: savings > 0
                                  ? kPrimary
                                  : Colors.redAccent)),
                    ]),
                  ),

                _label('Select Items *'),
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                      color: kLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kBorder)),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      final checked = _selectedIds.contains(item.id);
                      return InkWell(
                        onTap: () => setState(() => checked
                            ? _selectedIds.remove(item.id)
                            : _selectedIds.add(item.id)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                              color: checked
                                  ? kPrimary.withOpacity(0.06)
                                  : Colors.transparent,
                              border: Border(
                                  bottom: BorderSide(
                                      color: kBorder.withOpacity(0.5)))),
                          child: Row(children: [
                            AnimatedContainer(
                              duration:
                              const Duration(milliseconds: 150),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                  color: checked
                                      ? kPrimary
                                      : Colors.transparent,
                                  borderRadius:
                                  BorderRadius.circular(4),
                                  border: Border.all(
                                      color: checked
                                          ? kPrimary
                                          : kBorder,
                                      width: 1.5)),
                              child: checked
                                  ? const SvgIcon(AppIcons.checkRounded,
                                  size: 12, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: checked ? kText : kSub,
                                              fontWeight: checked
                                                  ? FontWeight.w600
                                                  : FontWeight.w400)),
                                      if (item.hasSizes)
                                        Text(
                                            item.sizes
                                                .map((s) =>
                                            '${s.name}: ${formatMoney(s.price)}')
                                                .join(' • '),
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: kMuted)),
                                    ])),
                            Text(
                                item.hasSizes
                                    ? '${formatMoney(item.effectivePrice)}+'
                                    : formatMoney(item.price),
                                style: const TextStyle(
                                    fontSize: 12, color: kMuted)),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
                if (_selectedIds.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('${_selectedIds.length} items selected',
                      style: const TextStyle(
                          fontSize: 11,
                          color: kPrimary,
                          fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 16),
                const Divider(color: kBorder),
                const SizedBox(height: 8),
                SizesEditorWidget(
                  initialSizes: _sizes,
                  priceLabel: 'Deal Price (£)',
                  onChanged: (sizes) => setState(() {
                    _sizes = sizes;
                    if (sizes.isNotEmpty) {
                      final lowest = sizes
                          .map((s) => s.price)
                          .reduce((a, b) => a < b ? a : b);
                      _price.text = lowest.toStringAsFixed(0);
                    }
                  }),
                ),
              ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            const Text('Cancel', style: TextStyle(color: kMuted))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          onPressed: () {
            if (_name.text.trim().isEmpty || _selectedIds.isEmpty) return;
            if (_sizes.isEmpty &&
                (double.tryParse(_price.text) ?? 0) <= 0) return;
            final branchId = widget.existing?.branchId ??
                ref.read(branchAuthProvider).branch!.branchId;
            widget.onSave(Deal(
              id: widget.existing?.id ?? '',
              branchId: branchId,
              name: _name.text.trim(),
              dealPrice: double.tryParse(_price.text) ?? 0,
              itemIds: _selectedIds.toList(),
              description: _desc.text.trim(),
              isAvailable: widget.existing?.isAvailable ?? true,
              sizes: _sizes,
            ));
            Navigator.pop(context);
          },
          child: const Text('Save Deal',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}