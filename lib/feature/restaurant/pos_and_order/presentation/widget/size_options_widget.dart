import 'package:flutter/material.dart';
import 'package:resturent_application/core/constants/currency.dart';
import '../../data/model/order_model.dart';

const _sizeColors = [
  Color(0xFF1B5E20),
  Color(0xFF2196F3),
  Color(0xFFAD1457),
  Color(0xFFE65100),
  Color(0xFF6A3FA0),
];

/// Shown in place of the menu grid when an item has sizes: pick one to add it to the invoice.
class SizeOptionsWidget extends StatelessWidget {
  final MenuProduct product;
  final ValueChanged<ProductSize> onSelect;
  final VoidCallback onCancel;

  const SizeOptionsWidget({
    super.key,
    required this.product,
    required this.onSelect,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1F5FC4), Color(0xFF4F95DD)],
        ),
      ),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${product.name} : Options',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'CANCEL',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: 150,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF9B51C0),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Size',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.white,
                  child: Text(
                    '?',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white54, height: 16),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              for (final (i, sz) in product.sizes.indexed)
                Container(
                  decoration: const BoxDecoration(
                    boxShadow: [
                      BoxShadow(color: Colors.black87, offset: Offset(3, 3)),
                    ],
                  ),
                  child: Material(
                    color: _sizeColors[i % _sizeColors.length],
                    child: InkWell(
                      onTap: () => onSelect(sz),
                      child: SizedBox(
                        width: 170,
                        height: 110,
                        child: Stack(
                          children: [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
                                child: Text(
                                  sz.name.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: Text(
                                formatMoney(sz.price),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
