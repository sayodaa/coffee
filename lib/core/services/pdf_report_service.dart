import 'package:coffee_app/features/inventory/domain/entities/inventory_item.dart';
import 'package:coffee_app/features/reports/domain/report_models.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportService {
  /// Set this from SettingsCubit at startup (or when settings change)
  /// so that every generated PDF uses the configured shop name.
  static String shopName = 'Coffee Shop';

  static Future<pw.Document> _createDocument() async {
    return pw.Document();
  }

  static pw.PageTheme _buildTheme(pw.Font arabicFont, pw.Font arabicBold) {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(
        base: arabicFont,
        bold: arabicBold,
      ),
      textDirection: pw.TextDirection.rtl,
    );
  }

  static Future<void> _shareOrPrintPdf(String title, pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: title,
    );
  }

  static pw.Widget _buildHeader(String reportTitle, String dateRange) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(shopName,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text(reportTitle, style: pw.TextStyle(fontSize: 18)),
        pw.SizedBox(height: 4),
        pw.Text(dateRange,
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} / ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
      ),
    );
  }

  // ==========================================
  // 1. Sales Report (generic)
  // ==========================================
  static Future<void> generateSalesReport(
      List<SalesItem> sales, DateTime start, DateTime end, String title) async {
    final pdf = await _createDocument();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final dateRangeStr =
        '${DateFormat('yyyy-MM-dd').format(start)} to ${DateFormat('yyyy-MM-dd').format(end)}';

    double totalRevenue = 0;
    int totalItems = 0;
    for (var s in sales) {
      totalRevenue += s.totalPrice;
      totalItems += s.quantity;
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _buildTheme(font, fontBold),
        header: (context) => _buildHeader(title, dateRangeStr),
        footer: _buildFooter,
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: ['Time', 'Drink Name', 'Quantity', 'Unit Price', 'Total'],
            data: sales.map((s) {
              return [
                DateFormat('HH:mm').format(s.timestamp),
                s.drinkName,
                s.quantity.toString(),
                '${s.price.toStringAsFixed(2)} \$',
                '${s.totalPrice.toStringAsFixed(2)} \$',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.center,
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Items Sold: $totalItems',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Total Revenue: ${totalRevenue.toStringAsFixed(2)} \$',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );

    await _shareOrPrintPdf(title, pdf);
  }

  // ====================================================
  // 1a. Daily Sales PDF (today only)
  // ====================================================
  static Future<void> generateDailySalesPDF(List<SalesItem> sales) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    await generateSalesReport(sales, start, start, 'Daily Sales Report');
  }

  // ====================================================
  // 1b. Weekly Sales PDF (last 7 days)
  // ====================================================
  static Future<void> generateWeeklySalesPDF(List<SalesItem> sales) async {
    final today = DateTime.now();
    final end = DateTime(today.year, today.month, today.day);
    final start = end.subtract(const Duration(days: 6));
    await generateSalesReport(sales, start, end, 'Weekly Sales Report');
  }

  // ====================================================
  // 1c. Monthly Sales PDF (current month)
  // ====================================================
  static Future<void> generateMonthlySalesPDF(List<SalesItem> sales) async {
    final today = DateTime.now();
    final end = DateTime(today.year, today.month, today.day);
    final start = DateTime(today.year, today.month, 1);
    await generateSalesReport(sales, start, end, 'Monthly Sales Report');
  }

  // ==========================================
  // 2. Inventory / Low Stock Report
  // ==========================================
  static Future<void> generateInventoryReport(
      List<InventoryItem> items, bool onlyLowStock) async {
    final pdf = await _createDocument();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final title = onlyLowStock ? 'Low Stock Report' : 'Full Inventory Report';
    final dateRangeStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final filteredItems =
        onlyLowStock ? items.where((i) => i.isLowStock).toList() : items;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _buildTheme(font, fontBold),
        header: (context) => _buildHeader(title, dateRangeStr),
        footer: _buildFooter,
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: [
              'SKU',
              'Item Name',
              'Category',
              'Quantity',
              'Unit',
              'Price'
            ],
            data: filteredItems.map((item) {
              return [
                item.sku,
                item.name,
                item.quantity.toString(),
                item.unit,
                '${item.price.toStringAsFixed(2)} \$',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.center,
          ),
          pw.SizedBox(height: 20),
          pw.Text('Total Items: ${filteredItems.length}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );

    await _shareOrPrintPdf(title, pdf);
  }

  // ====================================================
  // 2a. Low Stock PDF shortcut
  // ====================================================
  static Future<void> generateLowStockPDF(List<InventoryItem> items) async {
    await generateInventoryReport(items, true);
  }

  // ==========================================
  // 3. Consumption & Waste Report
  // ==========================================
  static Future<void> generateConsumptionReport(
      ReportData data, DateTime start, DateTime end) async {
    final pdf = await _createDocument();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    const title = 'Consumption & Waste Report';
    final dateRangeStr =
        '${DateFormat('yyyy-MM-dd').format(start)} to ${DateFormat('yyyy-MM-dd').format(end)}';

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _buildTheme(font, fontBold),
        header: (context) => _buildHeader(title, dateRangeStr),
        footer: _buildFooter,
        build: (context) => [
          pw.Header(level: 1, text: 'Executive Summary'),
          pw.Paragraph(
            text: 'Stock Accuracy: ${data.stockAccuracy.toStringAsFixed(1)}%\n'
                'Total Waste (Value): ${data.totalMonthlyWaste.toStringAsFixed(2)} \$\n'
                'Expected Loss Value: ${data.expectedLossValue.toStringAsFixed(2)} \$',
          ),
          pw.SizedBox(height: 10),
          pw.Header(level: 1, text: 'Loss Analysis (Item level)'),
          pw.TableHelper.fromTextArray(
            headers: [
              'Item Name',
              'Expected (Sold)',
              'Actual (Out)',
              'Difference'
            ],
            data: data.lossAnalysis.map((loss) {
              return [
                loss.itemName,
                loss.expected.toStringAsFixed(1),
                loss.actual.toStringAsFixed(1),
                loss.difference.toStringAsFixed(1),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.center,
          ),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, text: 'Waste Reasons'),
          pw.TableHelper.fromTextArray(
            headers: ['Reason', 'Amount'],
            data: data.wasteAnalysis.map((w) {
              return [w.reason, w.amount.toStringAsFixed(1)];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.center,
          ),
        ],
      ),
    );

    await _shareOrPrintPdf(title, pdf);
  }
}
