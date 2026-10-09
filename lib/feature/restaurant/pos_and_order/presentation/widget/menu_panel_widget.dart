import 'package:resturent_application/core/widget/shimmer.dart';
import 'pos_skeleton.dart';
import 'package:resturent_application/core/widget/app_tab_bar.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../data/model/order_model.dart';
import 'package:resturent_application/core/constants/currency.dart';

class MenuPanelWidget extends StatefulWidget {
  final List<MenuProduct>         products;
  final List<MenuProduct>         deals;
  final int                       cartCount;
  final ValueChanged<MenuProduct> onAddToCart;
  final Map<String, int>          cartItemIds;
  final VoidCallback              onViewCart;
  final double                    cartTotal;
  final bool                      isLoading;

  const MenuPanelWidget({
    super.key,
    required this.products,
    required this.deals,
    required this.cartCount,
    required this.onAddToCart,
    required this.cartItemIds,
    required this.onViewCart,
    required this.cartTotal,
    this.isLoading = false,
  });

  @override
  State<MenuPanelWidget> createState() => _MenuPanelWidgetState();
}

class _MenuPanelWidgetState extends State<MenuPanelWidget> {
  String _selectedTab = 'menu'; // 'menu' | 'deals'
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MenuProduct> get _tabItems =>
      _selectedTab == 'deals' ? widget.deals : widget.products;

  List<MenuProduct> get _currentItems {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _tabItems;
    return _tabItems.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile    = MediaQuery.of(context).size.width < 800;
    return Column(children: [
      _buildTabBar(),
      const Divider(height: 1, color: kBorder),
      Expanded(child: _buildContent()),
      if (widget.cartCount > 0) isMobile ? _buildMobileCartBar() : SizedBox(),
    ]);
  }

  // ─── Tab Bar ──────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: kCard,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(children: [
        AppTabBar(
          index: _selectedTab == 'deals' ? 1 : 0,
          onChanged: (i) => setState(() => _selectedTab = i == 1 ? 'deals' : 'menu'),
          items: [
            AppTabItem('Menu Items', icon: AppIcons.menuBookRounded, count: widget.isLoading ? null : widget.products.length),
            AppTabItem('Deals', icon: AppIcons.localOfferRounded, count: widget.isLoading ? null : widget.deals.length),
          ],
        ),
        const SizedBox(height: 10),
        _buildSearchField(),
      ]),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _query = v),
      style: const TextStyle(fontSize: 13, color: kText),
      decoration: InputDecoration(
        hintText: _selectedTab == 'deals' ? 'Search deals...' : 'Search menu items...',
        hintStyle: const TextStyle(color: kMuted, fontSize: 13),
        prefixIcon: const Padding(
          padding: EdgeInsets.all(12),
          child: SvgIcon(AppIcons.searchOutlined, size: 18, color: kMuted),
        ),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: const SvgIcon(AppIcons.closeOutlined, size: 16, color: kMuted),
                onPressed: () => setState(() {
                  _searchCtrl.clear();
                  _query = '';
                }),
              ),
        filled: true,
        fillColor: kLight,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPrimary, width: 1.5)),
      ),
    );
  }

  // ─── Content ──────────────────────────────────────────────────────────────

  Widget _buildContent() {
    if (widget.isLoading) {
      return const ProductGridSkeleton();
    }
    if (_currentItems.isEmpty) {
      final searching = _query.trim().isNotEmpty;
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SvgIcon(
            searching ? AppIcons.searchOffOutlined : AppIcons.restaurantMenuOutlined,
            size: 44,
            color: kMuted.withOpacity(0.6),
          ),
          const SizedBox(height: 10),
          Text(
            searching
                ? 'No results for "${_query.trim()}"'
                : _selectedTab == 'deals' ? 'No deals available' : 'No menu items found',
            style: const TextStyle(color: kMuted, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ]),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        crossAxisSpacing:   12,
        mainAxisSpacing:    12,
        childAspectRatio:   0.78,
      ),
      itemCount: _currentItems.length,
      itemBuilder: (_, i) {
        final p = _currentItems[i];
        return ProductCardWidget(
          product: p,
          cartQty: widget.cartItemIds[p.id] ?? 0,
          onAdd:   () => widget.onAddToCart(p),
        );
      },
    );
  }

  // ─── Mobile Cart Bar ──────────────────────────────────────────────────────

  Widget _buildMobileCartBar() {
    return GestureDetector(
      onTap: widget.onViewCart,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFB91C1C), Color(0xFFDC2626)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${widget.cartCount}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          const Text('View Cart / Checkout',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          Text(formatMoney(widget.cartTotal),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(width: 8),
          const SvgIcon(AppIcons.arrowForwardRounded, color: Colors.white, size: 18),
        ]),
      ),
    );
  }
}

// ─── Product Card ─────────────────────────────────────────────────────────────

class ProductCardWidget extends StatelessWidget {
  final MenuProduct  product;
  final int          cartQty;
  final VoidCallback onAdd;

  const ProductCardWidget({
    super.key,
    required this.product,
    required this.cartQty,
    required this.onAdd,
  });

  bool get _inCart => cartQty > 0;
  bool get _soldOut => !product.isAvailable;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _soldOut ? null : onAdd,
      child: Opacity(
        opacity: _soldOut ? 0.55 : 1,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _inCart ? kPrimary.withOpacity(0.5) : kBorder,
            width: _inCart ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:      _inCart ? kPrimary.withOpacity(0.12) : const Color(0x08000020),
              blurRadius: _inCart ? 10 : 6,
              offset:     const Offset(0, 3),
            ),
          ],
        ),
        child: Column(children: [
          Expanded(child: _buildImageSection()),
          _buildNamePriceSection(),
        ]),
      ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(children: [
      ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
        child: product.imageUrl != null && !product.isDeal
            ? Image.network(
          product.imageUrl!,
          width: double.infinity, height: double.infinity, fit: BoxFit.cover,
          errorBuilder:   (_, __, ___) => _fallbackImage(),
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : const Shimmer(child: SizedBox.expand(child: ShimmerBox(radius: 0))),
        )
            : _fallbackImage(),
      ),
      // Cart quantity badge
      if (_inCart)
        Positioned(
          top: 6, right: 6,
          child: Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: kPrimary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1))],
            ),
            child: Center(
              child: Text('$cartQty',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      // Deal badge
      if (product.isDeal)
        Positioned(
          top: 6, left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFAA88FF), borderRadius: BorderRadius.circular(6)),
            child: const Text('DEAL',
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
          ),
        ),
      if (_soldOut)
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.35),
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(6)),
              child: const Text('SOLD OUT',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
          ),
        ),
      // Sizes badge
      if (product.sizes.isNotEmpty)
        Positioned(
          bottom: 6, left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text('Sizes',
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
          ),
        ),
    ]);
  }

  Widget _buildNamePriceSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(product.name,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: _inCart ? kText : kSub),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Row(children: [
          Text(
            product.sizes.isNotEmpty
                ? 'From ${formatMoney(product.sizes.first.price)}'
                : formatMoney(product.price),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kPrimary),
          ),
          const Spacer(),
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: _inCart ? kPrimary : kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SvgIcon(AppIcons.addRounded, size: 14, color: _inCart ? Colors.white : kPrimary),
          ),
        ]),
      ]),
    );
  }

  Widget _fallbackImage() => Container(
    width: double.infinity, height: double.infinity,
    color: kLight,
    child: Center(child: Text(product.isDeal ? '🎁' : '🍽️',
        style: const TextStyle(fontSize: 36))),
  );
}