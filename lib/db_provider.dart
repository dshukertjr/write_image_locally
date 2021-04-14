import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

// ignore_for_file: public_member_api_docs

class DBProvider {
  DBProvider._();

  static final DBProvider db = DBProvider._();

  Database? _databaseData;

  Future<Database> get database async {
    if (_databaseData != null) {
      return _databaseData!;
    } else {
      _databaseData = await initDB();
      return _databaseData!;
    }
  }

  Future<Database> initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'picmemo.db');
    Database _db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('''
              CREATE TABLE all_categories (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                parent_id INTEGER,
                name TEXT,
                tag_color_index INTEGER,
                is_locked TEXT,
                created_at TEXT,
                update_at TEXT
              )
            ''');
      await db.execute('''
              CREATE TABLE contents (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                category_id INTEGER,
                init_image_path TEXT,
                multiple TEXT,
                memo TEXT,
                created_at TEXT,
                update_at TEXT
              )
            ''');
      await db.execute('''
              CREATE TABLE images (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                content_id INTEGER,
                path TEXT,
                thumb_path TEXT,
                order_index INTEGER,
                created_at TEXT,
                update_at TEXT
              )
            ''');
    });
    return _db;
  }

  Future<int> insertContentData(ContentsTable contentsTable) async {
    final _db = await database;
    var result = await _db.insert(
      'contents',
      contentsTable.insertToMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return result;
  }

  Future<int> insertImageData(ImagesTable imagesTable) async {
    final _db = await database;
    var result = await _db.insert(
      'images',
      imagesTable.insertToMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return result;
  }
}

class ContentsTable {
  ContentsTable({
    this.id,
    required this.categoryId,
    required this.initImagePath,
    required this.multiple,
    this.memo,
    required this.createdAt,
    this.updateAt,
  });

  final int? id;
  final int categoryId;
  final String initImagePath;
  final String multiple;
  final String? memo;
  final String createdAt;
  final String? updateAt;

  Map<String, dynamic> insertToMap() {
    return {
      'category_id': categoryId,
      'init_image_path': initImagePath,
      'multiple': multiple,
      'memo': memo,
      'created_at': createdAt
    };
  }

  Map<String, dynamic> updateToMap() {
    return {
      'category_id': categoryId,
      'init_image_path': initImagePath,
      'multiple': multiple,
      'memo': memo,
      'update_at': updateAt
    };
  }
}

class ImagesTable {
  ImagesTable({
    this.id,
    required this.contentId,
    required this.path,
    required this.thumbPath,
    required this.orderIndex,
    required this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int contentId;
  final String path;
  final String thumbPath;
  final int orderIndex;
  final String createdAt;
  final String? updatedAt;

  Map<String, dynamic> insertToMap() {
    return {
      'content_id': contentId,
      'path': path,
      'thumb_path': thumbPath,
      'order_index': orderIndex,
      'created_at': createdAt
    };
  }

  Map<String, dynamic> updateToMap() {
    return {
      'content_id': contentId,
      'path': path,
      'thumb_path': thumbPath,
      'order_index': orderIndex,
      'updated_at': updatedAt
    };
  }
}
