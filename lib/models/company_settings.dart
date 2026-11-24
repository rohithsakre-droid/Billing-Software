class CompanySettings {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String gstin;
  final String state;
  final String bankName;
  final String accountNo;
  final String ifscCode;
  final String upiId;
  final String terms;
  final String signatoryTitle;
  final String signatoryName;
  final String signatureImagePath;
  final String defaultSaveLocation; // 'Downloads' or 'Desktop'

  // --- Page Setup: Invoice section visibility ---
  final bool showBankDetails;
  final bool showUpiQrCode;
  final bool showSignature;
  final bool showTermsAndConditions;
  final bool showTaxSummary;
  final bool showAmountInWords;

  const CompanySettings({
    this.id = 1,
    this.name = 'INFOBYTE',
    this.address = '84, 5TH CROSS, SBM COLONY,\nBSK 1ST STAGE,\nBANGALORE-560050',
    this.phone = '9845064996',
    this.email = 'INFOBYTEBLR@GMAIL.COM',
    this.gstin = '29ANOPS2577H1Z8',
    this.state = '29-Karnataka',
    this.bankName = 'STATE BANK OF INDIA, SBM COLONY',
    this.accountNo = '64191122875',
    this.ifscCode = 'SBIN0040575',
    this.upiId = '9845064996@upi',
    this.terms = 'Thanks for doing business with us!',
    this.signatoryTitle = 'Authorized Signatory',
    this.signatoryName = 'Deepak',
    this.signatureImagePath = '', // Empty string means use bundled default signature image
    this.defaultSaveLocation = 'Downloads', // 'Downloads' or 'Desktop'
    // Page Setup defaults: all sections visible
    this.showBankDetails = true,
    this.showUpiQrCode = true,
    this.showSignature = true,
    this.showTermsAndConditions = true,
    this.showTaxSummary = true,
    this.showAmountInWords = true,
  });

  CompanySettings copyWith({
    int? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? gstin,
    String? state,
    String? bankName,
    String? accountNo,
    String? ifscCode,
    String? upiId,
    String? terms,
    String? signatoryTitle,
    String? signatoryName,
    String? signatureImagePath,
    String? defaultSaveLocation,
    bool? showBankDetails,
    bool? showUpiQrCode,
    bool? showSignature,
    bool? showTermsAndConditions,
    bool? showTaxSummary,
    bool? showAmountInWords,
  }) {
    return CompanySettings(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gstin: gstin ?? this.gstin,
      state: state ?? this.state,
      bankName: bankName ?? this.bankName,
      accountNo: accountNo ?? this.accountNo,
      ifscCode: ifscCode ?? this.ifscCode,
      upiId: upiId ?? this.upiId,
      terms: terms ?? this.terms,
      signatoryTitle: signatoryTitle ?? this.signatoryTitle,
      signatoryName: signatoryName ?? this.signatoryName,
      signatureImagePath: signatureImagePath ?? this.signatureImagePath,
      defaultSaveLocation: defaultSaveLocation ?? this.defaultSaveLocation,
      showBankDetails: showBankDetails ?? this.showBankDetails,
      showUpiQrCode: showUpiQrCode ?? this.showUpiQrCode,
      showSignature: showSignature ?? this.showSignature,
      showTermsAndConditions: showTermsAndConditions ?? this.showTermsAndConditions,
      showTaxSummary: showTaxSummary ?? this.showTaxSummary,
      showAmountInWords: showAmountInWords ?? this.showAmountInWords,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'gstin': gstin,
      'state': state,
      'bank_name': bankName,
      'account_no': accountNo,
      'ifsc_code': ifscCode,
      'upi_id': upiId,
      'terms': terms,
      'signatory_title': signatoryTitle,
      'signatory_name': signatoryName,
      'signature_image_path': signatureImagePath,
      'default_save_location': defaultSaveLocation,
      'show_bank_details': showBankDetails ? 1 : 0,
      'show_upi_qr_code': showUpiQrCode ? 1 : 0,
      'show_signature': showSignature ? 1 : 0,
      'show_terms_and_conditions': showTermsAndConditions ? 1 : 0,
      'show_tax_summary': showTaxSummary ? 1 : 0,
      'show_amount_in_words': showAmountInWords ? 1 : 0,
    };
  }

  factory CompanySettings.fromMap(Map<String, Object?> map) {
    return CompanySettings(
      id: map['id'] as int? ?? 1,
      name: map['name'] as String? ?? 'INFOBYTE',
      address: map['address'] as String? ?? '84, 5TH CROSS, SBM COLONY,\nBSK 1ST STAGE,\nBANGALORE-560050',
      phone: map['phone'] as String? ?? '9845064996',
      email: map['email'] as String? ?? 'INFOBYTEBLR@GMAIL.COM',
      gstin: map['gstin'] as String? ?? '29ANOPS2577H1Z8',
      state: map['state'] as String? ?? '29-Karnataka',
      bankName: map['bank_name'] as String? ?? 'STATE BANK OF INDIA, SBM COLONY',
      accountNo: map['account_no'] as String? ?? '64191122875',
      ifscCode: map['ifsc_code'] as String? ?? 'SBIN0040575',
      upiId: map['upi_id'] as String? ?? '9845064996@upi',
      terms: map['terms'] as String? ?? 'Thanks for doing business with us!',
      signatoryTitle: map['signatory_title'] as String? ?? 'Authorized Signatory',
      signatoryName: map['signatory_name'] as String? ?? 'Deepak',
      signatureImagePath: map['signature_image_path'] as String? ?? '',
      defaultSaveLocation: map['default_save_location'] as String? ?? 'Downloads',
      showBankDetails: (map['show_bank_details'] as int? ?? 1) == 1,
      showUpiQrCode: (map['show_upi_qr_code'] as int? ?? 1) == 1,
      showSignature: (map['show_signature'] as int? ?? 1) == 1,
      showTermsAndConditions: (map['show_terms_and_conditions'] as int? ?? 1) == 1,
      showTaxSummary: (map['show_tax_summary'] as int? ?? 1) == 1,
      showAmountInWords: (map['show_amount_in_words'] as int? ?? 1) == 1,
    );
  }
}
