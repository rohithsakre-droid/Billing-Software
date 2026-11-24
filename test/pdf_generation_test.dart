import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/company_settings.dart';
import 'package:billing_app/models/invoice.dart';
import 'package:billing_app/services/pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Generates Tax Invoice PDF with exact sample details', () async {
    final item1 = InvoiceItem(
      name: 'JM-SW-6000/72 VA',
      serialNo: 'Serial No.: HR20J2K04N00ESVP9Q',
      hsnSac: '8504',
      quantity: 1,
      unit: 'Nos',
      price: 37200.00,
      gstRate: 18.0,
    );

    final item2 = InvoiceItem(
      name: 'QUANTA 65AH-12V',
      serialNo: '',
      hsnSac: '8507',
      quantity: 6,
      unit: 'Nos',
      price: 6200.00,
      gstRate: 18.0,
    );

    final invoice = Invoice(
      invoiceNumber: '512',
      date: '23-11-2026',
      placeOfSupply: '29-Karnataka',
      customerName: 'SNAPTECH ANALYTICALS PVT LTD',
      customerAddress: '7TH BLOCK No.278Y 1ST MAIN BSK III STAGE BANGALORE',
      customerPhone: '9844003980',
      customerGstin: '29AAPCS0531E1ZD',
      customerState: '29-Karnataka',
      items: [item1, item2],
      companySettings: const CompanySettings(),
    );

    final pdfBytes = await PdfService.generateInvoicePdf(invoice);
    expect(pdfBytes.isNotEmpty, isTrue);

    // Save test PDF output to scratch/ directory
    final scratchDir = Directory('/Users/rohithsakre/.gemini/antigravity/brain/3d89d312-295f-4d30-96f5-5d6ac1782c81/scratch');
    if (!scratchDir.existsSync()) {
      scratchDir.createSync(recursive: true);
    }
    final file = File('${scratchDir.path}/test_tax_invoice_512.pdf');
    file.writeAsBytesSync(pdfBytes);
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(1000));
  });
}
