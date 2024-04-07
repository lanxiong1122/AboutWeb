import 'package:aboutweb/StartupPage.dart';
import 'package:aboutweb/WebViewPage.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WebView Cookie Example',
      initialRoute: '/',
      routes: {
        '/': (context) => StartupPage(),
        '/webPage': (context) => WebViewPage(), // 注册 WebViewPage 对应的路由
      },
      onUnknownRoute: (settings) {
        // 处理未知路由的情况，可选
      },
    );
  }
}
