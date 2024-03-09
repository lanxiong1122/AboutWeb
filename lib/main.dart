import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 引入url_launcher包
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebView Cookie Example',
      home: WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage>
    with AutomaticKeepAliveClientMixin {
  bool get wantKeepAlive => true;

  late WebViewController _webViewController;
  late Completer<WebViewController> _controller;
  late VoidCallback _getCookies, _clearCookies, _refreshPage;
  final jsCode = '''
(function() {
  var cookies = document.cookie.split(";");
  for (var i = 0; i < cookies.length; i++) {
    var cookie = cookies[i];
    var eqPos = cookie.indexOf("=");
    var name = eqPos > -1 ? cookie.substr(0, eqPos) : cookie;
    document.cookie = name + "=;expires=Thu, 01 Jan 1970 00:00:00 GMT";
  }
})();
''';
  bool _webViewIntialized = false;
  TextEditingController _urlController =
      TextEditingController(text: 'https://www.jd.com');

  @override
  void initState() {
    super.initState();

    _controller = Completer<WebViewController>();

    _getCookies = () async {
      if (_webViewController != null &&
          _controller.isCompleted &&
          _webViewController != await _controller.future) {
        // 等待WebViewController赋值完成后再执行获取Cookie的操作
        await Future.delayed(Duration.zero);
        _getCookies();
      } else if (_webViewController != null && _controller.isCompleted) {
        final controller = await _controller.future;
        final String cookieValue =
            await controller.evaluateJavascript('document.cookie');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Received cookies: $cookieValue')));
        debugPrint('Received cookies: $cookieValue');
      } else {
        debugPrint("WebViewController not ready yet.");
      }
    };

    _clearCookies = () async {
      if (_webViewController != null && _controller.isCompleted) {
        final controller = await _controller.future;
        await controller.clearCache();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: const Text('Cache and possibly some cookies cleared')),
        );

        // 再次尝试使用JavaScript清理Cookie
        await controller.evaluateJavascript(jsCode);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cookies cleared')),
        );
      } else {
        debugPrint("WebViewController not ready yet.");
      }
    };

    _refreshPage = () {
      if (_webViewController != null && _controller.isCompleted) {
        _webViewController.reload();
      } else {
        debugPrint(
            "WebView is either destroyed or hasn't been initialized yet.");
      }
    };
  }

  Future<bool> _onWillPop() async {
    if (_controller.isCompleted) {
      final controller = await _controller.future;
      final canGoBack = await controller.canGoBack();
      if (canGoBack) {
        controller.goBack();
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: const Text('WebView with Cookies')),
        body: Stack(
          children: [
            WebView(
              key: UniqueKey(),
              initialUrl: _urlController.text,
              javascriptMode: JavascriptMode.unrestricted,
              onPageStarted: (String url) async {
                final Uri parsedUrl = Uri.parse(url);
                if (!['http', 'https'].contains(parsedUrl.scheme)) {
                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('无法识别的链接或应用未安装'),
                      ),
                    );
                  }
                }
              },
              onWebViewCreated: (WebViewController webViewController) {
                _webViewController = webViewController;
                if (!_webViewIntialized) {
                  _webViewIntialized = true;
                  _controller.complete(webViewController);
                }
              },
              onPageFinished: (String url) async {
                Future.delayed(Duration.zero).then((_) async {
                  await _webViewController.evaluateJavascript('''
                    document.body.style.webkitUserSelect = 'auto';
                    document.addEventListener('copy', function(event) {
                      event.clipboardData.setData('text/plain', window.getSelection().toString());
                      event.preventDefault();
                    });
                  ''');
                  _getCookies();
                });
              },
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 56.0, // Adjust this height as per your requirement
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            hintText: '请输入网址',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.web),
                          ),
                          textAlign: TextAlign.center,
                          onFieldSubmitted: (value) {
                            setState(() {
                              _loadNewUrl(value);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _loadNewUrl(_urlController.text);
                          });
                        },
                        child: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _getCookies,
                      child: const Text('获取Cookie'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _clearCookies,
                      child: const Text('清除Cookie'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _refreshPage,
                      child: const Text('刷新页面'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadNewUrl(String newUrl) {
    if (_webViewController == null || !_controller.isCompleted) {
      debugPrint("WebView is either destroyed or hasn't been initialized yet.");
      return;
    }

    if (Uri.parse(newUrl).isAbsolute && Uri.parse(newUrl).scheme != '') {
      _urlController.text = newUrl;
      if (_controller.isCompleted) {
        final controller = _controller.future;
        controller.then((value) => value.loadUrl(newUrl));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的网址')),
      );
    }
  }
}
