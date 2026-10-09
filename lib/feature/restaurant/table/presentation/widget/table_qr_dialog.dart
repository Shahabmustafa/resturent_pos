import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../data/model/table_model.dart';

/// Asks for the website address (remembered), then prints one QR card per
/// table. Scanning a card opens the website at `?table=<token>`, where the
/// customer orders for that table without logging in.
class TableQrDialog extends StatefulWidget {
  final List<TableModel> tables;
  const TableQrDialog({super.key, required this.tables});

  @override
  State<TableQrDialog> createState() => _TableQrDialogState();
}

class _TableQrDialogState extends State<TableQrDialog> {
  static const _prefsKey = 'website_url';

  final _url = TextEditingController();
  bool _printing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance()
        .then((p) => _url.text = p.getString(_prefsKey) ?? '')
        .catchError((_) => '');
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  /// "example.com/" → "https://example.com"
  String? _normalized() {
    var url = _url.text.trim();
    if (url.isEmpty) return null;
    if (!url.startsWith('http://') && !url.startsWith('https://')) url = 'https://$url';
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return Uri.tryParse(url)?.host.isNotEmpty == true ? url : null;
  }

  Future<void> _print() async {
    final base = _normalized();
    if (base == null) {
      setState(() => _error = 'Enter your website address, e.g. order.myrestaurant.com');
      return;
    }
    setState(() {
      _error = null;
      _printing = true;
    });
    try {
      await (await SharedPreferences.getInstance()).setString(_prefsKey, base);
    } catch (_) {}
    try {
      final tables = widget.tables.where((t) => t.qrToken.isNotEmpty).toList();
      await Printing.layoutPdf(
        name: 'Table QR codes',
        onLayout: (format) async => (await _buildPdf(base, tables, format)).save(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = 'Couldn\'t print: $e');
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  static Future<pw.Document> _buildPdf(String base, List<TableModel> tables, PdfPageFormat format) async {
    final doc = pw.Document();
    const perPage = 4;
    for (var i = 0; i < tables.length; i += perPage) {
      final page = tables.skip(i).take(perPage).toList();
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => pw.Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [for (final t in page) _card(base, t)],
        ),
      ));
    }
    return doc;
  }

  static pw.Widget _card(String base, TableModel t) => pw.Container(
        width: 259,
        height: 370,
        padding: const pw.EdgeInsets.all(18),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 1),
          borderRadius: pw.BorderRadius.circular(14),
        ),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text('TABLE', style: pw.TextStyle(fontSize: 12, letterSpacing: 3, color: PdfColors.grey700)),
            pw.Text(t.tableNumber, style: pw.TextStyle(fontSize: 34, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 14),
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: '$base/?table=${t.qrToken}',
              width: 170,
              height: 170,
            ),
            pw.SizedBox(height: 14),
            pw.Text('Scan to see the menu and order',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 3),
            pw.Text('Pay at the counter when you\'re done',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final count = widget.tables.where((t) => t.qrToken.isNotEmpty).length;
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Table QR Codes', style: TextStyle(color: kText, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Prints a QR card for each of your $count tables. Customers scan it, '
            'see the menu and send their order — it appears here as a Dine-in order for that table.',
            style: const TextStyle(color: kSub, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Text('Website address', style: TextStyle(color: kText, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: _url,
            decoration: InputDecoration(
              hintText: 'e.g. order.myrestaurant.com',
              errorText: _error,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onSubmitted: (_) => _print(),
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: kMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _printing || count == 0 ? null : _print,
          child: Text(_printing ? 'Preparing…' : 'Print QR Codes', style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
