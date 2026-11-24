import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/company_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _gstinCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _accountNoCtrl;
  late TextEditingController _ifscCodeCtrl;
  late TextEditingController _upiIdCtrl;
  late TextEditingController _termsCtrl;
  late TextEditingController _signatoryNameCtrl;
  late TextEditingController _signatoryTitleCtrl;

  String _signatureImagePath = '';
  String _defaultSaveLocation = 'Downloads'; // 'Downloads' or 'Desktop'

  // Page Setup: section visibility toggles
  bool _showBankDetails = true;
  bool _showUpiQrCode = true;
  bool _showSignature = true;
  bool _showTermsAndConditions = true;
  bool _showTaxSummary = true;
  bool _showAmountInWords = true;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await DBHelper.getCompanySettings();
    _nameCtrl = TextEditingController(text: s.name);
    _addressCtrl = TextEditingController(text: s.address);
    _phoneCtrl = TextEditingController(text: s.phone);
    _emailCtrl = TextEditingController(text: s.email);
    _gstinCtrl = TextEditingController(text: s.gstin);
    _stateCtrl = TextEditingController(text: s.state);
    _bankNameCtrl = TextEditingController(text: s.bankName);
    _accountNoCtrl = TextEditingController(text: s.accountNo);
    _ifscCodeCtrl = TextEditingController(text: s.ifscCode);
    _upiIdCtrl = TextEditingController(text: s.upiId);
    _termsCtrl = TextEditingController(text: s.terms);
    _signatoryNameCtrl = TextEditingController(text: s.signatoryName);
    _signatoryTitleCtrl = TextEditingController(text: s.signatoryTitle);
    _signatureImagePath = s.signatureImagePath;
    _defaultSaveLocation = s.defaultSaveLocation;
    _showBankDetails = s.showBankDetails;
    _showUpiQrCode = s.showUpiQrCode;
    _showSignature = s.showSignature;
    _showTermsAndConditions = s.showTermsAndConditions;
    _showTaxSummary = s.showTaxSummary;
    _showAmountInWords = s.showAmountInWords;

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    if (!_isLoading) {
      _nameCtrl.dispose();
      _addressCtrl.dispose();
      _phoneCtrl.dispose();
      _emailCtrl.dispose();
      _gstinCtrl.dispose();
      _stateCtrl.dispose();
      _bankNameCtrl.dispose();
      _accountNoCtrl.dispose();
      _ifscCodeCtrl.dispose();
      _upiIdCtrl.dispose();
      _termsCtrl.dispose();
      _signatoryNameCtrl.dispose();
      _signatoryTitleCtrl.dispose();
    }
    super.dispose();
  }

  void _resetToTemplateDefaults() {
    const s = CompanySettings();
    setState(() {
      _nameCtrl.text = s.name;
      _addressCtrl.text = s.address;
      _phoneCtrl.text = s.phone;
      _emailCtrl.text = s.email;
      _gstinCtrl.text = s.gstin;
      _stateCtrl.text = s.state;
      _bankNameCtrl.text = s.bankName;
      _accountNoCtrl.text = s.accountNo;
      _ifscCodeCtrl.text = s.ifscCode;
      _upiIdCtrl.text = s.upiId;
      _termsCtrl.text = s.terms;
      _signatoryNameCtrl.text = s.signatoryName;
      _signatoryTitleCtrl.text = s.signatoryTitle;
      _signatureImagePath = ''; // default template image
      _defaultSaveLocation = 'Downloads';
      _showBankDetails = true;
      _showUpiQrCode = true;
      _showSignature = true;
      _showTermsAndConditions = true;
      _showTaxSummary = true;
      _showAmountInWords = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reset to INFOBYTE template default values'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickSignatureImage() async {
    const typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['png', 'jpg', 'jpeg', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      setState(() {
        _signatureImagePath = file.path;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected signature image: ${file.name}'),
            backgroundColor: Colors.blue.shade800,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final updated = CompanySettings(
      id: 1,
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      gstin: _gstinCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      bankName: _bankNameCtrl.text.trim(),
      accountNo: _accountNoCtrl.text.trim(),
      ifscCode: _ifscCodeCtrl.text.trim(),
      upiId: _upiIdCtrl.text.trim(),
      terms: _termsCtrl.text.trim(),
      signatoryName: _signatoryNameCtrl.text.trim(),
      signatoryTitle: _signatoryTitleCtrl.text.trim(),
      signatureImagePath: _signatureImagePath,
      defaultSaveLocation: _defaultSaveLocation,
      showBankDetails: _showBankDetails,
      showUpiQrCode: _showUpiQrCode,
      showSignature: _showSignature,
      showTermsAndConditions: _showTermsAndConditions,
      showTaxSummary: _showTaxSummary,
      showAmountInWords: _showAmountInWords,
    );

    await DBHelper.updateCompanySettings(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company, Signature & Auto-Save settings saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildPageSetupToggle({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon, color: enabled ? Theme.of(context).primaryColor : Colors.grey),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: enabled ? value : false,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _buildSignaturePreview() {
    Widget imageWidget;
    String statusText;

    if (_signatureImagePath.isNotEmpty && _signatureImagePath != 'NONE') {
      final f = File(_signatureImagePath);
      if (f.existsSync()) {
        imageWidget = Image.file(
          f,
          height: 60,
          fit: BoxFit.contain,
        );
        statusText = 'Custom image: ${f.path.split(Platform.pathSeparator).last}';
      } else {
        imageWidget = Image.asset(
          'assets/images/default_signature.png',
          height: 60,
          fit: BoxFit.contain,
        );
        statusText = 'File not found, showing template default';
      }
    } else if (_signatureImagePath == 'NONE') {
      imageWidget = Container(
        height: 60,
        alignment: Alignment.center,
        child: Text(
          _signatoryNameCtrl.text,
          style: const TextStyle(
            fontSize: 22,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A365D),
          ),
        ),
      );
      statusText = 'Using typed signatory name';
    } else {
      // Default template signature from user reference image
      imageWidget = Image.asset(
        'assets/images/default_signature.png',
        height: 60,
        fit: BoxFit.contain,
      );
      statusText = 'Default signature from reference invoice (Deepak)';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: imageWidget,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_photo_alternate, size: 18),
                    label: const Text('Upload Signature Image'),
                    onPressed: _pickSignatureImage,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setState(() => _signatureImagePath = '');
                        },
                        child: const Text('Use Template Image'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() => _signatureImagePath = 'NONE');
                        },
                        child: const Text('Clear Image'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            statusText,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company & Bank Settings'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.restore),
            label: const Text('Reset to Template Defaults'),
            onPressed: _resetToTemplateDefaults,
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
            onPressed: _saveSettings,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PDF Auto-Save Location Setting
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.folder_special, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Automatic Bill PDF Save Location',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Whenever you click "Save Bill", the software will automatically generate and save the Tax Invoice PDF to this folder.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'Downloads',
                              label: Text('Downloads Folder'),
                              icon: Icon(Icons.download),
                            ),
                            ButtonSegment(
                              value: 'Desktop',
                              label: Text('Desktop Folder'),
                              icon: Icon(Icons.desktop_windows),
                            ),
                          ],
                          selected: {_defaultSaveLocation},
                          onSelectionChanged: (set) {
                            if (set.isNotEmpty) {
                              setState(() => _defaultSaveLocation = set.first);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Page Setup: Invoice Section Visibility
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Page Setup',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Choose which sections appear on your Tax Invoice PDF. Toggle off any section you don\'t need.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      _buildPageSetupToggle(
                        icon: Icons.account_balance,
                        label: 'Bank Details',
                        subtitle: 'Bank name, account number, IFSC code',
                        value: _showBankDetails,
                        onChanged: (v) => setState(() => _showBankDetails = v),
                      ),
                      _buildPageSetupToggle(
                        icon: Icons.qr_code_2,
                        label: 'UPI QR Code',
                        subtitle: 'Dynamic QR code for instant UPI payment',
                        value: _showUpiQrCode,
                        onChanged: (v) => setState(() => _showUpiQrCode = v),
                        enabled: _showBankDetails,
                      ),
                      _buildPageSetupToggle(
                        icon: Icons.draw,
                        label: 'Authorized Signature',
                        subtitle: 'Signature image and signatory name',
                        value: _showSignature,
                        onChanged: (v) => setState(() => _showSignature = v),
                      ),
                      _buildPageSetupToggle(
                        icon: Icons.summarize,
                        label: 'Tax Summary Table',
                        subtitle: 'HSN/SAC-wise CGST/SGST/IGST breakdown',
                        value: _showTaxSummary,
                        onChanged: (v) => setState(() => _showTaxSummary = v),
                      ),
                      _buildPageSetupToggle(
                        icon: Icons.text_fields,
                        label: 'Amount In Words',
                        subtitle: 'Invoice total written out in words',
                        value: _showAmountInWords,
                        onChanged: (v) => setState(() => _showAmountInWords = v),
                      ),
                      _buildPageSetupToggle(
                        icon: Icons.gavel,
                        label: 'Terms & Conditions',
                        subtitle: 'Your custom terms text at the bottom',
                        value: _showTermsAndConditions,
                        onChanged: (v) => setState(() => _showTermsAndConditions = v),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Signature Image & Signatory Card
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.draw, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Authorized Signature & Terms',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Upload your physical signature image (PNG or JPG). It will appear directly in the signature box on every Tax Invoice.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      _buildSignaturePreview(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _signatoryNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Signatory Name (Fallback text)',
                                hintText: 'Deepak',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _signatoryTitleCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Signatory Title',
                                hintText: 'Authorized Signatory',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _termsCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Terms And Conditions',
                          hintText: 'Thanks for doing business with us!',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Company Profile Card
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.business, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Business & Seller Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Company / Business Name *',
                          hintText: 'e.g. INFOBYTE',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _addressCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Address *',
                          hintText: '84, 5TH CROSS, SBM COLONY...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number *',
                                hintText: '9845064996',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _emailCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Email Address *',
                                hintText: 'INFOBYTEBLR@GMAIL.COM',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _gstinCtrl,
                              decoration: const InputDecoration(
                                labelText: 'GSTIN Number *',
                                hintText: '29ANOPS2577H1Z8',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _stateCtrl,
                              decoration: const InputDecoration(
                                labelText: 'State & Code *',
                                hintText: '29-Karnataka',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bank Details & UPI QR Card
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Bank & UPI Payment Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'These details appear in the invoice footer, and the UPI ID is encoded into the payment QR code.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bankNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Bank Name & Branch *',
                          hintText: 'STATE BANK OF INDIA, SBM COLONY',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _accountNoCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Bank Account Number *',
                                hintText: '64191122875',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _ifscCodeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'IFSC Code *',
                                hintText: 'SBIN0040575',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _upiIdCtrl,
                        decoration: const InputDecoration(
                          labelText: 'UPI ID (For Dynamic QR Code) *',
                          hintText: '9845064996@upi or infobyteblr@sbi',
                          helperText: 'Customers can scan the printed invoice QR code with Google Pay/PhonePe/Paytm to pay instantly.',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 250,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      'Save All Settings',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _saveSettings,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
