import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice.dart';

class PdfService {
  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹ ',
    decimalDigits: 2,
  );

  static final NumberFormat _numFormat = NumberFormat('#,##,##0.00', 'en_IN');

  static String _formatCurrency(double val) => _inrFormat.format(val);
  static String _formatNum(double val) => _numFormat.format(val);

  static Future<Directory> getTargetSaveDirectory([String target = 'Downloads']) async {
    if (target.toLowerCase() == 'desktop') {
      try {
        final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
        if (home != null) {
          final desktop = Directory('$home/Desktop');
          if (desktop.existsSync()) return desktop;
        }
      } catch (_) {}
    }
    try {
      final d = await getDownloadsDirectory();
      if (d != null && d.existsSync()) return d;
    } catch (_) {}
    try {
      final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (home != null) {
        final downloads = Directory('$home/Downloads');
        if (downloads.existsSync()) return downloads;
      }
    } catch (_) {}
    return await getApplicationDocumentsDirectory();
  }

  static Future<String> exportPdf(Invoice invoice, {String? targetLocation}) async {
    final bytes = await generateInvoicePdf(invoice);
    final loc = targetLocation ?? invoice.companySettings.defaultSaveLocation;
    final dir = await getTargetSaveDirectory(loc);

    final safeNum = invoice.invoiceNumber.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final filePath = '${dir.path}/Tax_Invoice_$safeNum.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static Future<String> exportPdfToDownloads(Invoice invoice) async {
    return exportPdf(invoice, targetLocation: 'Downloads');
  }

  static Future<String> exportPdfToDesktop(Invoice invoice) async {
    return exportPdf(invoice, targetLocation: 'Desktop');
  }

  static Future<Uint8List> generateInvoicePdf(Invoice invoice) async {
    final pdf = pw.Document();

    // Load bundled Roboto fonts to reliably support Rupee symbol '₹' offline
    pw.Font fontRegular;
    pw.Font fontBold;
    pw.Font fontItalic;
    pw.Font fontBoldItalic;
    try {
      final regData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      final italicData = await rootBundle.load('assets/fonts/Roboto-Italic.ttf');
      final boldItalicData = await rootBundle.load('assets/fonts/Roboto-BoldItalic.ttf');
      fontRegular = pw.Font.ttf(regData);
      fontBold = pw.Font.ttf(boldData);
      fontItalic = pw.Font.ttf(italicData);
      fontBoldItalic = pw.Font.ttf(boldItalicData);
    } catch (_) {
      fontRegular = await PdfGoogleFonts.robotoRegular();
      fontBold = await PdfGoogleFonts.robotoBold();
      fontItalic = await PdfGoogleFonts.robotoItalic();
      fontBoldItalic = await PdfGoogleFonts.robotoBoldItalic();
    }

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      italic: fontItalic,
      boldItalic: fontBoldItalic,
    );

    // Load Signature Image (Custom uploaded image or bundled template signature)
    Uint8List? signatureImageBytes;
    if (invoice.companySettings.signatureImagePath.isNotEmpty) {
      final f = File(invoice.companySettings.signatureImagePath);
      if (f.existsSync()) {
        try {
          signatureImageBytes = f.readAsBytesSync();
        } catch (_) {}
      }
    }
    if (signatureImageBytes == null) {
      try {
        final d = await rootBundle.load('assets/images/default_signature.png');
        signatureImageBytes = d.buffer.asUint8List();
      } catch (_) {}
    }

    // Build UPI Payment URI for QR Code
    final upiUri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': invoice.companySettings.upiId.isNotEmpty
            ? invoice.companySettings.upiId
            : 'infobyteblr@sbi',
        'pn': invoice.companySettings.name,
        'tr': invoice.invoiceNumber,
        'tn': 'Tax Invoice ${invoice.invoiceNumber}',
        'am': invoice.grandTotal.toStringAsFixed(2),
        'cu': 'INR',
      },
    ).toString();

    const borderColor = PdfColor.fromInt(0xFF5A6268);
    final borderSide = pw.BorderSide(color: borderColor, width: 0.8);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: theme,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. Header Title: "Tax Invoice"
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Text(
                  'Tax Invoice',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF2C3E50),
                  ),
                ),
              ),

              // 2. Main Outer Container with Border
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 1.0),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // --- SELLER HEADER ---
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Left: Company Info
                          pw.Expanded(
                            flex: 6,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  invoice.companySettings.name.toUpperCase(),
                                  style: pw.TextStyle(
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColor.fromInt(0xFF1F2937),
                                  ),
                                ),
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  invoice.companySettings.address,
                                  style: const pw.TextStyle(
                                    fontSize: 8.5,
                                    lineSpacing: 1.5,
                                    color: PdfColors.black,
                                  ),
                                ),
                                pw.SizedBox(height: 3),
                                pw.RichText(
                                  text: pw.TextSpan(
                                    text: 'Phone: ',
                                    style: const pw.TextStyle(
                                      fontSize: 8.5,
                                      color: PdfColors.black,
                                    ),
                                    children: [
                                      pw.TextSpan(
                                        text: invoice.companySettings.phone,
                                        style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                pw.SizedBox(height: 1),
                                pw.RichText(
                                  text: pw.TextSpan(
                                    text: 'GSTIN: ',
                                    style: const pw.TextStyle(
                                      fontSize: 8.5,
                                      color: PdfColors.black,
                                    ),
                                    children: [
                                      pw.TextSpan(
                                        text: invoice.companySettings.gstin,
                                        style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Right: Email & State
                          pw.Expanded(
                            flex: 5,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.SizedBox(height: 18),
                                pw.RichText(
                                  text: pw.TextSpan(
                                    text: 'Email: ',
                                    style: const pw.TextStyle(
                                      fontSize: 8.5,
                                      color: PdfColors.black,
                                    ),
                                    children: [
                                      pw.TextSpan(
                                        text: invoice.companySettings.email,
                                        style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                pw.SizedBox(height: 3),
                                pw.RichText(
                                  text: pw.TextSpan(
                                    text: 'State: ',
                                    style: const pw.TextStyle(
                                      fontSize: 8.5,
                                      color: PdfColors.black,
                                    ),
                                    children: [
                                      pw.TextSpan(
                                        text: invoice.companySettings.state,
                                        style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border(top: borderSide),
                      ),
                    ),

                    // --- BILL TO & INVOICE DETAILS ---
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Left Column: Bill To
                        pw.Expanded(
                          flex: 1,
                          child: pw.Container(
                            decoration: pw.BoxDecoration(
                              border: pw.Border(right: borderSide),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Container(
                                  width: double.infinity,
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border(bottom: borderSide),
                                  ),
                                  child: pw.Text(
                                    'Bill To:',
                                    style: pw.TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColor.fromInt(0xFF1F2937),
                                    ),
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        invoice.customerName.toUpperCase(),
                                        style: pw.TextStyle(
                                          fontSize: 9,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                      pw.SizedBox(height: 2),
                                      pw.Text(
                                        invoice.customerAddress,
                                        style: const pw.TextStyle(
                                          fontSize: 8.5,
                                          lineSpacing: 1.3,
                                        ),
                                      ),
                                      pw.SizedBox(height: 4),
                                      pw.Row(
                                        children: [
                                          pw.Text(
                                            'Contact No: ',
                                            style: const pw.TextStyle(
                                              fontSize: 8.5,
                                            ),
                                          ),
                                          pw.Text(
                                            invoice.customerPhone,
                                            style: pw.TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                          pw.SizedBox(width: 14),
                                          pw.Text(
                                            'GSTIN Number: ',
                                            style: const pw.TextStyle(
                                              fontSize: 8.5,
                                            ),
                                          ),
                                          pw.Text(
                                            invoice.customerGstin,
                                            style: pw.TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      pw.SizedBox(height: 2),
                                      pw.RichText(
                                        text: pw.TextSpan(
                                          text: 'State: ',
                                          style: const pw.TextStyle(
                                            fontSize: 8.5,
                                          ),
                                          children: [
                                            pw.TextSpan(
                                              text: invoice.customerState,
                                              style: pw.TextStyle(
                                                fontWeight: pw.FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Right Column: Invoice Details
                        pw.Expanded(
                          flex: 1,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                width: double.infinity,
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: pw.BoxDecoration(
                                  border: pw.Border(bottom: borderSide),
                                ),
                                child: pw.Text(
                                  'Invoice Details:',
                                  style: pw.TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColor.fromInt(0xFF1F2937),
                                  ),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.RichText(
                                      text: pw.TextSpan(
                                        text: 'No: ',
                                        style: const pw.TextStyle(
                                          fontSize: 8.5,
                                        ),
                                        children: [
                                          pw.TextSpan(
                                            text: invoice.invoiceNumber,
                                            style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    pw.SizedBox(height: 3),
                                    pw.RichText(
                                      text: pw.TextSpan(
                                        text: 'Date: ',
                                        style: const pw.TextStyle(
                                          fontSize: 8.5,
                                        ),
                                        children: [
                                          pw.TextSpan(
                                            text: invoice.date,
                                            style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    pw.SizedBox(height: 3),
                                    pw.RichText(
                                      text: pw.TextSpan(
                                        text: 'Place of Supply: ',
                                        style: const pw.TextStyle(
                                          fontSize: 8.5,
                                        ),
                                        children: [
                                          pw.TextSpan(
                                            text: invoice.placeOfSupply,
                                            style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Divider
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border(top: borderSide),
                      ),
                    ),

                    // --- ITEMS TABLE ---
                    pw.Table(
                      border: pw.TableBorder(
                        horizontalInside: borderSide,
                        verticalInside: borderSide,
                        bottom: borderSide,
                      ),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(0.5), // #
                        1: pw.FlexColumnWidth(3.4), // Item name
                        2: pw.FlexColumnWidth(1.1), // HSN/SAC
                        3: pw.FlexColumnWidth(1.0), // Quantity
                        4: pw.FlexColumnWidth(0.9), // Unit
                        5: pw.FlexColumnWidth(1.5), // Price/Unit
                        6: pw.FlexColumnWidth(1.5), // GST
                        7: pw.FlexColumnWidth(1.6), // Amount
                      },
                      children: [
                        // Table Header
                        pw.TableRow(
                          children: [
                            _buildTableHeaderCell('#', align: pw.TextAlign.center),
                            _buildTableHeaderCell('Item name'),
                            _buildTableHeaderCell('HSN/ SAC', align: pw.TextAlign.center),
                            _buildTableHeaderCell('Quantity', align: pw.TextAlign.center),
                            _buildTableHeaderCell('Unit', align: pw.TextAlign.center),
                            _buildTableHeaderCell('Price/ Unit\n(₹)', align: pw.TextAlign.right),
                            _buildTableHeaderCell('GST(₹)', align: pw.TextAlign.right),
                            _buildTableHeaderCell('Amount(₹)', align: pw.TextAlign.right),
                          ],
                        ),

                        // Item Rows
                        ...invoice.items.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final item = entry.value;
                          return pw.TableRow(
                            children: [
                              _buildTableCell(
                                '$idx',
                                align: pw.TextAlign.center,
                                isBold: true,
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 5,
                                ),
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      item.name,
                                      style: pw.TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                    if (item.serialNo.trim().isNotEmpty) ...[
                                      pw.SizedBox(height: 2),
                                      pw.Text(
                                        item.serialNo.trim(),
                                        style: const pw.TextStyle(
                                          fontSize: 7.5,
                                          color: PdfColors.grey700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              _buildTableCell(
                                item.hsnSac,
                                align: pw.TextAlign.center,
                              ),
                              _buildTableCell(
                                item.quantity % 1 == 0
                                    ? item.quantity.toInt().toString()
                                    : item.quantity.toStringAsFixed(2),
                                align: pw.TextAlign.center,
                              ),
                              _buildTableCell(
                                item.unit,
                                align: pw.TextAlign.center,
                              ),
                              _buildTableCell(
                                _formatCurrency(item.price),
                                align: pw.TextAlign.right,
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 5,
                                ),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  children: [
                                    pw.Text(
                                      _formatCurrency(item.gstAmount),
                                      style: const pw.TextStyle(fontSize: 8.5),
                                    ),
                                    pw.Text(
                                      '(${item.gstRate.toStringAsFixed(1)}%)',
                                      style: const pw.TextStyle(
                                        fontSize: 7.5,
                                        color: PdfColors.grey700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildTableCell(
                                _formatCurrency(item.totalAmount),
                                align: pw.TextAlign.right,
                              ),
                            ],
                          );
                        }),

                        // Total Row of Item Table
                        pw.TableRow(
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              alignment: pw.Alignment.centerLeft,
                              child: pw.Text(
                                '',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 8.5,
                                ),
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: pw.Text(
                                'Total',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 8.5,
                                ),
                              ),
                            ),
                            pw.Container(),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                invoice.totalQuantity % 1 == 0
                                    ? invoice.totalQuantity.toInt().toString()
                                    : invoice.totalQuantity.toStringAsFixed(2),
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 8.5,
                                ),
                              ),
                            ),
                            pw.Container(),
                            pw.Container(),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                _formatCurrency(invoice.totalTax),
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 8.5,
                                ),
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                _formatCurrency(invoice.grandTotal),
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 8.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // --- TAX SUMMARY & TOTALS SECTION ---
                    if (invoice.companySettings.showTaxSummary ||
                        invoice.companySettings.showAmountInWords)
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Left Side: Tax Summary (optional)
                        if (invoice.companySettings.showTaxSummary)
                        pw.Expanded(
                          flex: 12,
                          child: pw.Container(
                            decoration: pw.BoxDecoration(
                              border: invoice.companySettings.showAmountInWords
                                  ? pw.Border(right: borderSide)
                                  : null,
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  child: pw.Text(
                                    'Tax Summary:',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8.5,
                                    ),
                                  ),
                                ),
                                _buildTaxSummaryTable(invoice, borderSide),
                              ],
                            ),
                          ),
                        ),

                        // Right Side: Sub Total, Total, Amount in words (optional)
                        if (invoice.companySettings.showAmountInWords)
                        pw.Expanded(
                          flex: 6,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                            children: [
                              // Sub Total
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: pw.Row(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text(
                                      'Sub Total',
                                      style: const pw.TextStyle(fontSize: 8.5),
                                    ),
                                    pw.Text(':', style: const pw.TextStyle(fontSize: 8.5)),
                                    pw.Text(
                                      _formatCurrency(invoice.subtotal),
                                      style: pw.TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              pw.Container(
                                decoration: pw.BoxDecoration(
                                  border: pw.Border(top: borderSide),
                                ),
                              ),

                              // Total
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: pw.Row(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text(
                                      'Total',
                                      style: pw.TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                    pw.Text(':', style: const pw.TextStyle(fontSize: 8.5)),
                                    pw.Text(
                                      _formatCurrency(invoice.grandTotal),
                                      style: pw.TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              pw.Container(
                                decoration: pw.BoxDecoration(
                                  border: pw.Border(top: borderSide),
                                ),
                              ),

                              // Invoice Amount in Words
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      'Invoice Amount In Words :',
                                      style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                    pw.SizedBox(height: 3),
                                    pw.Text(
                                      invoice.amountInWords,
                                      style: const pw.TextStyle(
                                        fontSize: 7.5,
                                        lineSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Divider (before terms and conditions)
                    if (invoice.companySettings.showTermsAndConditions)
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border(top: borderSide),
                      ),
                    ),

                    // --- TERMS AND CONDITIONS ---
                    if (invoice.companySettings.showTermsAndConditions)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Terms And Conditions:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 8.5,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            invoice.companySettings.terms,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                    ),

                    // Divider (before bank/signature section)
                    if (invoice.companySettings.showBankDetails ||
                        invoice.companySettings.showSignature)
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border(top: borderSide),
                      ),
                    ),

                    // --- BANK DETAILS & AUTHORIZED SIGNATORY ---
                    if (invoice.companySettings.showBankDetails ||
                        invoice.companySettings.showSignature)
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Left Side: Bank Details with QR code
                        if (invoice.companySettings.showBankDetails)
                        pw.Expanded(
                          flex: 1,
                          child: pw.Container(
                            decoration: invoice.companySettings.showSignature
                                ? pw.BoxDecoration(
                                    border: pw.Border(right: borderSide),
                                  )
                                : const pw.BoxDecoration(),
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Bank Details:',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 8.5,
                                  ),
                                ),
                                pw.SizedBox(height: 5),
                                pw.Row(
                                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                                  children: [
                                    // QR Code with UPI badge
                                    if (invoice.companySettings.showUpiQrCode)
                                    pw.Column(
                                      children: [
                                        pw.Container(
                                          width: 55,
                                          height: 55,
                                          child: pw.BarcodeWidget(
                                            barcode: pw.Barcode.qrCode(),
                                            data: upiUri,
                                            drawText: false,
                                          ),
                                        ),
                                        pw.SizedBox(height: 2),
                                        // UPI Click to pay badge
                                        pw.Container(
                                          padding:
                                              const pw.EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1.5,
                                          ),
                                          decoration: pw.BoxDecoration(
                                            color: PdfColor.fromInt(0xFF008850),
                                            borderRadius:
                                                pw.BorderRadius.circular(2),
                                          ),
                                          child: pw.Row(
                                            mainAxisSize: pw.MainAxisSize.min,
                                            children: [
                                              pw.Text(
                                                'UPI ',
                                                style: pw.TextStyle(
                                                  color: PdfColors.white,
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                  fontSize: 5,
                                                ),
                                              ),
                                              pw.Text(
                                                'CLICK TO PAY',
                                                style: const pw.TextStyle(
                                                  color: PdfColors.white,
                                                  fontSize: 4.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (invoice.companySettings.showUpiQrCode)
                                    pw.SizedBox(width: 8),

                                    // Bank Accounts
                                    pw.Expanded(
                                      child: pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.start,
                                        children: [
                                          pw.RichText(
                                            text: pw.TextSpan(
                                              text: 'Name: ',
                                              style: const pw.TextStyle(
                                                fontSize: 8,
                                              ),
                                              children: [
                                                pw.TextSpan(
                                                  text: invoice
                                                      .companySettings.bankName,
                                                  style: pw.TextStyle(
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                    fontSize: 8,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          pw.SizedBox(height: 2),
                                          pw.RichText(
                                            text: pw.TextSpan(
                                              text: 'Account No.: ',
                                              style: const pw.TextStyle(
                                                fontSize: 8,
                                              ),
                                              children: [
                                                pw.TextSpan(
                                                  text: invoice
                                                      .companySettings.accountNo,
                                                  style: pw.TextStyle(
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                    fontSize: 8,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          pw.SizedBox(height: 2),
                                          pw.RichText(
                                            text: pw.TextSpan(
                                              text: 'IFSC code: ',
                                              style: const pw.TextStyle(
                                                fontSize: 8,
                                              ),
                                              children: [
                                                pw.TextSpan(
                                                  text: invoice
                                                      .companySettings.ifscCode,
                                                  style: pw.TextStyle(
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                    fontSize: 8,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Right Side: Signatory
                        if (invoice.companySettings.showSignature)
                        pw.Expanded(
                          flex: 1,
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Align(
                                  alignment: pw.Alignment.topLeft,
                                  child: pw.Text(
                                    'For ${invoice.companySettings.name}:',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8.5,
                                    ),
                                  ),
                                ),
                                pw.SizedBox(height: 6),
                                // Blue signature graphic (Image or styled font)
                                pw.Container(
                                  height: 36,
                                  alignment: pw.Alignment.center,
                                  child: signatureImageBytes != null
                                      ? pw.Image(
                                          pw.MemoryImage(signatureImageBytes),
                                          height: 34,
                                          fit: pw.BoxFit.contain,
                                        )
                                      : pw.Text(
                                          invoice.companySettings.signatoryName,
                                          style: pw.TextStyle(
                                            color: PdfColor.fromInt(0xFF1A365D),
                                            fontSize: 22,
                                            fontWeight: pw.FontWeight.bold,
                                            fontStyle: pw.FontStyle.italic,
                                          ),
                                        ),
                                ),
                                pw.SizedBox(height: 3),
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(
                                      'Authorized ',
                                      style: const pw.TextStyle(fontSize: 8.5),
                                    ),
                                    pw.Container(
                                      padding: const pw.EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: pw.BoxDecoration(
                                        color: PdfColor.fromInt(0xFFE6F4EA),
                                        borderRadius:
                                            pw.BorderRadius.circular(2),
                                        border: pw.Border.all(
                                          color: PdfColor.fromInt(0xFF34A853),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: pw.Text(
                                        'Signatory',
                                        style: pw.TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: pw.FontWeight.bold,
                                          color: PdfColor.fromInt(0xFF1E8E3E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // --- Helper Widgets ---

  static pw.Widget _buildTableHeaderCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      alignment: align == pw.TextAlign.center
          ? pw.Alignment.center
          : (align == pw.TextAlign.right
              ? pw.Alignment.centerRight
              : pw.Alignment.centerLeft),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      alignment: align == pw.TextAlign.center
          ? pw.Alignment.center
          : (align == pw.TextAlign.right
              ? pw.Alignment.centerRight
              : pw.Alignment.centerLeft),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildTaxHeaderCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      alignment: align == pw.TextAlign.center
          ? pw.Alignment.center
          : (align == pw.TextAlign.right
              ? pw.Alignment.centerRight
              : pw.Alignment.centerLeft),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildDualTaxHeaderCell(
    String title,
    pw.BorderSide borderSide,
  ) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          alignment: pw.Alignment.center,
          child: pw.Text(
            title,
            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border(top: borderSide)),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Rate (%)\n ',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 6.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.Container(
                width: 0.8,
                height: 16,
                color: borderSide.color,
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Amt (₹)\n ',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 6.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildDualDataCell(
    String rate,
    String amt,
    pw.BorderSide borderSide, {
    bool isBold = false,
  }) {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 1,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            alignment: pw.Alignment.center,
            child: pw.Text(
              rate,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ),
        pw.Container(
          width: 0.8,
          height: 16,
          color: borderSide.color,
        ),
        pw.Expanded(
          flex: 1,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              amt,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTaxSummaryTable(
    Invoice invoice,
    pw.BorderSide borderSide,
  ) {
    final summaryList = invoice.taxSummary;
    final isInterState = invoice.isInterState;

    final double totalTaxable = summaryList.fold(
      0.0,
      (sum, row) => sum + row.taxableAmount,
    );
    final double totalCgst = summaryList.fold(
      0.0,
      (sum, row) => sum + row.cgstAmount,
    );
    final double totalSgst = summaryList.fold(
      0.0,
      (sum, row) => sum + row.sgstAmount,
    );
    final double totalIgst = summaryList.fold(
      0.0,
      (sum, row) => sum + row.igstAmount,
    );
    final double totalTax = summaryList.fold(
      0.0,
      (sum, row) => sum + row.totalTax,
    );

    if (isInterState) {
      // Inter-State (IGST) table layout
      return pw.Table(
        border: pw.TableBorder(
          horizontalInside: borderSide,
          verticalInside: borderSide,
          top: borderSide,
        ),
        columnWidths: const {
          0: pw.FlexColumnWidth(1.2), // HSN/SAC
          1: pw.FlexColumnWidth(1.8), // Taxable amount
          2: pw.FlexColumnWidth(1.0), // Rate %
          3: pw.FlexColumnWidth(1.5), // Amt
          4: pw.FlexColumnWidth(1.5), // Total Tax
        },
        children: [
          pw.TableRow(
            children: [
              _buildTableHeaderCell('HSN/ SAC', align: pw.TextAlign.center),
              _buildTableHeaderCell('Taxable\namount (₹)', align: pw.TextAlign.right),
              _buildTableHeaderCell('IGST\nRate (%)', align: pw.TextAlign.center),
              _buildTableHeaderCell('Amt (₹)', align: pw.TextAlign.right),
              _buildTableHeaderCell('Total Tax(₹)', align: pw.TextAlign.right),
            ],
          ),
          ...summaryList.map(
            (row) => pw.TableRow(
              children: [
                _buildTableCell(row.hsnSac, align: pw.TextAlign.center),
                _buildTableCell(_formatNum(row.taxableAmount), align: pw.TextAlign.right),
                _buildTableCell(row.igstRate.toStringAsFixed(1), align: pw.TextAlign.center),
                _buildTableCell(_formatNum(row.igstAmount), align: pw.TextAlign.right),
                _buildTableCell(_formatNum(row.totalTax), align: pw.TextAlign.right),
              ],
            ),
          ),
          pw.TableRow(
            children: [
              _buildTableCell('TOTAL', align: pw.TextAlign.center, isBold: true),
              _buildTableCell(_formatNum(totalTaxable), align: pw.TextAlign.right, isBold: true),
              _buildTableCell('', align: pw.TextAlign.center),
              _buildTableCell(_formatNum(totalIgst), align: pw.TextAlign.right, isBold: true),
              _buildTableCell(_formatNum(totalTax), align: pw.TextAlign.right, isBold: true),
            ],
          ),
        ],
      );
    }

    // Intra-State (CGST + SGST) matching image exactly
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: borderSide,
        verticalInside: borderSide,
        top: borderSide,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.1), // HSN/SAC
        1: pw.FlexColumnWidth(1.6), // Taxable amount
        2: pw.FlexColumnWidth(2.0), // CGST (Rate + Amt)
        3: pw.FlexColumnWidth(2.0), // SGST (Rate + Amt)
        4: pw.FlexColumnWidth(1.4), // Total Tax
      },
      children: [
        // Header Row
        pw.TableRow(
          children: [
            _buildTaxHeaderCell('HSN/ SAC', align: pw.TextAlign.center),
            _buildTaxHeaderCell('Taxable\namount (₹)', align: pw.TextAlign.right),
            _buildDualTaxHeaderCell('CGST', borderSide),
            _buildDualTaxHeaderCell('SGST', borderSide),
            _buildTaxHeaderCell('Total Tax(₹)', align: pw.TextAlign.right),
          ],
        ),
        // Data Rows
        ...summaryList.map(
          (row) => pw.TableRow(
            children: [
              _buildTableCell(row.hsnSac, align: pw.TextAlign.center),
              _buildTableCell(_formatNum(row.taxableAmount), align: pw.TextAlign.right),
              _buildDualDataCell(
                row.cgstRate.toStringAsFixed(1),
                _formatNum(row.cgstAmount),
                borderSide,
              ),
              _buildDualDataCell(
                row.sgstRate.toStringAsFixed(1),
                _formatNum(row.sgstAmount),
                borderSide,
              ),
              _buildTableCell(_formatNum(row.totalTax), align: pw.TextAlign.right),
            ],
          ),
        ),
        // TOTAL Row
        pw.TableRow(
          children: [
            _buildTableCell('TOTAL', align: pw.TextAlign.center, isBold: true),
            _buildTableCell(_formatNum(totalTaxable), align: pw.TextAlign.right, isBold: true),
            _buildDualDataCell(
              '',
              _formatNum(totalCgst),
              borderSide,
              isBold: true,
            ),
            _buildDualDataCell(
              '',
              _formatNum(totalSgst),
              borderSide,
              isBold: true,
            ),
            _buildTableCell(_formatNum(totalTax), align: pw.TextAlign.right, isBold: true),
          ],
        ),
      ],
    );
  }
}
