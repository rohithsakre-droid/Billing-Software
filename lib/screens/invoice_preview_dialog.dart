import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/invoice.dart';
import '../services/pdf_service.dart';

class InvoicePreviewDialog extends StatelessWidget {
  final Invoice invoice;

  const InvoicePreviewDialog({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tax Invoice #${invoice.invoiceNumber}'),
        actions: [
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => PdfService.generateInvoicePdf(invoice),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: 'Tax_Invoice_${invoice.invoiceNumber}.pdf',
        actions: [
          PdfPreviewAction(
            icon: const Icon(Icons.save_alt),
            onPressed: (context, build, pageFormat) async {
              final bytes = await build(pageFormat);
              await Printing.sharePdf(
                bytes: bytes,
                filename: 'Tax_Invoice_${invoice.invoiceNumber}.pdf',
              );
            },
          ),
        ],
      ),
    );
  }
}
