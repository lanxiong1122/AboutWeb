import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
      if (_webViewController != null) {
        _webViewController
            .runJavascriptReturningResult('document.cookie')
            .then((cookieValue) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Received cookies: $cookieValue')),
          );
          debugPrint('Received cookies: $cookieValue');
        });
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
        await controller.runJavascript(jsCode);
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
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
            Expanded(
              child: WebView(
                key: UniqueKey(),
                initialUrl: _urlController.text,
                javascriptMode: JavascriptMode.unrestricted,
                onPageStarted: (String url) async {
                  final Uri parsedUrl = Uri.parse(url);
                  if (!['http', 'https'].contains(parsedUrl.scheme)) {
                    if (parsedUrl.scheme == 'baiduboxapp') {
                      final String newUrl =
                          parsedUrl.queryParameters['url'] ?? '';
                      if (newUrl.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('无法识别的链接'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('无法加载此链接，请确保其可用性'),
                          ),
                        );
                      }
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
                    _getCookies();
                  }
                },
                onPageFinished: (String url) async {
                  Future.delayed(Duration.zero).then((_) async {
                    await _webViewController.runJavascript('''
                    document.body.style.webkitUserSelect = 'auto';
                    document.addEventListener('copy', function(event) {
                      event.clipboardData.setData('text/plain', window.getSelection().toString());
                      event.preventDefault();
                    });
                  ''');
                    //_getCookies();
                  });
                },
              ),
            ),
            // 将底部的 Positioned 更改为 Stack
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(height: 60), // 添加一个占位容器，用于放置底部按钮区域
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: _getCookies,
                          child: const Text('获取Cookie'),
                        ),
                        ElevatedButton(
                          onPressed: _clearCookies,
                          child: const Text('清除Cookie'),
                        ),
                        ElevatedButton(
                          onPressed: _refreshPage,
                          child: const Text('刷新页面'),
                        ),
                        ElevatedButton(
                          onPressed: _setPcUaAndReload,
                          child: const Text('设置PC端UA并刷新'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _loadNewUrl(String newUrl) async {
    if (_webViewController == null) {
      debugPrint("WebView is not initialized yet.");
      return;
    }

    if (Uri.parse(newUrl).isAbsolute && Uri.parse(newUrl).scheme != '') {
      _urlController.text = newUrl;
      await _webViewController
          .loadUrl(newUrl); // 直接使用_webViewController而非_future
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的网址')),
      );
    }
  }

  // 新增的方法用于设置UA并刷新页面
  _setPcUaAndReload() async {
    if (_webViewController == null) {
      debugPrint("WebView is not initialized yet.");
      return;
    }

    const String pcUserAgent =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3";

    // 注入JavaScript脚本来改变User-Agent
    await _webViewController
        .runJavascript("navigator.userAgent = '$pcUserAgent';");

    // 重新加载页面使更改生效
    await _webViewController.reload();
  }
}
