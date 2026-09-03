import 'package:flutter/material.dart';

class AnimatedTextController {
  AnimationController? animationController;
  void finish() {
    animationController?.value = 1.0;
  }

  bool isAnimating() {
    return animationController?.isAnimating ?? false;
  }
}

class AnimatedTextView extends StatefulWidget {
  AnimatedTextView({Key? key, required this.text, this.style, this.controller})
    : super(key: key) {
    durationMs = 1000;
  }

  late int durationMs;
  final String text;
  TextStyle? style;
  AnimatedTextController? controller;

  @override
  AnimatedTextState createState() {
    return AnimatedTextState();
  }
}

class AnimatedTextState extends State<AnimatedTextView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _textAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.durationMs,
      ), // Adjust the duration as needed
    );
    widget.controller?.animationController = _controller;
  }

  void startAnimation() {
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    _textAnimation = IntTween(
      begin: 0,
      end: widget.text.length,
    ).animate(_controller);

    Future.delayed(const Duration(milliseconds: 10), () {
      startAnimation();
    });

    return AnimatedBuilder(
      animation: _textAnimation,
      builder: (context, child) {
        String animatedText = widget.text.substring(0, _textAnimation.value);
        return Text(
          animatedText,
          style: widget.style ?? TextStyle(fontSize: 16, color: Colors.white),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

const int kDefaultDuration = 300;

class AnimatedViewController {
  AnimationController? animationController;
  void proceedToEnd() {
    animationController?.value = 1.0;
  }
}

class AnimatedView extends StatefulWidget {
  AnimatedView({super.key, required this.child, this.controller});

  final Widget child;
  AnimatedViewController? controller;

  @override
  AnimatedViewState createState() => AnimatedViewState();
}

class AnimatedViewState extends State<AnimatedView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kDefaultDuration),
    );

    widget.controller?.animationController = _controller;

    _animation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: -1.0, end: 0.0),
      duration: const Duration(milliseconds: kDefaultDuration),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(value * MediaQuery.of(context).size.width, 0.0),
          child: widget.child,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
