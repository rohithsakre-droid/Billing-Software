class Product {
  final int? id;
  final String name;
  final String serialNo;
  final String hsnSac;
  final String unit;
  final double price;
  final double gstRate;

  const Product({
    this.id,
    required this.name,
    this.serialNo = '',
    required this.hsnSac,
    this.unit = 'Nos',
    required this.price,
    this.gstRate = 18.0,
  });

  Product copyWith({
    int? id,
    String? name,
    String? serialNo,
    String? hsnSac,
    String? unit,
    double? price,
    double? gstRate,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      serialNo: serialNo ?? this.serialNo,
      hsnSac: hsnSac ?? this.hsnSac,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      gstRate: gstRate ?? this.gstRate,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'serial_no': serialNo,
      'hsn_sac': hsnSac,
      'unit': unit,
      'price': price,
      'gst_rate': gstRate,
    };
  }

  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      serialNo: map['serial_no'] as String? ?? '',
      hsnSac: map['hsn_sac'] as String? ?? '',
      unit: map['unit'] as String? ?? 'Nos',
      price: (map['price'] as num).toDouble(),
      gstRate: (map['gst_rate'] as num?)?.toDouble() ?? 18.0,
    );
  }
}
