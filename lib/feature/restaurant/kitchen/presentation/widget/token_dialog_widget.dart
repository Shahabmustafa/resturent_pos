import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../data/model/kitchen_model.dart';

class TokenDialogWidget extends StatelessWidget {
  final KitchenOrder order;
  const TokenDialogWidget({super.key, required this.order});

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 340,
        decoration: BoxDecoration(
          color: kLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: kBorder)),
            ),
            child: Row(children: [
              const SvgIcon(AppIcons.receiptLongRounded, color: kPrimary, size: 20),
              const SizedBox(width: 8),
              const Text('Kitchen Token',
                  style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const SvgIcon(AppIcons.closeRounded, color: kMuted, size: 20),
              ),
            ]),
          ),

          // Token content (thermal print style)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDDD8C0), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0x20000000), blurRadius: 8, offset: Offset(0, 3))
              ],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              const Text('SPICE GARDEN',
                  style: TextStyle(
                      color: Color(0xFF1A1D3A),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2)),
              const Text('Kitchen Order Token',
                  style: TextStyle(color: Color(0xFF555555), fontSize: 10, letterSpacing: 1)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: DashedLineWidget(),
              ),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF333333), width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(order.orderNum,
                    style: const TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2)),
              ),
              const SizedBox(height: 10),

              TokenRowWidget('Type', order.orderType),
              if (order.table.isNotEmpty) TokenRowWidget('Table', order.table),
              if (order.customerName.isNotEmpty) TokenRowWidget('Customer', order.customerName),
              TokenRowWidget('Time', _fmt(order.createdAt)),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: DashedLineWidget(),
              ),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text('ITEMS',
                    style: TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5)),
              ),
              const SizedBox(height: 6),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(item.name,
                          style: const TextStyle(
                              color: Color(0xFF222222),
                              fontSize: 13,
                              fontWeight: FontWeight.w600))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF333333)),
                        borderRadius: BorderRadius.circular(3)),
                    child: Text('×${item.qty}',
                        style: const TextStyle(
                            color: Color(0xFF111111),
                            fontSize: 11,
                            fontWeight: FontWeight.w900)),
                  ),
                ]),
              )),

              if (order.notes.isNotEmpty) ...[
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8), child: DashedLineWidget()),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.08),
                    border: Border.all(color: kPrimary.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('SPECIAL NOTES:',
                        style: TextStyle(
                            color: kPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(order.notes,
                        style: const TextStyle(
                            color: Color(0xFF333300),
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ],

              const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: DashedLineWidget()),
              const Text('*** KITCHEN COPY ***',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 10, letterSpacing: 1)),
            ]),
          ),

          // Print button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kSub,
                    side: const BorderSide(color: kBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const SvgIcon(AppIcons.closeRounded, size: 14),
                  label: const Text('Close', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Token printed successfully!',style: TextStyle(fontWeight: FontWeight.w700)),
                      backgroundColor: kPrimary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ));
                  },
                  icon: const SvgIcon(AppIcons.printRounded, size: 16),
                  label: const Text('Print Token', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class TokenRowWidget extends StatelessWidget {
  final String label, value;
  const TokenRowWidget(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        SizedBox(
            width: 70,
            child: Text('$label:',
                style: const TextStyle(color: Color(0xFF666666), fontSize: 12))),
        Text(value,
            style: const TextStyle(
                color: Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class DashedLineWidget extends StatelessWidget {
  const DashedLineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 1,
      child: CustomPaint(painter: DashPainter()),
    );
  }
}

class DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBBBBAA)
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 6, 0), paint);
      x += 10;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}