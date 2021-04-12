import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
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
                downloadImagesInit(context, assets);
              },
              child: Text('start'),
            ),
            // FutureBuilder<String>(
            //   future: _filePath(),
            //   builder: (context, snap) {
            //     if (snap.data != null) {
            //       return Image.file(File(snap.data));
            //     } else {
            //       return Container();
            //     }
            //   },
            // ),
          ],
        ),
      ),
    );
  }

  Future<String> _filePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/2021-04-12T21:28:48.784980_PXL_20210404_095506511.jpg';
  }

  Future<void> downloadImagesInit(
    BuildContext context,
    List<AssetEntity> assets,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    String path = directory.path;
    await Future.wait(
        assets.map((asset) => downloadImages(context, path, asset)));
    // todo: すべての画像のダウンロードを完了した時の処理。
  }

  Future<void> downloadImages(
    BuildContext context,
    String path,
    AssetEntity asset,
  ) async {
    String imageTitle = await asset.titleAsync;
    Uint8List image = await asset.thumbDataWithSize(2000, 2000);
    Uint8List compressedThumbImage = await getCompressedThumbImage(image);

    String imagePathString = '${DateTime.now().toIso8601String()}_$imageTitle';
    String thumbPathString =
        '${DateTime.now().toIso8601String()}_${imageTitle}_thumb';

    File file = File('$path/$imagePathString');
    File thumbFile = File('$path/$thumbPathString');

    await file.writeAsBytes(image);
    await thumbFile.writeAsBytes(compressedThumbImage);

    // データベースに格納
    // await insertContentsAndImages(
    //   context, categoryId, imagePathString, thumbPathString);
  }

  Future<Uint8List> getCompressedThumbImage(image) async {
    if (image.lengthInBytes > 10000000) {
      return await FlutterImageCompress.compressWithList(image,
          minWidth: 250,
          minHeight: 500,
          quality: 40,
          format: CompressFormat.jpeg);
    } else if (image.lengthInBytes > 5000000) {
      return await FlutterImageCompress.compressWithList(image,
          minWidth: 250,
          minHeight: 500,
          quality: 60,
          format: CompressFormat.jpeg);
    } else {
      return await FlutterImageCompress.compressWithList(image,
          minWidth: 250,
          minHeight: 500,
          quality: 80,
          format: CompressFormat.jpeg);
    }
  }

  // insertContentsAndImages(
  //   BuildContext context, int categoryId, String imagePath, thumbPath) {
  // var contents = ContentsTable(
  //     categoryId: categoryId,
  //     initImagePath: thumbPath,
  //     multiple: 'false',
  //     memo: null,
  //     createdAt: DateTime.now().toString());
  // DBProvider.db.insertContentData(contents).then((id) {
  //   var image = ImagesTable(
  //       contentId: id,
  //       path: imagePath,
  //       thumbPath: thumbPath,
  //       orderIndex: 0,
  //       createdAt: DateTime.now().toString());
  // await DBProvider.db.insertImageData(image);
  // });
}
