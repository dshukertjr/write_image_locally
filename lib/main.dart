import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:image/db_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

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

    // ここでデータベースへの挿入を行う

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

  Future<int> insertContentsAndImages({
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
