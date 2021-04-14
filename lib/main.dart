import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';
import 'package:image/db_provider.dart';
import 'package:image/web_swipe.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

// ignore_for_file: public_member_api_docs

void main() {
  runApp(MyApp());
}

/// 画像データを持つだけのオブジェクト
class ImageNameSet {
  ImageNameSet({
    required this.imagePathString,
    required this.thumbnailPathString,
  });

  /// 画像の保存先情報
  final String imagePathString;

  /// サムネイルの保存先情報
  final String thumbnailPathString;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FirstPage(),
    );
  }
}

// class HomePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ElevatedButton(
//               onPressed: () async {
//                 await PhotoManager.requestPermission();
//                 final list = await PhotoManager.getAssetPathList();
//                 final data = list.first;
//                 final assets = await data.assetList;
//                 await downloadImagesInit(
//                   context: context,
//                   assets: assets,
//                   categoryId: 1,
//                 );
//               },
//               child: const Text('start'),
//             ),
//             FutureBuilder<Directory>(
//                 future: getApplicationDocumentsDirectory(),
//                 builder: (context, snapshot) {
//                   if (snapshot.data == null) {
//                     return Container();
//                   }
//                   return Image.file(File('${snapshot.data!.path}/'));
//                 }),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> downloadImagesInit({
//     required BuildContext context,
//     required int categoryId,
//     required List<AssetEntity> assets,
//   }) async {
//     final directory = await getApplicationDocumentsDirectory();
//     final path = directory.path;
//     var i = 0;

//     // おそらくクラッシュの原因はメモリー不足なので、
//     // 1回に全ての画像を処理するのではなく、下記の枚数ずつ処理してこまめにメモリーを開放してあげる
//     const processPerIteration = 50;

//     while (i * processPerIteration < assets.length) {
//       final isLastLoop =
//           (i * processPerIteration + processPerIteration) > assets.length;

//       // このループで処理する画像一覧
//       final processingList = assets.sublist(i * processPerIteration,
//           isLastLoop ? null : i * processPerIteration + processPerIteration);

//       final imageNameSets = await Future.wait(processingList.map(
//         (asset) => downloadImages(
//           context: context,
//           path: path,
//           categoryId: categoryId,
//           asset: asset,
//         ),
//       ));

//       // ここでデータベースへの挿入を行う
//       // データベースに格納
//       for (final imageNameSet in imageNameSets) {
//         await insertContentsAndImages(
//           context: context,
//           categoryId: categoryId,
//           imagePathString: imageNameSet.imagePathString,
//           thumbPathString: imageNameSet.thumbnailPathString,
//         );
//       }

//       i++;
//     }

//     // todo: すべての画像のダウンロードを完了した時の処理。
//   }

//   Future<ImageNameSet> downloadImages({
//     required BuildContext context,
//     required String path,
//     required int categoryId,
//     required AssetEntity asset,
//   }) async {
//     final imageName = await asset.titleAsync;
//     final image = await asset.thumbDataWithSize(2000, 2000);
//     if (image == null) {
//       throw Error();
//     }
//     final compressedThumbImage = await getCompressedThumbImage(image);

//     final imagePathString = '${DateTime.now().toIso8601String()}_$imageName';
//     final thumbPathString =
//         '${DateTime.now().toIso8601String()}_${imageName}_thumb';

//     final file = File('$path/$imagePathString');
//     final thumbFile = File('$path/$thumbPathString');

//     await file.writeAsBytes(image);
//     await thumbFile.writeAsBytes(compressedThumbImage);

//     return ImageNameSet(
//       imagePathString: imagePathString,
//       thumbnailPathString: thumbPathString,
//     );
//   }

//   Future<Uint8List> getCompressedThumbImage(Uint8List image) async {
//     if (image.lengthInBytes > 10000000) {
//       return FlutterImageCompress.compressWithList(image,
//           minWidth: 250,
//           minHeight: 500,
//           quality: 40,
//           format: CompressFormat.jpeg);
//     } else if (image.lengthInBytes > 5000000) {
//       return FlutterImageCompress.compressWithList(image,
//           minWidth: 250,
//           minHeight: 500,
//           quality: 60,
//           format: CompressFormat.jpeg);
//     } else {
//       return FlutterImageCompress.compressWithList(image,
//           minWidth: 250,
//           minHeight: 500,
//           quality: 80,
//           format: CompressFormat.jpeg);
//     }
//   }

//   Future<int> insertContentsAndImages({
//     required BuildContext context,
//     required int categoryId,
//     required String imagePathString,
//     required String thumbPathString,
//   }) async {
//     var contents = ContentsTable(
//       categoryId: categoryId,
//       initImagePath: thumbPathString,
//       multiple: 'false',
//       memo: null,
//       createdAt: DateTime.now().toString(),
//     );
//     final id = await DBProvider.db.insertContentData(contents);
//     final image = ImagesTable(
//         contentId: id,
//         path: imagePathString,
//         thumbPath: thumbPathString,
//         orderIndex: 0,
//         createdAt: DateTime.now().toString());
//     return DBProvider.db.insertImageData(image);
//   }
// }
