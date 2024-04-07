import 'dart:math'; // 引入 math 包以便使用 min 函数

import 'package:flutter/material.dart';

class CountDownWidget extends StatefulWidget {
  final int countdown;

  CountDownWidget({required this.countdown});

  @override
  _CountDownWidgetState createState() => _CountDownWidgetState();
}

class _CountDownWidgetState extends State<CountDownWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.countdown),
    );
    _animation = Tween(begin: 360.0, end: 0.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // 假设倒计时结束时需要显示“已完成”或其他操作
          setState(() {
            // 可能需要重置 UI 显示或者调用回调函数通知外部组件倒计时已结束
            // widget.onCountdownFinished(); // 假设有这样的回调函数
          });
          _controller.reverse(from: 0.0); // 继续反向动画，形成循环效果
        } else if (status == AnimationStatus.dismissed) {
          // 不需要额外处理dismissed状态，因为在这个例子中它并不会被触发
        }
      });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '剩余时间：${widget.countdown}',
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: CircleProgressPainter(_animation.value),
            size: Size.square(64),
          ),
          Text(
            '${widget.countdown}',
            style: TextStyle(fontSize: 32, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class CircleProgressPainter extends CustomPainter {
  final double angle;

  CircleProgressPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    // 画一个背景圆
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final backgroundPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 画一个旋转的进度圆
    final arcPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2,
        angle, false, arcPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
