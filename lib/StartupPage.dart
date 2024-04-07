import 'dart:async';

import 'package:aboutweb/view/CountDownWidget.dart';
import 'package:flutter/material.dart';

class StartupPage extends StatefulWidget {
  @override
  _StartupPageState createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  String imageUrl =
      'https://img0.baidu.com/it/u=696279398,1588213175&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=1082';
  int countdown = 10;
  bool hasFinished = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() async {
    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        countdown--;
        if (countdown <= 0 || hasFinished) {
          timer.cancel();
          _onFinish();
        }
      });
    });
  }

  void _onFinish() {
    setState(() {
      hasFinished = true;
    });
    Navigator.pushReplacementNamed(context, '/webPage'); // 跳转到main页面
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SizedBox.expand(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(color: Colors.white),
                  height: constraints.maxHeight,
                  width: constraints.maxWidth,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                          )
                        : SizedBox.shrink(),
                  ),
                ),
                Positioned(
                  top: 26,
                  right: 26,
                  child: Semantics(
                    label: '剩余时间：$countdown 秒',
                    child: CountDownWidget(countdown: countdown),
                  ),
                ),
                Positioned(
                  bottom: 25, // 设置距离底部25像素
                  left: 50,
                  right: 50,
                  child: AnimatedOpacity(
                    opacity: hasFinished ? 0.0 : 1.0,
                    duration: Duration(milliseconds: 300),
                    child: MaterialButton(
                      onPressed: hasFinished
                          ? null
                          : () {
                              _onFinish();
                            },
                      color: Colors.indigoAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          '进入',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
