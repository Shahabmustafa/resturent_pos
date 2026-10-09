import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../pos_and_order/data/model/order_model.dart';
import '../../../setting/data/model/branch_setting_model.dart';
import '../../../setting/data/model/receipt_settings_model.dart';
import '../../../setting/presentation/provider/receipt_settings_provider.dart';
import 'package:resturent_application/core/constants/currency.dart';

// ── Font cache — downloaded once, then served from memory ────────────────────
pw.Font? _cachedRegular;
pw.Font? _cachedBold;

Future<(pw.Font, pw.Font)> _getFonts() async {
  _cachedRegular ??= await PdfGoogleFonts.notoSansRegular();
  _cachedBold    ??= await PdfGoogleFonts.notoSansBold();
  return (_cachedRegular!, _cachedBold!);
}

class ReceiptPrintDialog extends ConsumerStatefulWidget {
  final OrderModel order;
  const ReceiptPrintDialog({super.key, required this.order});

  @override
  ConsumerState<ReceiptPrintDialog> createState() => _ReceiptPrintDialogState();
}

class _ReceiptPrintDialogState extends ConsumerState<ReceiptPrintDialog> {
  bool _printing = false;

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(receiptSettingsProvider);
    final settings      = settingsState.settings;
    final branchAsync   = ref.watch(receiptBranchProvider);
    final branch        = branchAsync.value;

