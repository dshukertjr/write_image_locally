import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FirstPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => WebSwipe()));
          },
          child: const Text('Open Next Page'),
        ),
      ),
    );
  }
}

class WebSwipe extends StatefulWidget {
  @override
  _WebSwipeState createState() => _WebSwipeState();
}

class _WebSwipeState extends State<WebSwipe> {
  WebViewController? _controller;
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return Future(() => false);
      },
      child: Scaffold(
        body: GestureDetector(
          onHorizontalDragEnd: (details) async {
            if (details.primaryVelocity! <= 0) {
              // 右スワイプだった時は何もしない
              return;
            }

            if (_controller == null) {
              Navigator.of(context).pop();
              return;
            }
            final canGoBack = await _controller!.canGoBack();
            if (canGoBack) {
              await _controller!.goBack();
            } else {
              Navigator.of(context).pop();
            }
          },
          child: WebView(
            initialUrl: 'https://yahoo.co.jp',
            onWebViewCreated: (controller) {
              _controller = controller;
            },
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{}..add(
                Factory<VerticalDragGestureRecognizer>(
                    () => VerticalDragGestureRecognizer()),
              ),
          ),
        ),
      ),
    );
  }
}
