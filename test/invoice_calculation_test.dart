import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/company_settings.dart';
import 'package:billing_app/models/invoice.dart';
import 'package:billing_app/utils/number_to_words.dart';

void main() {
  group('Number To Words Converter Tests', () {
    test('Converts exact sample amount 87792 to words correctly', () {
      final words = NumberToWords.convert(87792.0);
      expect(
        words,
        'Eighty Seven Thousand Seven Hundred and Ninety Two Rupees only',
      );
    });

    test('Converts zero rupees', () {
      expect(NumberToWords.convert(0.0), 'Zero Rupees only');
    });

    test('Converts amount with paise', () {
      final words = NumberToWords.convert(500.50);
      expect(
        words,
        'Five Hundred Rupees and Fifty Paise only',
      );
    });

    test('Converts lakhs and crores', () {
      final words = NumberToWords.convert(1254300.0);
      expect(
        words,
        'Twelve Lakh Fifty Four Thousand Three Hundred Rupees only',
      );
    });
  });

  group('Invoice Tax & Calculations Tests', () {
    test('Calculates exact INFOBYTE sample invoice #512 math', () {
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
        companySettings: const CompanySettings(
          state: '29-Karnataka',
        ),
      );

      // Verify Item 1
      expect(item1.taxableAmount, 37200.00);
      expect(item1.gstAmount, 6696.00);
      expect(item1.totalAmount, 43896.00);

      // Verify Item 2
      expect(item2.taxableAmount, 37200.00);
      expect(item2.gstAmount, 6696.00);
      expect(item2.totalAmount, 43896.00);

      // Verify Totals
      expect(invoice.totalQuantity, 7.0);
      expect(invoice.taxableSubtotal, 74400.00);
      expect(invoice.totalTax, 13392.00);
      expect(invoice.grandTotal, 87792.00);
      expect(invoice.subtotal, 87792.00);

      // Verify Intra-state Tax Summary breakdown (CGST 9% + SGST 9%)
      expect(invoice.isInterState, isFalse);
      final taxSummary = invoice.taxSummary;
      expect(taxSummary.length, 2);

      // HSN 8504
      final hsn8504 = taxSummary.firstWhere((r) => r.hsnSac == '8504');
      expect(hsn8504.taxableAmount, 37200.00);
      expect(hsn8504.cgstRate, 9.0);
      expect(hsn8504.cgstAmount, 3348.00);
      expect(hsn8504.sgstRate, 9.0);
      expect(hsn8504.sgstAmount, 3348.00);
      expect(hsn8504.totalTax, 6696.00);

      // HSN 8507
      final hsn8507 = taxSummary.firstWhere((r) => r.hsnSac == '8507');
      expect(hsn8507.taxableAmount, 37200.00);
      expect(hsn8507.cgstRate, 9.0);
      expect(hsn8507.cgstAmount, 3348.00);
      expect(hsn8507.sgstRate, 9.0);
      expect(hsn8507.sgstAmount, 3348.00);
      expect(hsn8507.totalTax, 6696.00);
    });

    test('Handles Inter-state (IGST) when states differ', () {
      final item = InvoiceItem(
        name: 'Test Item',
        hsnSac: '8504',
        quantity: 2,
        price: 10000.00,
        gstRate: 18.0,
      );

      final invoice = Invoice(
        invoiceNumber: '513',
        date: '24-11-2026',
        placeOfSupply: '27-Maharashtra',
        customerName: 'OUT OF STATE CUSTOMER',
        customerAddress: 'MUMBAI',
        customerPhone: '9999999999',
        customerGstin: '27AAAAA0000A1Z5',
        customerState: '27-Maharashtra',
        items: [item],
        companySettings: const CompanySettings(
          state: '29-Karnataka',
        ),
      );

      expect(invoice.isInterState, isTrue);
      final taxSummary = invoice.taxSummary;
      expect(taxSummary.first.igstRate, 18.0);
      expect(taxSummary.first.igstAmount, 3600.00);
      expect(taxSummary.first.cgstAmount, 0.0);
      expect(taxSummary.first.sgstAmount, 0.0);
    });
  });
}
