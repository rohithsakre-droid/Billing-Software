import 'company_settings.dart';
import '../utils/number_to_words.dart';

class InvoiceItem {
  final int? id;
  final int? invoiceId;
  final String name;
  final String serialNo;
  final String hsnSac;
  final double quantity;
  final String unit;
  final double price; // Taxable price per unit
  final double gstRate; // e.g. 18.0

  InvoiceItem({
    this.id,
    this.invoiceId,
    required this.name,
    this.serialNo = '',
    required this.hsnSac,
    required this.quantity,
    this.unit = 'Nos',
    required this.price,
    this.gstRate = 18.0,
  });

  double get taxableAmount => quantity * price;
  double get gstAmount => taxableAmount * (gstRate / 100);
  double get totalAmount => taxableAmount + gstAmount;

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    String? name,
    String? serialNo,
    String? hsnSac,
    double? quantity,
    String? unit,
    double? price,
    double? gstRate,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      name: name ?? this.name,
      serialNo: serialNo ?? this.serialNo,
      hsnSac: hsnSac ?? this.hsnSac,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      gstRate: gstRate ?? this.gstRate,
    );
  }

  Map<String, Object?> toMap([int? explicitInvoiceId]) {
    return {
      if (id != null) 'id': id,
      'invoice_id': explicitInvoiceId ?? invoiceId,
      'name': name,
      'serial_no': serialNo,
      'hsn_sac': hsnSac,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'gst_rate': gstRate,
      'taxable_amount': taxableAmount,
      'gst_amount': gstAmount,
      'total_amount': totalAmount,
    };
  }

  factory InvoiceItem.fromMap(Map<String, Object?> map) {
    return InvoiceItem(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int?,
      name: map['name'] as String? ?? '',
      serialNo: map['serial_no'] as String? ?? '',
      hsnSac: map['hsn_sac'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: map['unit'] as String? ?? 'Nos',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      gstRate: (map['gst_rate'] as num?)?.toDouble() ?? 18.0,
    );
  }
}

class TaxSummaryRow {
  final String hsnSac;
  final double taxableAmount;
  final double cgstRate;
  final double cgstAmount;
  final double sgstRate;
  final double sgstAmount;
  final double igstRate;
  final double igstAmount;
  final double totalTax;

  const TaxSummaryRow({
    required this.hsnSac,
    required this.taxableAmount,
    required this.cgstRate,
    required this.cgstAmount,
    required this.sgstRate,
    required this.sgstAmount,
    required this.igstRate,
    required this.igstAmount,
    required this.totalTax,
  });
}

class Invoice {
  final int? id;
  final String invoiceNumber;
  final String date;
  final String placeOfSupply;
  final String customerName;
  final String customerAddress;
  final String customerPhone;
  final String customerGstin;
  final String customerState;
  final List<InvoiceItem> items;
  final CompanySettings companySettings;
  final String createdAt;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.date,
    required this.placeOfSupply,
    required this.customerName,
    required this.customerAddress,
    required this.customerPhone,
    required this.customerGstin,
    required this.customerState,
    this.items = const [],
    this.companySettings = const CompanySettings(),
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  double get totalQuantity => items.fold(0.0, (sum, item) => sum + item.quantity);
  double get taxableSubtotal => items.fold(0.0, (sum, item) => sum + item.taxableAmount);
  double get totalTax => items.fold(0.0, (sum, item) => sum + item.gstAmount);
  double get grandTotal => items.fold(0.0, (sum, item) => sum + item.totalAmount);

  // Subtotal in invoice template displays the sum of item gross amounts (or grandTotal)
  double get subtotal => grandTotal;

  String get amountInWords => NumberToWords.convert(grandTotal);

  /// Check whether transaction is inter-state (IGST) or intra-state (CGST + SGST)
  bool get isInterState {
    final sellerCode = _extractStateCode(companySettings.state);
    final buyerCode = _extractStateCode(customerState.isNotEmpty ? customerState : placeOfSupply);
    if (sellerCode.isNotEmpty && buyerCode.isNotEmpty) {
      return sellerCode != buyerCode;
    }
    return false;
  }

  static String _extractStateCode(String stateStr) {
    final match = RegExp(r'^(\d{2})').firstMatch(stateStr.trim());
    return match?.group(1) ?? '';
  }

  List<TaxSummaryRow> get taxSummary {
    final Map<String, List<InvoiceItem>> grouped = {};
    for (final item in items) {
      final key = item.hsnSac.isEmpty ? 'GENERAL' : item.hsnSac;
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final List<TaxSummaryRow> summary = [];
    final interState = isInterState;

    for (final entry in grouped.entries) {
      final hsn = entry.key;
      final groupItems = entry.value;

      final double taxableSum = groupItems.fold(0.0, (sum, it) => sum + it.taxableAmount);
      final double totalTaxSum = groupItems.fold(0.0, (sum, it) => sum + it.gstAmount);
      final double avgRate = groupItems.isNotEmpty ? groupItems.first.gstRate : 18.0;

      if (interState) {
        summary.add(
          TaxSummaryRow(
            hsnSac: hsn,
            taxableAmount: taxableSum,
            cgstRate: 0.0,
            cgstAmount: 0.0,
            sgstRate: 0.0,
            sgstAmount: 0.0,
            igstRate: avgRate,
            igstAmount: totalTaxSum,
            totalTax: totalTaxSum,
          ),
        );
      } else {
        final halfRate = avgRate / 2;
        final halfAmt = totalTaxSum / 2;
        summary.add(
          TaxSummaryRow(
            hsnSac: hsn,
            taxableAmount: taxableSum,
            cgstRate: halfRate,
            cgstAmount: halfAmt,
            sgstRate: halfRate,
            sgstAmount: halfAmt,
            igstRate: 0.0,
            igstAmount: 0.0,
            totalTax: totalTaxSum,
          ),
        );
      }
    }
    return summary;
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_number': invoiceNumber,
      'date': date,
      'place_of_supply': placeOfSupply,
      'customer_name': customerName,
      'customer_address': customerAddress,
      'customer_phone': customerPhone,
      'customer_gstin': customerGstin,
      'customer_state': customerState,
      'subtotal': subtotal,
      'taxable_subtotal': taxableSubtotal,
      'tax_total': totalTax,
      'grand_total': grandTotal,
      'amount_in_words': amountInWords,
      'created_at': createdAt,
    };
  }

  factory Invoice.fromMap(
    Map<String, Object?> map, {
    List<InvoiceItem> items = const [],
    CompanySettings companySettings = const CompanySettings(),
  }) {
    return Invoice(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as String? ?? '',
      date: map['date'] as String? ?? '',
      placeOfSupply: map['place_of_supply'] as String? ?? '',
      customerName: map['customer_name'] as String? ?? '',
      customerAddress: map['customer_address'] as String? ?? '',
      customerPhone: map['customer_phone'] as String? ?? '',
      customerGstin: map['customer_gstin'] as String? ?? '',
      customerState: map['customer_state'] as String? ?? '',
      items: items,
      companySettings: companySettings,
      createdAt: map['created_at'] as String?,
    );
  }
}
