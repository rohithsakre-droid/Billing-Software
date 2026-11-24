import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/company_settings.dart';
import '../models/invoice.dart';
import '../models/product.dart';

class DBHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    // Enable FFI for desktop (macOS & Windows)
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final Directory appDir = await getApplicationSupportDirectory();
    final String dbPath = join(appDir.path, 'billing_app_v2.db');

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          // Company Settings Table
          await db.execute('''
            CREATE TABLE company_settings (
              id INTEGER PRIMARY KEY,
              name TEXT NOT NULL,
              address TEXT NOT NULL,
              phone TEXT NOT NULL,
              email TEXT NOT NULL,
              gstin TEXT NOT NULL,
              state TEXT NOT NULL,
              bank_name TEXT NOT NULL,
              account_no TEXT NOT NULL,
              ifsc_code TEXT NOT NULL,
              upi_id TEXT NOT NULL,
              terms TEXT NOT NULL,
              signatory_title TEXT NOT NULL,
              signatory_name TEXT NOT NULL,
              signature_image_path TEXT,
              default_save_location TEXT DEFAULT 'Downloads',
              show_bank_details INTEGER DEFAULT 1,
              show_upi_qr_code INTEGER DEFAULT 1,
              show_signature INTEGER DEFAULT 1,
              show_terms_and_conditions INTEGER DEFAULT 1,
              show_tax_summary INTEGER DEFAULT 1,
              show_amount_in_words INTEGER DEFAULT 1
            )
          ''');

          // Products Table
          await db.execute('''
            CREATE TABLE products (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              serial_no TEXT,
              hsn_sac TEXT NOT NULL,
              unit TEXT NOT NULL,
              price REAL NOT NULL,
              gst_rate REAL NOT NULL
            )
          ''');

          // Invoices Table
          await db.execute('''
            CREATE TABLE invoices (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              invoice_number TEXT UNIQUE NOT NULL,
              date TEXT NOT NULL,
              place_of_supply TEXT NOT NULL,
              customer_name TEXT NOT NULL,
              customer_address TEXT NOT NULL,
              customer_phone TEXT NOT NULL,
              customer_gstin TEXT NOT NULL,
              customer_state TEXT NOT NULL,
              subtotal REAL NOT NULL,
              taxable_subtotal REAL NOT NULL,
              tax_total REAL NOT NULL,
              grand_total REAL NOT NULL,
              amount_in_words TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');

          // Invoice Items Table
          await db.execute('''
            CREATE TABLE invoice_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              invoice_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              serial_no TEXT,
              hsn_sac TEXT NOT NULL,
              quantity REAL NOT NULL,
              unit TEXT NOT NULL,
              price REAL NOT NULL,
              gst_rate REAL NOT NULL,
              taxable_amount REAL NOT NULL,
              gst_amount REAL NOT NULL,
              total_amount REAL NOT NULL,
              FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
            )
          ''');

          // Seed Default Company Settings
          const defaultSettings = CompanySettings();
          await db.insert('company_settings', defaultSettings.toMap());

          // Seed Sample Catalog Products
          await db.insert('products', {
            'name': 'JM-SW-6000/72 VA',
            'serial_no': 'HR20J2K04N00ESVP9Q',
            'hsn_sac': '8504',
            'unit': 'Nos',
            'price': 37200.0,
            'gst_rate': 18.0,
          });
          await db.insert('products', {
            'name': 'QUANTA 65AH-12V',
            'serial_no': '',
            'hsn_sac': '8507',
            'unit': 'Nos',
            'price': 6200.0,
            'gst_rate': 18.0,
          });
          await db.insert('products', {
            'name': 'EXIDE 150AH SOLAR BATTERY',
            'serial_no': '',
            'hsn_sac': '8507',
            'unit': 'Nos',
            'price': 14500.0,
            'gst_rate': 28.0,
          });
          await db.insert('products', {
            'name': 'MICROTEK 1KVA INVERTER',
            'serial_no': '',
            'hsn_sac': '8504',
            'unit': 'Nos',
            'price': 6800.0,
            'gst_rate': 18.0,
          });

          // Seed Sample Invoice #512 (Matching the uploaded image)
          final sampleInv = Invoice(
            invoiceNumber: '512',
            date: '23-11-2026',
            placeOfSupply: '29-Karnataka',
            customerName: 'SNAPTECH ANALYTICALS PVT LTD',
            customerAddress: '7TH BLOCK No.278Y 1ST MAIN BSK III STAGE BANGALORE',
            customerPhone: '9844003980',
            customerGstin: '29AAPCS0531E1ZD',
            customerState: '29-Karnataka',
            items: [
              InvoiceItem(
                name: 'JM-SW-6000/72 VA',
                serialNo: 'Serial No.: HR20J2K04N00ESVP9Q',
                hsnSac: '8504',
                quantity: 1,
                unit: 'Nos',
                price: 37200.0,
                gstRate: 18.0,
              ),
              InvoiceItem(
                name: 'QUANTA 65AH-12V',
                serialNo: '',
                hsnSac: '8507',
                quantity: 6,
                unit: 'Nos',
                price: 6200.0,
                gstRate: 18.0,
              ),
            ],
          );

          final invId = await db.insert('invoices', sampleInv.toMap());
          for (final item in sampleInv.items) {
            await db.insert('invoice_items', item.toMap(invId));
          }
        },
        onOpen: (db) async {
          try {
            await db.execute('ALTER TABLE company_settings ADD COLUMN signature_image_path TEXT DEFAULT ""');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE company_settings ADD COLUMN default_save_location TEXT DEFAULT "Downloads"');
          } catch (_) {}
          // Page Setup columns
          try {
            await db.execute('ALTER TABLE company_settings ADD COLUMN show_bank_details INTEGER DEFAULT 1');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE company_settings ADD COLUMN show_upi_qr_code INTEGER DEFAULT 1');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE company_settings ADD COLUMN show_signature INTEGER DEFAULT 1');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE company_settings ADD COLUMN show_terms_and_conditions INTEGER DEFAULT 1');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE company_settings ADD COLUMN show_tax_summary INTEGER DEFAULT 1');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE company_settings ADD COLUMN show_amount_in_words INTEGER DEFAULT 1');
          } catch (_) {}
        },
      ),
    );
  }

  // --- Company Settings Operations ---
  static Future<CompanySettings> getCompanySettings() async {
    final db = await database;
    final rows = await db.query('company_settings', limit: 1);
    if (rows.isNotEmpty) {
      return CompanySettings.fromMap(rows.first);
    }
    const def = CompanySettings();
    await db.insert('company_settings', def.toMap());
    return def;
  }

  static Future<void> updateCompanySettings(CompanySettings settings) async {
    final db = await database;
    await db.update(
      'company_settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [settings.id],
    );
  }

  // --- Product Operations ---
  static Future<List<Product>> getAllProducts() async {
    final db = await database;
    final rows = await db.query('products', orderBy: 'name ASC');
    return rows.map((r) => Product.fromMap(r)).toList();
  }

  static Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  static Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  static Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // --- Invoice Operations ---
  static Future<int> insertInvoice(Invoice invoice) async {
    final db = await database;
    return await db.transaction((txn) async {
      final invId = await txn.insert('invoices', invoice.toMap());
      for (final item in invoice.items) {
        await txn.insert('invoice_items', item.toMap(invId));
      }
      return invId;
    });
  }

  static Future<void> updateInvoice(Invoice invoice) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'invoices',
        invoice.toMap(),
        where: 'id = ?',
        whereArgs: [invoice.id],
      );
      if (invoice.id != null) {
        await txn.delete(
          'invoice_items',
          where: 'invoice_id = ?',
          whereArgs: [invoice.id],
        );
        for (final item in invoice.items) {
          await txn.insert('invoice_items', item.toMap(invoice.id!));
        }
      }
    });
  }

  static Future<int> deleteInvoice(int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      await txn.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [id]);
      return await txn.delete('invoices', where: 'id = ?', whereArgs: [id]);
    });
  }

  static Future<List<Invoice>> getAllInvoices({String? searchQuery}) async {
    final db = await database;
    final settings = await getCompanySettings();

    List<Map<String, Object?>> rows;
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      rows = await db.query(
        'invoices',
        where: 'invoice_number LIKE ? OR customer_name LIKE ? OR date LIKE ?',
        whereArgs: [q, q, q],
        orderBy: 'id DESC',
      );
    } else {
      rows = await db.query('invoices', orderBy: 'id DESC');
    }

    final List<Invoice> invoices = [];
    for (final r in rows) {
      final invId = r['id'] as int;
      final itemRows = await db.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invId],
      );
      final items = itemRows.map((it) => InvoiceItem.fromMap(it)).toList();
      invoices.add(Invoice.fromMap(r, items: items, companySettings: settings));
    }
    return invoices;
  }

  static Future<Invoice?> getInvoiceById(int id) async {
    final db = await database;
    final rows = await db.query('invoices', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;

    final settings = await getCompanySettings();
    final itemRows = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [id],
    );
    final items = itemRows.map((it) => InvoiceItem.fromMap(it)).toList();
    return Invoice.fromMap(rows.first, items: items, companySettings: settings);
  }

  static Future<String> getNextInvoiceNumber() async {
    final db = await database;
    final rows = await db.query(
      'invoices',
      columns: ['invoice_number'],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return '512';

    final lastNumStr = rows.first['invoice_number'] as String;
    final parsed = int.tryParse(lastNumStr);
    if (parsed != null) {
      return (parsed + 1).toString();
    }
    return 'INV-${DateTime.now().millisecondsSinceEpoch % 100000}';
  }
}
