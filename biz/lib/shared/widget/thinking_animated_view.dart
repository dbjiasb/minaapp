import 'package:flutter/material.dart';

class ThinkingDots extends StatefulWidget {
  const ThinkingDots({super.key, this.size = 6.0, this.color = const Color(0xFFE962F6)});

  final double size; // 圆点大小
  final Color color; // 圆点颜色

  @override
  State<ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<ThinkingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    // 初始化动画控制器，周期1.2秒，无限循环
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();

    // 三个圆点的动画：依次从0.3透明度到1，再回到0.3
    _animations = List.generate(3, (index) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          // 每个圆点延迟启动，形成依次闪烁效果
          curve: Interval(
            index * 0.2, // 第一个0.0s开始，第二个0.2s，第三个0.4s
            index * 0.2 + 0.5, // 每个动画持续0.5s
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min, // 紧凑排列
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(color: widget.color.withOpacity(_animations[index].value), shape: BoxShape.circle),
              ),
            );
          },
        );
      }),
    );
  }
}
