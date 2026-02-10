import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../models/group.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bill_split.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Bills table
    await db.execute('''
      CREATE TABLE bills (
        id TEXT PRIMARY KEY,
        restaurant_name TEXT NOT NULL,
        date TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        tip REAL NOT NULL,
        total REAL NOT NULL,
        group_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Bill items table
    await db.execute('''
      CREATE TABLE bill_items (
        id TEXT PRIMARY KEY,
        bill_id TEXT NOT NULL,
        item_name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (bill_id) REFERENCES bills (id) ON DELETE CASCADE
      )
    ''');

    // Item assignments table
    await db.execute('''
      CREATE TABLE item_assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_item_id TEXT NOT NULL,
        person_name TEXT NOT NULL,
        FOREIGN KEY (bill_item_id) REFERENCES bill_items (id) ON DELETE CASCADE
      )
    ''');

    // Groups table
    await db.execute('''
      CREATE TABLE groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Group members table
    await db.execute('''
      CREATE TABLE group_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id TEXT NOT NULL,
        member_name TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
      )
    ''');

    // Person totals table (for bill history)
    await db.execute('''
      CREATE TABLE person_totals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_id TEXT NOT NULL,
        person_name TEXT NOT NULL,
        total REAL NOT NULL,
        paid INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (bill_id) REFERENCES bills (id) ON DELETE CASCADE
      )
    ''');
  }

  // Bill operations
  Future<String> insertBill(Bill bill) async {
    final db = await database;
    await db.transaction((txn) async {
      // Insert bill
      await txn.insert('bills', {
        'id': bill.id,
        'restaurant_name': bill.restaurantName,
        'date': bill.date.toIso8601String(),
        'subtotal': bill.subtotal,
        'tax': bill.tax,
        'tip': bill.tip,
        'total': bill.total,
        'group_id': bill.groupId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Insert bill items
      for (var item in bill.items) {
        await txn.insert('bill_items', {
          'id': item.id,
          'bill_id': bill.id,
          'item_name': item.name,
          'price': item.price,
          'quantity': item.quantity,
        });

        // Insert item assignments
        for (var person in item.assignedPeople) {
          await txn.insert('item_assignments', {
            'bill_item_id': item.id,
            'person_name': person,
          });
        }
      }

      // Insert person totals
      for (var entry in bill.personTotals.entries) {
        await txn.insert('person_totals', {
          'bill_id': bill.id,
          'person_name': entry.key,
          'total': entry.value,
          'paid': bill.paidStatus[entry.key] == true ? 1 : 0,
        });
      }
    });
    return bill.id;
  }

  Future<List<Bill>> getAllBills({int? limit}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = limit != null
        ? await db.query(
            'bills',
            orderBy: 'date DESC',
            limit: limit,
          )
        : await db.query('bills', orderBy: 'date DESC');

    List<Bill> bills = [];
    for (var map in maps) {
      final bill = await _getBillById(map['id'] as String);
      if (bill != null) {
        bills.add(bill);
      }
    }
    return bills;
  }

  Future<Bill?> getBillById(String id) async {
    return await _getBillById(id);
  }

  Future<Bill?> _getBillById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> billMaps =
        await db.query('bills', where: 'id = ?', whereArgs: [id]);

    if (billMaps.isEmpty) return null;

    final billMap = billMaps.first;

    // Get items
    final List<Map<String, dynamic>> itemMaps = await db.query(
      'bill_items',
      where: 'bill_id = ?',
      whereArgs: [id],
    );

    List<BillItem> items = [];
    for (var itemMap in itemMaps) {
      // Get assigned people
      final List<Map<String, dynamic>> assignmentMaps = await db.query(
        'item_assignments',
        where: 'bill_item_id = ?',
        whereArgs: [itemMap['id']],
      );

      items.add(BillItem(
        id: itemMap['id'] as String,
        name: itemMap['item_name'] as String,
        price: itemMap['price'] as double,
        quantity: itemMap['quantity'] as int,
        assignedPeople: assignmentMaps
            .map((a) => a['person_name'] as String)
            .toList(),
      ));
    }

    // Get person totals
    final List<Map<String, dynamic>> totalMaps = await db.query(
      'person_totals',
      where: 'bill_id = ?',
      whereArgs: [id],
    );

    Map<String, double> personTotals = {};
    Map<String, bool> paidStatus = {};
    for (var totalMap in totalMaps) {
      final personName = totalMap['person_name'] as String;
      personTotals[personName] = totalMap['total'] as double;
      paidStatus[personName] = (totalMap['paid'] as int) == 1;
    }

    return Bill(
      id: billMap['id'] as String,
      restaurantName: billMap['restaurant_name'] as String,
      date: DateTime.parse(billMap['date'] as String),
      items: items,
      subtotal: billMap['subtotal'] as double,
      tax: billMap['tax'] as double,
      tip: billMap['tip'] as double,
      total: billMap['total'] as double,
      groupId: billMap['group_id'] as String?,
      personTotals: personTotals,
      paidStatus: paidStatus,
    );
  }

  Future<void> deleteBill(String id) async {
    final db = await database;
    await db.delete('bills', where: 'id = ?', whereArgs: [id]);
  }

  // Group operations
  Future<String> insertGroup(Group group) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('groups', {
        'id': group.id,
        'name': group.name,
        'created_at': group.createdAt.toIso8601String(),
      });

      for (var member in group.members) {
        await txn.insert('group_members', {
          'group_id': group.id,
          'member_name': member,
        });
      }
    });
    return group.id;
  }

  Future<List<Group>> getAllGroups() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('groups', orderBy: 'created_at DESC');

    List<Group> groups = [];
    for (var map in maps) {
      final members = await _getGroupMembers(map['id'] as String);
      groups.add(Group(
        id: map['id'] as String,
        name: map['name'] as String,
        members: members,
        createdAt: DateTime.parse(map['created_at'] as String),
      ));
    }
    return groups;
  }

  Future<List<String>> _getGroupMembers(String groupId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'group_members',
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
    return maps.map((m) => m['member_name'] as String).toList();
  }

  Future<Group?> getGroupById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('groups', where: 'id = ?', whereArgs: [id]);

    if (maps.isEmpty) return null;

    final map = maps.first;
    final members = await _getGroupMembers(id);

    return Group(
      id: map['id'] as String,
      name: map['name'] as String,
      members: members,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Future<void> updateGroup(Group group) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'groups',
        {
          'name': group.name,
        },
        where: 'id = ?',
        whereArgs: [group.id],
      );

      // Delete old members
      await txn.delete('group_members', where: 'group_id = ?', whereArgs: [group.id]);

      // Insert new members
      for (var member in group.members) {
        await txn.insert('group_members', {
          'group_id': group.id,
          'member_name': member,
        });
      }
    });
  }

  Future<void> deleteGroup(String id) async {
    final db = await database;
    await db.delete('groups', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllBills() async {
    final db = await database;
    await db.delete('bills');
  }
}
