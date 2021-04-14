import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                await PhotoManager.requestPermission();
                final list = await PhotoManager.getAssetPathList();
                final data = list
                    .first; // 1st album in the list, typically the "Recent" or "All" album
                final assets = await data.assetList;
                await downloadImagesInit(context: context, assets: assets);
              },
              child: Text('start'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> downloadImagesInit({
    BuildContext context,
    int categoryId,
    List<AssetEntity> assets,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    String path = directory.path;
    int i = 0;

    // おそらくクラッシュの原因はメモリー不足なので、
    // 1回に全ての画像を処理するのではなく、下記の枚数ずつ処理してこまめにメモリーを開放してあげる
    const processPerIteration = 50;

    while (i * processPerIteration < assets.length) {
      final isLastLoop =
          (i * processPerIteration + processPerIteration) > assets.length;

      // このループで処理する画像一覧
      final processingList = assets.sublist(i * processPerIteration,
          isLastLoop ? null : i * processPerIteration + processPerIteration);

      await Future.wait(processingList.map(
        (asset) => downloadImages(
          context: context,
          path: path,
          categoryId: categoryId,
          asset: asset,
        ),
      ));
      i++;
    }
    // todo: すべての画像のダウンロードを完了した時の処理。
  }

  Future<void> downloadImages({
    BuildContext context,
    String path,
    int categoryId,
    AssetEntity asset,
  }) async {
    String imageName = await asset.titleAsync;
    Uint8List image = await asset.thumbDataWithSize(2000, 2000);
    Uint8List compressedThumbImage = await getCompressedThumbImage(image);

    String imagePathString = '${DateTime.now().toIso8601String()}_$imageName';
    String thumbPathString =
        '${DateTime.now().toIso8601String()}_${imageName}_thumb';

    File file = File('$path/$imagePathString');
    File thumbFile = File('$path/$thumbPathString');

    await file.writeAsBytes(image);
    await thumbFile.writeAsBytes(compressedThumbImage);

    // データベースに格納
    await insertContentsAndImages(
      context: context,
      categoryId: categoryId,
      imagePathString: imagePathString,
      thumbPathString: thumbPathString,
    );
  }

  Future<Uint8List> getCompressedThumbImage(image) async {
    if (image.lengthInBytes > 10000000) {
      return FlutterImageCompress.compressWithList(image,
          minWidth: 250,
          minHeight: 500,
          quality: 40,
          format: CompressFormat.jpeg);
    } else if (image.lengthInBytes > 5000000) {
      return FlutterImageCompress.compressWithList(image,
          minWidth: 250,
          minHeight: 500,
          quality: 60,
          format: CompressFormat.jpeg);
    } else {
      return FlutterImageCompress.compressWithList(image,
          minWidth: 250,
          minHeight: 500,
          quality: 80,
          format: CompressFormat.jpeg);
    }
  }

  insertContentsAndImages({
    BuildContext context,
    int categoryId,
    String imagePathString,
    String thumbPathString,
  }) async {
    var contents = ContentsTable(
      categoryId: categoryId,
      initImagePath: thumbPathString,
      multiple: 'false',
      memo: null,
      createdAt: DateTime.now().toString(),
    );
    final id = await DBProvider.db.insertContentData(contents);
    final image = ImagesTable(
        contentId: id,
        path: imagePathString,
        thumbPath: thumbPathString,
        orderIndex: 0,
        createdAt: DateTime.now().toString());
    return DBProvider.db.insertImageData(image);
  }
}

class DBProvider {
  DBProvider._();

  static final DBProvider db = DBProvider._();

  Database _databaseData;

  Future<Database> get database async {
    if (_databaseData != null) {
      return _databaseData;
    } else {
      _databaseData = await initDB();
      return _databaseData;
    }
  }

  initDB() async {
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

  insertContentData(ContentsTable contentsTable) async {
    final _db = await database;
    var result = await _db.insert(
      'contents',
      contentsTable.insertToMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return result;
  }

  insertImageData(ImagesTable imagesTable) async {
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
  final int id;
  final int categoryId;
  final String initImagePath;
  final String multiple;
  final String memo;
  final String createdAt;
  final String updateAt;

  ContentsTable(
      {this.id,
      this.categoryId,
      this.initImagePath,
      this.multiple,
      this.memo,
      this.createdAt,
      this.updateAt});

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
  final int id;
  final int contentId;
  final String path;
  final String thumbPath;
  final int orderIndex;
  final String createdAt;
  final String updatedAt;

  ImagesTable(
      {this.id,
      this.contentId,
      this.path,
      this.thumbPath,
      this.orderIndex,
      this.createdAt,
      this.updatedAt});

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
