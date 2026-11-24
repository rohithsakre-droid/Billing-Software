import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../database/db_helper.dart';
import '../models/company_settings.dart';
import '../models/invoice.dart';
import '../models/product.dart';
import '../services/pdf_service.dart';
import 'invoice_preview_dialog.dart';

const List<String> kIndianStates = [
  '01-Jammu and Kashmir',
  '02-Himachal Pradesh',
  '03-Punjab',
  '04-Chandigarh',
  '05-Uttarakhand',
  '06-Haryana',
  '07-Delhi',
  '08-Rajasthan',
  '09-Uttar Pradesh',
  '10-Bihar',
  '11-Sikkim',
  '12-Arunachal Pradesh',
  '13-Nagaland',
  '14-Manipur',
  '15-Mizoram',
  '16-Tripura',
  '17-Meghalaya',
  '18-Assam',
  '19-West Bengal',
  '20-Jharkhand',
  '21-Odisha',
  '22-Chhattisgarh',
  '23-Madhya Pradesh',
  '24-Gujarat',
  '26-Dadra and Nagar Haveli and Daman and Diu',
  '27-Maharashtra',
  '28-Andhra Pradesh (Old)',
  '29-Karnataka',
  '30-Goa',
  '31-Lakshadweep',
  '32-Kerala',
  '33-Tamil Nadu',
  '34-Puducherry',
  '35-Andaman and Nicobar Islands',
  '36-Telangana',
  '37-Andhra Pradesh',
  '38-Ladakh',
];

class LineItemEditor {
  final TextEditingController nameCtrl;
  final TextEditingController serialCtrl;
  final TextEditingController hsnCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController unitCtrl;
  final TextEditingController priceCtrl;
  double gstRate;

  LineItemEditor({
    String name = '',
    String serial = '',
    String hsn = '',
    String qty = '1',
    String unit = 'Nos',
    String price = '',
    this.gstRate = 18.0,
  })  : nameCtrl = TextEditingController(text: name),
        serialCtrl = TextEditingController(text: serial),
        hsnCtrl = TextEditingController(text: hsn),
        qtyCtrl = TextEditingController(text: qty),
        unitCtrl = TextEditingController(text: unit),
        priceCtrl = TextEditingController(text: price);

  InvoiceItem toInvoiceItem() {
    final q = double.tryParse(qtyCtrl.text.trim()) ?? 1.0;
    final p = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
    return InvoiceItem(
      name: nameCtrl.text.trim(),
      serialNo: serialCtrl.text.trim(),
      hsnSac: hsnCtrl.text.trim(),
      quantity: q,
      unit: unitCtrl.text.trim().isEmpty ? 'Nos' : unitCtrl.text.trim(),
      price: p,
      gstRate: gstRate,
    );
  }

  void dispose() {
    nameCtrl.dispose();
    serialCtrl.dispose();
    hsnCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
    priceCtrl.dispose();
  }
}

class BillingScreen extends StatefulWidget {
  final Invoice? initialInvoice;

  const BillingScreen({super.key, this.initialInvoice});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _editingInvoiceId;
  final _invoiceNoCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  String _placeOfSupply = '29-Karnataka';

  final _customerNameCtrl = TextEditingController();
  final _customerAddressCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _customerGstinCtrl = TextEditingController();
  String _customerState = '29-Karnataka';

  final List<LineItemEditor> _itemEditors = [];
  CompanySettings _companySettings = const CompanySettings();
  List<Product> _catalogProducts = [];

  bool _showLivePreview = true;
  bool _isSaving = false;

  final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹ ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final settings = await DBHelper.getCompanySettings();
    final products = await DBHelper.getAllProducts();

    if (mounted) {
      setState(() {
        _companySettings = settings;
        _catalogProducts = products;
      });
    }