    return Dialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: kBorder)),
              ),
              child: Row(children: [
                const SvgIcon(AppIcons.receiptLongRounded, color: kPrimary, size: 18),
                const SizedBox(width: 8),
                Text('Receipt — ${widget.order.orderNumber}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kText)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const SvgIcon(AppIcons.closeRounded, size: 18, color: kMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
            ),

            // Preview
            if (settingsState.loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: kPrimary),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: _ReceiptPreview(order: widget.order, settings: settings, branch: branch),
                  ),
                ),
              ),

            // Actions
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: kBorder)),
              ),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kMuted,
                      side: const BorderSide(color: kBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: (settings == null || _printing)
                        ? null
                        : () async {
                      setState(() => _printing = true);
                      try {
                        await _printReceipt(context, widget.order, settings, branch);
                      } finally {
                        if (mounted) setState(() => _printing = false);
                      }
                    },
                    icon: _printing
                        ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const SvgIcon(AppIcons.printRounded, size: 16),
                    label: Text(_printing ? 'Preparing...' : 'Print Receipt',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  /// The receipt still prints when the logo can't be downloaded — just without it.
  static Future<pw.ImageProvider?> _loadLogo(String url) async {
    try {
      return await networkImage(url);
    } catch (_) {
      return null;
    }
  }

  Future<void> _printReceipt(
      BuildContext context, OrderModel order, ReceiptSettings s, BranchModel? branch) async {
    final doc = pw.Document();

    // FIX: load fonts + logo in parallel (uses the cache too)
    final hasLogo = s.showLogo && s.logoUrl != null && s.logoUrl!.isNotEmpty;
    final results = await Future.wait([
      _getFonts(),
      if (hasLogo)
        _loadLogo(s.logoUrl!)
      else
        Future.value(null),
    ]);

    final (regularFont, boldFont) = results[0] as (pw.Font, pw.Font);
    pw.MemoryImage? logoImage;
    try {
      if (hasLogo && results[1] != null) {
        logoImage = results[1] as pw.MemoryImage;
      }
    } catch (_) {}

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat(
        58 * PdfPageFormat.mm,
        double.infinity,
        marginAll: 5 * PdfPageFormat.mm,
      ),
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logoImage != null) ...[
            pw.Image(logoImage, width: 42, height: 42, fit: pw.BoxFit.contain),
            pw.SizedBox(height: 6),
          ],
          pw.Text(
              branch?.restaurantName.isNotEmpty == true
                  ? branch!.restaurantName
                  : branch?.name ?? '',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
          if ((branch?.address ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(branch!.address,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center),
          ],
          if ((branch?.phone ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 1),
            pw.Text(branch!.phone,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center),
          ],
          if (s.headerNote.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(s.headerNote,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center),
          ],
          pw.SizedBox(height: 8),
          _dashedDivider(),
          pw.SizedBox(height: 6),

          // Order info
          _pdfRow('Order #', order.orderNumber, boldValue: true),
          if (order.tableNumber.isNotEmpty) _pdfRow('Table', order.tableNumber),
          if (order.customerName.isNotEmpty) _pdfRow('Customer', order.customerName),
          _pdfRow('Type', order.orderType),
          _pdfRow('Payment', order.paymentMethod),
          _pdfRow('Date', _formatDate(order.createdAt)),
          pw.SizedBox(height: 6),
          _dashedDivider(),
          pw.SizedBox(height: 6),

          // Items header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('ITEM', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
              pw.Text('AMOUNT', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 4),

          // Items
          ...order.items.map((item) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        item.itemName,
                        style: const pw.TextStyle(fontSize: 9.5),
                      ),
                    ),
                    pw.Text(formatMoney(item.totalPrice),
                        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Text(
                  '${item.qty} x ${formatMoney(item.totalPrice / item.qty)}'
                      '${item.size.isNotEmpty ? '  •  ${item.size}' : ''}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          )),
          pw.SizedBox(height: 4),
          _dashedDivider(),
          pw.SizedBox(height: 6),

          // Bill
          _pdfRow('Subtotal', formatMoney(order.subtotal)),
          if (order.discountAmt > 0)
            _pdfRow('Discount', '- ${formatMoney(order.discountAmt)}'),
          if (s.showTaxBreakdown)
            _pdfRow('Tax (${order.taxPct.toStringAsFixed(0)}%)',
                formatMoney(order.taxAmt)),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(width: 1, color: PdfColors.black),
                bottom: pw.BorderSide(width: 1, color: PdfColors.black),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
                pw.Text(formatMoney(order.total),
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.SizedBox(height: 8),

          // Payment status
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 0.7, color: PdfColors.black),
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text(order.paymentStatus.toUpperCase(),
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
          ),
          if (s.showCashierName) ...[
            pw.SizedBox(height: 6),
            pw.Text('Cashier: ${branch?.name ?? 'N/A'}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ],
          pw.SizedBox(height: 10),

          if (s.footerText.isNotEmpty)
            pw.Text(s.footerText,
                style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
                textAlign: pw.TextAlign.center),
        ],
      ),
    ));

    // FIX: sharePdf is faster on web — layoutPdf was slow through the browser print dialog
    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'receipt_${order.orderNumber.replaceAll('#', '')}.pdf',
    );
  }

  pw.Widget _pdfRow(String label, String value, {bool boldValue = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.Text(value,
            style: pw.TextStyle(fontSize: 9, fontWeight: boldValue ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    ),
  );

  // Dashed line — reads better on thermal paper than a solid pw.Divider.
  pw.Widget _dashedDivider() => pw.LayoutBuilder(
    builder: (ctx, constraints) {
      final width = constraints?.maxWidth ?? 180;
      const dashWidth = 3.0, gap = 2.0;
      final count = (width / (dashWidth + gap)).floor();
      return pw.Row(
        children: List.generate(
          count,
              (_) => pw.Container(width: dashWidth, height: 0.7, color: PdfColors.grey500,
              margin: const pw.EdgeInsets.only(right: gap)),
        ),
      );
    },
  );

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ── Flutter Receipt Preview (in dialog) ──────────────────────────────────────

class _ReceiptPreview extends StatelessWidget {
  final OrderModel order;
  final ReceiptSettings? settings;
  final BranchModel? branch;
  const _ReceiptPreview({required this.order, required this.settings, required this.branch});

  Color _statusColor(String status) => kPrimary;

  @override
  Widget build(BuildContext context) {
    final s = settings;
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: CustomPaint(
        painter: _ZigzagEdgePainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
          child: Column(children: [
            if (s?.showLogo == true && s?.logoUrl != null && s!.logoUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(s.logoUrl!, width: 42, height: 42, fit: BoxFit.contain),
              ),
              const SizedBox(height: 8),
            ],
            Text(
                branch?.restaurantName.isNotEmpty == true
                    ? branch!.restaurantName
                    : branch?.name ?? '',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: 0.3)),
            if ((branch?.address ?? '').isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(branch!.address,
                  style: const TextStyle(fontSize: 9.5, color: Colors.black45),
                  textAlign: TextAlign.center),
            ],
            if ((branch?.phone ?? '').isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(branch!.phone,
                  style: const TextStyle(fontSize: 9.5, color: Colors.black45)),
            ],
            if (s != null && s.headerNote.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(s.headerNote,
                  style: const TextStyle(fontSize: 9.5, color: Colors.black45),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 10),
            const _DashedDivider(),
            const SizedBox(height: 8),
            _RRow(l: 'Order #', r: order.orderNumber, bold: true),
            if (order.tableNumber.isNotEmpty) _RRow(l: 'Table', r: order.tableNumber),
            if (order.customerName.isNotEmpty) _RRow(l: 'Customer', r: order.customerName),
            _RRow(l: 'Type', r: order.orderType),
            _RRow(l: 'Payment', r: order.paymentMethod),
            _RRow(l: 'Date', r: '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}'),
            const SizedBox(height: 8),
            const _DashedDivider(),
            const SizedBox(height: 8),
            Row(children: const [
              Text('ITEM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.black38, letterSpacing: 0.3)),
              Spacer(),
              Text('AMOUNT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.black38, letterSpacing: 0.3)),
            ]),
            const SizedBox(height: 6),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(item.itemName,
                        style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600)),
                  ),
                  Text(formatMoney(item.totalPrice),
                      style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w700)),
                ]),
                Text(
                  '${item.qty} x ${formatMoney(item.totalPrice / item.qty)}'
                      '${item.size.isNotEmpty ? '  •  ${item.size}' : ''}',
                  style: const TextStyle(fontSize: 9.5, color: Colors.black38),
                ),
              ]),
            )),
            const SizedBox(height: 4),
            const _DashedDivider(),
            const SizedBox(height: 8),
            _RRow(l: 'Subtotal', r: formatMoney(order.subtotal)),
            if (order.discountAmt > 0)
              _RRow(l: 'Discount', r: '- ${formatMoney(order.discountAmt)}'),
            if (s?.showTaxBreakdown == true)
              _RRow(l: 'Tax (${order.taxPct.toStringAsFixed(0)}%)',
                  r: formatMoney(order.taxAmt)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.black87, width: 1.2),
                  bottom: BorderSide(color: Colors.black87, width: 1.2),
                ),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('TOTAL', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                Text(formatMoney(order.total),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(order.paymentStatus).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _statusColor(order.paymentStatus).withValues(alpha: 0.4)),
              ),
              child: Text(order.paymentStatus.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4,
                      color: _statusColor(order.paymentStatus))),
            ),
            if (s?.showCashierName == true) ...[
              const SizedBox(height: 8),
              Text('Cashier: ${branch?.name ?? 'N/A'}',
                  style: const TextStyle(fontSize: 9.5, color: Colors.black45)),
            ],
            if (s != null && s.footerText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(s.footerText,
                  style: const TextStyle(fontSize: 10.5, color: Colors.black54, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center),
            ],
          ]),
        ),
      ),
    );
  }
}

// Dashed divider for the Flutter preview (matches the PDF's dashed rule)
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const dashWidth = 4.0, gap = 3.0;
      final count = (constraints.maxWidth / (dashWidth + gap)).floor();
      return Row(
        children: List.generate(
          count,
              (_) => Container(width: dashWidth, height: 1, color: const Color(0xFFD8D8D8),
              margin: const EdgeInsets.only(right: gap)),
        ),
      );
    });
  }
}

// Perforated/zigzag bottom edge to mimic a torn thermal receipt strip
class _ZigzagEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    const toothWidth = 10.0;
    final path = Path()..moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - 6);
    var x = size.width;
    var down = true;
    while (x > 0) {
      x -= toothWidth;
      path.lineTo(x, down ? size.height : size.height - 6);
      down = !down;
    }
    path.close();
    canvas.drawShadow(path, Colors.black26, 4, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RRow extends StatelessWidget {
  final String l, r;
  final bool bold;
  const _RRow({required this.l, required this.r, this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: TextStyle(fontSize: 11, color: Colors.black54,
            fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
        Text(r, style: TextStyle(fontSize: 11, color: Colors.black,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
      ],
    ),
  );
}