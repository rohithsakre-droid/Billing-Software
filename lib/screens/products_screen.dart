import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/product.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();
  final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹ ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final list = await DBHelper.getAllProducts();
    if (mounted) {
      setState(() {
        _products = list;
        _isLoading = false;
      });
    }
  }

  List<Product> get _filteredProducts {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _products;
    return _products.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.hsnSac.toLowerCase().contains(q) ||
          p.serialNo.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _showProductDialog([Product? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final serialCtrl = TextEditingController(text: existing?.serialNo ?? '');
    final hsnCtrl = TextEditingController(text: existing?.hsnSac ?? '');
    final unitCtrl = TextEditingController(text: existing?.unit ?? 'Nos');
    final priceCtrl = TextEditingController(
      text: existing != null ? existing.price.toStringAsFixed(2) : '',
    );
    double selectedGst = existing?.gstRate ?? 18.0;

    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add New Product' : 'Edit Product'),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Product / Item Name *',
                            hintText: 'e.g. JM-SW-6000/72 VA',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Please enter product name'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: serialCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Serial No / Model / Specifications',
                            hintText: 'e.g. Serial No.: HR20J2K04N00ESVP9Q',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: hsnCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'HSN / SAC Code *',
                                  hintText: 'e.g. 8504',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: unitCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Unit',
                                  hintText: 'Nos',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: priceCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Price / Unit (₹) *',
                                  prefixText: '₹ ',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (double.tryParse(v.trim()) == null) {
                                    return 'Invalid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<double>(
                                initialValue: selectedGst,
                                decoration: const InputDecoration(
                                  labelText: 'GST Rate',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 0.0, child: Text('0% GST')),
                                  DropdownMenuItem(value: 5.0, child: Text('5% GST')),
                                  DropdownMenuItem(value: 12.0, child: Text('12% GST')),
                                  DropdownMenuItem(value: 18.0, child: Text('18% GST')),
                                  DropdownMenuItem(value: 28.0, child: Text('28% GST')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setDlgState(() => selectedGst = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final p = Product(
                        id: existing?.id,
                        name: nameCtrl.text.trim(),
                        serialNo: serialCtrl.text.trim(),
                        hsnSac: hsnCtrl.text.trim(),
                        unit: unitCtrl.text.trim().isEmpty
                            ? 'Nos'
                            : unitCtrl.text.trim(),
                        price: double.parse(priceCtrl.text.trim()),
                        gstRate: selectedGst,
                      );
                      if (existing == null) {
                        await DBHelper.insertProduct(p);
                      } else {
                        await DBHelper.updateProduct(p);
                      }
                      if (context.mounted) {
                        Navigator.of(ctx).pop(true);
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      _loadProducts();
    }
  }

  Future<void> _deleteProduct(Product p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${p.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && p.id != null) {
      await DBHelper.deleteProduct(p.id!);
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product & Item Catalog'),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
            onPressed: () => _showProductDialog(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search products by name, HSN code, or serial number...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Products Table / List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No products found.',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add Your First Product'),
                                onPressed: () => _showProductDialog(),
                              ),
                            ],
                          ),
                        )
                      : Card(
                          elevation: 1,
                          clipBehavior: Clip.antiAlias,
                          child: ListView.separated(
                            itemCount: list.length,
                            separatorBuilder: (ctx, i) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final p = list[idx];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Colors.blue.shade100,
                                  child: Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      color: Colors.blue.shade900,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    if (p.serialNo.isNotEmpty) ...[
                                      Text(
                                        p.serialNo,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    Chip(
                                      label: Text('HSN: ${p.hsnSac}'),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text('GST: ${p.gstRate}%'),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text('Unit: ${p.unit}'),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _inr.format(p.price),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      tooltip: 'Edit',
                                      onPressed: () => _showProductDialog(p),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      tooltip: 'Delete',
                                      onPressed: () => _deleteProduct(p),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