    if (widget.initialInvoice != null) {
      _loadFromInvoice(widget.initialInvoice!);
    } else {
      _loadTemplateSample();
    }
  }

  void _loadFromInvoice(Invoice inv) {
    _clearEditors();
    setState(() {
      _editingInvoiceId = inv.id;
      _invoiceNoCtrl.text = inv.invoiceNumber;
      _dateCtrl.text = inv.date;
      _placeOfSupply =
          kIndianStates.contains(inv.placeOfSupply)
              ? inv.placeOfSupply
              : '29-Karnataka';
      _customerNameCtrl.text = inv.customerName;
      _customerAddressCtrl.text = inv.customerAddress;
      _customerPhoneCtrl.text = inv.customerPhone;
      _customerGstinCtrl.text = inv.customerGstin;
      _customerState =
          kIndianStates.contains(inv.customerState)
              ? inv.customerState
              : '29-Karnataka';

      for (final item in inv.items) {
        final editor = LineItemEditor(
          name: item.name,
          serial: item.serialNo,
          hsn: item.hsnSac,
          qty: item.quantity % 1 == 0
              ? item.quantity.toInt().toString()
              : item.quantity.toString(),
          unit: item.unit,
          price: item.price.toStringAsFixed(2),
          gstRate: item.gstRate,
        );
        _attachListener(editor);
        _itemEditors.add(editor);
      }
    });
  }

  void _loadTemplateSample() {
    _clearEditors();
    setState(() {
      _editingInvoiceId = null;
      _invoiceNoCtrl.text = '512';
      _dateCtrl.text = '23-11-2026';
      _placeOfSupply = '29-Karnataka';

      _customerNameCtrl.text = 'SNAPTECH ANALYTICALS PVT LTD';
      _customerAddressCtrl.text =
          '7TH BLOCK No.278Y 1ST MAIN BSK III STAGE BANGALORE';
      _customerPhoneCtrl.text = '9844003980';
      _customerGstinCtrl.text = '29AAPCS0531E1ZD';
      _customerState = '29-Karnataka';

      final item1 = LineItemEditor(
        name: 'JM-SW-6000/72 VA',
        serial: 'Serial No.: HR20J2K04N00ESVP9Q',
        hsn: '8504',
        qty: '1',
        unit: 'Nos',
        price: '37200.00',
        gstRate: 18.0,
      );
      final item2 = LineItemEditor(
        name: 'QUANTA 65AH-12V',
        serial: '',
        hsn: '8507',
        qty: '6',
        unit: 'Nos',
        price: '6200.00',
        gstRate: 18.0,
      );

      _attachListener(item1);
      _attachListener(item2);
      _itemEditors.addAll([item1, item2]);
    });
  }

  Future<void> _startNewInvoice() async {
    final nextNo = await DBHelper.getNextInvoiceNumber();
    final now = DateTime.now();
    final dateStr = DateFormat('dd-MM-yyyy').format(now);

    _clearEditors();
    setState(() {
      _editingInvoiceId = null;
      _invoiceNoCtrl.text = nextNo;
      _dateCtrl.text = dateStr;
      _placeOfSupply = '29-Karnataka';
      _customerNameCtrl.clear();
      _customerAddressCtrl.clear();
      _customerPhoneCtrl.clear();
      _customerGstinCtrl.clear();
      _customerState = '29-Karnataka';

      _addNewLineItem();
    });
  }

  void _attachListener(LineItemEditor editor) {
    editor.nameCtrl.addListener(_onFieldChanged);
    editor.serialCtrl.addListener(_onFieldChanged);
    editor.hsnCtrl.addListener(_onFieldChanged);
    editor.qtyCtrl.addListener(_onFieldChanged);
    editor.unitCtrl.addListener(_onFieldChanged);
    editor.priceCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  void _clearEditors() {
    for (final e in _itemEditors) {
      e.dispose();
    }
    _itemEditors.clear();
  }

  void _addNewLineItem([Product? p]) {
    final editor = LineItemEditor(
      name: p?.name ?? '',
      serial: p?.serialNo ?? '',
      hsn: p?.hsnSac ?? '',
      qty: '1',
      unit: p?.unit ?? 'Nos',
      price: p != null ? p.price.toStringAsFixed(2) : '',
      gstRate: p?.gstRate ?? 18.0,
    );
    _attachListener(editor);
    setState(() {
      _itemEditors.add(editor);
    });
  }

  void _removeItem(int index) {
    if (_itemEditors.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one item is required in the bill')),
      );
      return;
    }
    final removed = _itemEditors.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Invoice _buildInvoiceObject() {
    final items = _itemEditors.map((e) => e.toInvoiceItem()).toList();
    return Invoice(
      id: _editingInvoiceId,
      invoiceNumber: _invoiceNoCtrl.text.trim().isEmpty
          ? '512'
          : _invoiceNoCtrl.text.trim(),
      date: _dateCtrl.text.trim().isEmpty
          ? DateFormat('dd-MM-yyyy').format(DateTime.now())
          : _dateCtrl.text.trim(),
      placeOfSupply: _placeOfSupply,
      customerName: _customerNameCtrl.text.trim().isEmpty
          ? 'Walk-in Customer'
          : _customerNameCtrl.text.trim(),
      customerAddress: _customerAddressCtrl.text.trim(),
      customerPhone: _customerPhoneCtrl.text.trim(),
      customerGstin: _customerGstinCtrl.text.trim(),
      customerState: _customerState,
      items: items,
      companySettings: _companySettings,
    );
  }

  Future<void> _saveInvoice() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_itemEditors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Reload latest settings to pick up any updated signature image or default save location
      _companySettings = await DBHelper.getCompanySettings();
      final inv = _buildInvoiceObject();

      if (_editingInvoiceId != null) {
        await DBHelper.updateInvoice(inv);
      } else {
        final newId = await DBHelper.insertInvoice(inv);
        _editingInvoiceId = newId;
      }

      // Automatically export PDF to the configured Desktop or Downloads folder
      String? savedPdfPath;
      try {
        savedPdfPath = await PdfService.exportPdf(
          inv,
          targetLocation: _companySettings.defaultSaveLocation,
        );
      } catch (pdfErr) {
        debugPrint('PDF export note: $pdfErr');
      }

      if (mounted) {
        final targetLoc = _companySettings.defaultSaveLocation;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              savedPdfPath != null
                  ? 'Invoice #${inv.invoiceNumber} saved & PDF created in $targetLoc:\n$savedPdfPath'
                  : 'Invoice #${inv.invoiceNumber} saved to database!',
            ),
            backgroundColor: Colors.teal.shade800,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'View PDF',
              textColor: Colors.amber,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => InvoicePreviewDialog(invoice: inv),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showCatalogPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SizedBox(
          height: 480,
          child: Column(
            children: [
              AppBar(
                title: const Text('Select Product from Catalog'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              Expanded(
                child: _catalogProducts.isEmpty
                    ? const Center(child: Text('No catalog products available'))
                    : ListView.builder(
                        itemCount: _catalogProducts.length,
                        itemBuilder: (context, idx) {
                          final p = _catalogProducts[idx];
                          return ListTile(
                            leading: CircleAvatar(child: Text('${idx + 1}')),
                            title: Text(
                              p.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'HSN: ${p.hsnSac} | GST: ${p.gstRate}% | Unit: ${p.unit}',
                            ),
                            trailing: Text(
                              _inr.format(p.price),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            onTap: () {
                              _addNewLineItem(p);
                              Navigator.of(ctx).pop();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _invoiceNoCtrl.dispose();
    _dateCtrl.dispose();
    _customerNameCtrl.dispose();
    _customerAddressCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _customerGstinCtrl.dispose();
    _clearEditors();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentInvoice = _buildInvoiceObject();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1100;
        final showSideBySide = _showLivePreview && !isNarrow;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _editingInvoiceId != null
                  ? 'Editing Invoice #${currentInvoice.invoiceNumber}'
                  : 'Create Tax Invoice',
            ),
            actions: [
              if (!isNarrow) ...[
                TextButton.icon(
                  icon: const Icon(Icons.flash_on, color: Colors.amber),
                  label: const Text('Load Sample #512'),
                  onPressed: _loadTemplateSample,
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('New Invoice'),
                  onPressed: _startNewInvoice,
                ),
                const SizedBox(width: 8),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.flash_on, color: Colors.amber),
                  tooltip: 'Load Sample #512',
                  onPressed: _loadTemplateSample,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'New Invoice',
                  onPressed: _startNewInvoice,
                ),
              ],
              IconButton(
                icon: Icon(
                  _showLivePreview
                      ? Icons.chrome_reader_mode
                      : Icons.chrome_reader_mode_outlined,
                ),
                tooltip: _showLivePreview ? 'Hide Live PDF' : 'Show Live PDF',
                onPressed: () {
                  setState(() => _showLivePreview = !_showLivePreview);
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.print),
                tooltip: 'Print / Full PDF',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => InvoicePreviewDialog(invoice: currentInvoice),
                  );
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.download, color: Colors.teal),
                tooltip: 'Save PDF to Downloads',
                onPressed: () async {
                  final path = await PdfService.exportPdfToDownloads(currentInvoice);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tax Invoice saved to Downloads:\n$path'),
                        backgroundColor: Colors.teal.shade800,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save, size: 18),
                label: Text(isNarrow ? 'Save' : (_editingInvoiceId != null ? 'Update Bill' : 'Save Bill')),
                onPressed: _isSaving ? null : _saveInvoice,
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Pane: Form Editor
              Expanded(
                flex: showSideBySide ? 6 : 10,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Invoice Meta Card
                        _buildMetaCard(),
                        const SizedBox(height: 16),

                        // Customer Details Card
                        _buildCustomerCard(),
                        const SizedBox(height: 16),

                        // Items Card
                        _buildItemsCard(),
                        const SizedBox(height: 16),

                        // Realtime Calculation Summary Card
                        _buildSummaryCard(currentInvoice),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),

              // Right Pane: Live PDF Preview
              if (showSideBySide) ...[
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  flex: 5,
                  child: Container(
                    color: Colors.grey.shade100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          color: Colors.grey.shade200,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.visibility, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Live Invoice Format Preview',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.fullscreen, size: 20),
                                tooltip: 'Open Fullscreen Preview',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => InvoicePreviewDialog(
                                      invoice: currentInvoice,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: PdfPreview(
                            build: (format) =>
                                PdfService.generateInvoicePdf(currentInvoice),
                            canChangeOrientation: false,
                            canChangePageFormat: false,
                            canDebug: false,
                            dynamicLayout: false,
                            maxPageWidth: 650,
                            pdfFileName:
                                'Tax_Invoice_${currentInvoice.invoiceNumber}.pdf',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // --- Sub-Widgets ---

  Widget _buildMetaCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invoice Header & Place of Supply',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _invoiceNoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Invoice No. *',
                      hintText: '512',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _dateCtrl,
                    decoration: InputDecoration(
                      labelText: 'Date (DD-MM-YYYY) *',
                      hintText: '23-11-2026',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            _dateCtrl.text =
                                DateFormat('dd-MM-yyyy').format(picked);
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _placeOfSupply,
                    decoration: const InputDecoration(
                      labelText: 'Place of Supply *',
                      border: OutlineInputBorder(),
                    ),
                    items: kIndianStates.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _placeOfSupply = val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, size: 20),
                SizedBox(width: 6),
                Text(
                  'Bill To (Customer Information)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Customer / Company Name *',
                hintText: 'e.g. SNAPTECH ANALYTICALS PVT LTD',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerAddressCtrl,
              decoration: const InputDecoration(
                labelText: 'Customer Address',
                hintText:
                    '7TH BLOCK No.278Y 1ST MAIN BSK III STAGE BANGALORE',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _customerPhoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Contact No.',
                      hintText: '9844003980',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _customerGstinCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Customer GSTIN',
                      hintText: '29AAPCS0531E1ZD',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _customerState,
                    decoration: const InputDecoration(
                      labelText: 'Customer State *',
                      border: OutlineInputBorder(),
                    ),
                    items: kIndianStates.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _customerState = val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.format_list_numbered, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Invoice Items',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.bookmark_add, size: 16),
                      label: const Text('Pick from Catalog'),
                      onPressed: _showCatalogPicker,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Blank Row'),
                      onPressed: () => _addNewLineItem(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Item Rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _itemEditors.length,
              separatorBuilder: (ctx, i) =>
                  const Divider(height: 24, thickness: 1),
              itemBuilder: (context, idx) {
                final editor = _itemEditors[idx];
                final q = double.tryParse(editor.qtyCtrl.text.trim()) ?? 1.0;
                final p = double.tryParse(editor.priceCtrl.text.trim()) ?? 0.0;
                final taxable = q * p;
                final gst = taxable * (editor.gstRate / 100);
                final total = taxable + gst;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row # Badge
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            '${idx + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Item Name
                        Expanded(
                          flex: 5,
                          child: TextFormField(
                            controller: editor.nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Item Name *',
                              hintText: 'e.g. JM-SW-6000/72 VA',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // HSN/SAC
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: editor.hsnCtrl,
                            decoration: const InputDecoration(
                              labelText: 'HSN/SAC *',
                              hintText: '8504',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Quantity
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: editor.qtyCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Qty *',
                              hintText: '1',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Unit
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: editor.unitCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              hintText: 'Nos',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Delete Action
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          tooltip: 'Remove Item',
                          onPressed: () => _removeItem(idx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Second Row: Serial/Description, Price, GST % and Subtotals
                    Row(
                      children: [
                        const SizedBox(width: 34), // align with inputs above
                        // Serial No / Specs
                        Expanded(
                          flex: 5,
                          child: TextFormField(
                            controller: editor.serialCtrl,
                            decoration: const InputDecoration(
                              labelText:
                                  'Serial No. / Model / Description',
                              hintText:
                                  'e.g. Serial No.: HR20J2K04N00ESVP9Q',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Price / Unit
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: editor.priceCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Price / Unit (₹) *',
                              prefixText: '₹ ',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // GST Rate
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<double>(
                            isExpanded: true,
                            initialValue: editor.gstRate,
                            decoration: const InputDecoration(
                              labelText: 'GST %',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 0.0, child: Text('0%')),
                              DropdownMenuItem(value: 5.0, child: Text('5%')),
                              DropdownMenuItem(value: 12.0, child: Text('12%')),
                              DropdownMenuItem(value: 18.0, child: Text('18%')),
                              DropdownMenuItem(value: 28.0, child: Text('28%')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => editor.gstRate = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Calculated Line Total Display
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _inr.format(total),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Tax: ${_inr.format(gst)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Invoice inv) {
    final interState = inv.isInterState;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calculate_outlined, size: 20),
                SizedBox(width: 6),
                Text(
                  'Tax Summary & Bill Totals',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Total Items & Quantity: ${inv.items.length} items (${inv.totalQuantity % 1 == 0 ? inv.totalQuantity.toInt() : inv.totalQuantity.toStringAsFixed(2)} units)',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Taxable Subtotal: ${_inr.format(inv.taxableSubtotal)}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (interState) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('IGST (Inter-state):'),
                        Text(
                          _inr.format(inv.totalTax),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('CGST (Central Tax):'),
                        Text(_inr.format(inv.totalTax / 2)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('SGST (State Tax):'),
                        Text(_inr.format(inv.totalTax / 2)),
                      ],
                    ),
                  ],
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Tax:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _inr.format(inv.totalTax),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        _inr.format(inv.grandTotal),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Amount In Words: ${inv.amountInWords}',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
