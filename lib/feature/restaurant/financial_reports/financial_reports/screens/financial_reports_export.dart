import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/financial_reports_models.dart';
import '../widgets/report_helpers.dart' show formatCurrency, formatFullDate;

// ─── PDF Export ───────────────────────────────────────────────────────────────
Future<void> exportReportPdf({
  required BuildContext context,
  required FinancialSummary summary,
  required List<ProductReport> products,
  required List<ExpenseReport> expenses,
  required DateTime startDate,
  required DateTime endDate,
  required String restaurantName,
}) async {
  final pdf = pw.Document();

  final regular = await PdfGoogleFonts.notoSansRegular();
  final bold    = await PdfGoogleFonts.notoSansBold();

  final accent = PdfColor.fromHex('B91C1C');
  final red    = PdfColor.fromHex('EF4444');
  final green  = PdfColor.fromHex('22C55E');
  final muted  = PdfColor.fromHex('6B7280');
  final border = PdfColor.fromHex('E5E7EB');
  final light  = PdfColor.fromHex('F9FAFB');

  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    build: (ctx) => [
      // ── Header ──────────────────────────────────────────────────────────────
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(restaurantName, style: pw.TextStyle(font: bold, fontSize: 18, color: accent)),
          pw.SizedBox(height: 4),
          pw.Text('Financial Report', style: pw.TextStyle(font: regular, fontSize: 12, color: muted)),
          pw.Text(
            '${formatFullDate(startDate)}  –  ${formatFullDate(endDate)}',
            style: pw.TextStyle(font: regular, fontSize: 10, color: muted),
          ),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('Net Profit', style: pw.TextStyle(font: regular, fontSize: 10, color: muted)),
          pw.Text(
            formatCurrency(summary.netProfit),
            style: pw.TextStyle(
              font: bold, fontSize: 20,
              color: summary.netProfit >= 0 ? green : red,
            ),
          ),
        ]),
      ]),
      pw.Divider(color: border, thickness: 1),
      pw.SizedBox(height: 8),

      // ── P&L Summary ─────────────────────────────────────────────────────────
      pw.Text('Profit & Loss Summary', style: pw.TextStyle(font: bold, fontSize: 13)),
      pw.SizedBox(height: 8),
      pw.Table(
        border: pw.TableBorder.all(color: border, width: 0.5),
        children: [
          _pdfHeaderRow(['Metric', 'Amount'], bold, light, accent),
          _pdfRow(['Total Revenue', formatCurrency(summary.totalRevenue)], regular, PdfColors.white),
          _pdfRow(['Cost of Goods Sold', '− ${formatCurrency(summary.totalCost)}'], regular, light),
          _pdfRow(['Gross Profit (${summary.grossMargin.toStringAsFixed(1)}%)', formatCurrency(summary.grossProfit)], bold, PdfColors.white),
          _pdfRow(['Operating Expenses', '− ${formatCurrency(summary.totalExpenses)}'], regular, light),
          _pdfRow(['Net Profit (${summary.netMargin.toStringAsFixed(1)}%)', formatCurrency(summary.netProfit)], bold, PdfColors.white),
        ],
      ),
      pw.SizedBox(height: 16),

      // ── Order Stats ──────────────────────────────────────────────────────────
      pw.Text('Order Statistics', style: pw.TextStyle(font: bold, fontSize: 13)),
      pw.SizedBox(height: 8),
      pw.Table(
        border: pw.TableBorder.all(color: border, width: 0.5),
        children: [
          _pdfHeaderRow(['Stat', 'Value'], bold, light, accent),
          _pdfRow(['Total Orders', summary.totalOrders.toString()], regular, PdfColors.white),
          _pdfRow(['Paid Orders', summary.paidOrders.toString()], regular, light),
          _pdfRow(['Unpaid Orders', summary.unpaidOrders.toString()], regular, PdfColors.white),
          _pdfRow(['Avg Order Value', formatCurrency(summary.averageOrderValue)], regular, light),
          _pdfRow(['Cash Revenue', formatCurrency(summary.cashRevenue)], regular, PdfColors.white),
          _pdfRow(['Card Revenue', formatCurrency(summary.cardRevenue)], regular, light),
          _pdfRow(['Online Revenue', formatCurrency(summary.onlineRevenue)], regular, PdfColors.white),
        ],
      ),
      pw.SizedBox(height: 16),

      // ── Top Products ─────────────────────────────────────────────────────────
      if (products.isNotEmpty) ...[
        pw.Text('Top Products by Revenue', style: pw.TextStyle(font: bold, fontSize: 13)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: border, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(2),
            5: const pw.FlexColumnWidth(1),
          },
          children: [
            _pdfHeaderRow(['Item', 'Category', 'Qty', 'Revenue', 'Profit', 'Margin'], bold, light, accent),
            ...products.take(20).toList().asMap().entries.map((e) {
              final p = e.value;
              return _pdfRow([
                p.itemName,
                p.categoryName,
                p.quantitySold.toString(),
                formatCurrency(p.revenue),
                formatCurrency(p.profit),
                '${p.margin.toStringAsFixed(0)}%',
              ], regular, e.key.isEven ? PdfColors.white : light);
            }),
          ],
        ),
        pw.SizedBox(height: 16),
      ],

      // ── Expenses ─────────────────────────────────────────────────────────────
      if (expenses.isNotEmpty) ...[
        pw.Text('Expenses Breakdown', style: pw.TextStyle(font: bold, fontSize: 13)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: border, width: 0.5),
          children: [
            _pdfHeaderRow(['Category', 'Transactions', 'Amount', 'Share'], bold, light, accent),
            ...expenses.asMap().entries.map((e) {
              final exp = e.value;
              final pct = summary.totalExpenses == 0 ? 0.0 : exp.amount / summary.totalExpenses * 100;
              return _pdfRow([
                exp.category,
                exp.count.toString(),
                formatCurrency(exp.amount),
                '${pct.toStringAsFixed(1)}%',
              ], regular, e.key.isEven ? PdfColors.white : light);
            }),
          ],
        ),
      ],

      pw.SizedBox(height: 24),
      pw.Divider(color: border),
      pw.Text(
        'Generated on ${formatFullDate(DateTime.now())} · Spice Garden POS',
        style: pw.TextStyle(font: regular, fontSize: 8, color: muted),
      ),
    ],
  ));

  await Printing.sharePdf(
    bytes: await pdf.save(),
    filename: 'financial_report_${startDate.year}${startDate.month.toString().padLeft(2, '0')}${startDate.day.toString().padLeft(2, '0')}.pdf',
  );
}

pw.TableRow _pdfHeaderRow(List<String> cells, pw.Font bold, PdfColor bg, PdfColor textColor) =>
    pw.TableRow(
      decoration: pw.BoxDecoration(color: bg),
      children: cells.map((c) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(c, style: pw.TextStyle(font: bold, fontSize: 9, color: textColor)),
      )).toList(),
    );

pw.TableRow _pdfRow(List<String> cells, pw.Font font, PdfColor bg) =>
    pw.TableRow(
      decoration: pw.BoxDecoration(color: bg),
      children: cells.map((c) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: pw.Text(c, style: pw.TextStyle(font: font, fontSize: 9)),
      )).toList(),
    );

// ─── CSV Export ───────────────────────────────────────────────────────────────
String buildReportCsv({
  required FinancialSummary summary,
  required List<ProductReport> products,
  required List<ExpenseReport> expenses,
  required DateTime startDate,
  required DateTime endDate,
}) {
  final buf = StringBuffer();

  buf.writeln('FINANCIAL REPORT');
  buf.writeln('Period,${formatFullDate(startDate)} - ${formatFullDate(endDate)}');
  buf.writeln();

  buf.writeln('PROFIT & LOSS');
  buf.writeln('Metric,Amount');
  buf.writeln('Total Revenue,${summary.totalRevenue.toStringAsFixed(2)}');
  buf.writeln('Cost of Goods Sold,${summary.totalCost.toStringAsFixed(2)}');
  buf.writeln('Gross Profit,${summary.grossProfit.toStringAsFixed(2)}');
  buf.writeln('Gross Margin %,${summary.grossMargin.toStringAsFixed(2)}');
  buf.writeln('Operating Expenses,${summary.totalExpenses.toStringAsFixed(2)}');
  buf.writeln('Net Profit,${summary.netProfit.toStringAsFixed(2)}');
  buf.writeln('Net Margin %,${summary.netMargin.toStringAsFixed(2)}');
  buf.writeln();

  buf.writeln('ORDERS');
  buf.writeln('Total Orders,${summary.totalOrders}');
  buf.writeln('Paid Orders,${summary.paidOrders}');
  buf.writeln('Unpaid Orders,${summary.unpaidOrders}');
  buf.writeln('Average Order Value,${summary.averageOrderValue.toStringAsFixed(2)}');
  buf.writeln('Cash Revenue,${summary.cashRevenue.toStringAsFixed(2)}');
  buf.writeln('Card Revenue,${summary.cardRevenue.toStringAsFixed(2)}');
  buf.writeln('Online Revenue,${summary.onlineRevenue.toStringAsFixed(2)}');
  buf.writeln();

  if (products.isNotEmpty) {
    buf.writeln('PRODUCTS');
    buf.writeln('Item,Category,Quantity Sold,Revenue,Cost,Profit,Margin %');
    for (final p in products) {
      buf.writeln('"${p.itemName}","${p.categoryName}",${p.quantitySold},${p.revenue.toStringAsFixed(2)},${p.cost.toStringAsFixed(2)},${p.profit.toStringAsFixed(2)},${p.margin.toStringAsFixed(2)}');
    }
    buf.writeln();
  }

  if (expenses.isNotEmpty) {
    buf.writeln('EXPENSES');
    buf.writeln('Category,Transactions,Amount');
    for (final e in expenses) {
      buf.writeln('"${e.category}",${e.count},${e.amount.toStringAsFixed(2)}');
    }
  }

  return buf.toString();
}
