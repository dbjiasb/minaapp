import 'package:flutter/material.dart';

/// stack包裹组件
class IndexedStackChild {
  /// 是否进行预加载 index索引的元素即使为false也会加载
  final bool preload;

  /// 组件元素
  final Widget child;

  IndexedStackChild({this.preload = false, required this.child});
}

/// 懒加载IndexedStack组件
class LazyIndexedStack extends StatefulWidget {
  /// 当前指向的元素索引
  final int index;

  /// 如何定位堆栈中的元素
  final AlignmentGeometry alignment;

  /// 要解析的文本方向
  final TextDirection? textDirection;

  /// 要进行加载的子元素
  final List<IndexedStackChild> children;

  /// 如何定义子元素的大小
  final StackFit sizing;

  LazyIndexedStack({
    Key? key,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.sizing = StackFit.loose,
    this.index = 0,
    this.children = const <IndexedStackChild>[],
  }) : super(key: key);

  @override
  _ProsteLazyIndexedStackState createState() => _ProsteLazyIndexedStackState();
}

class _ProsteLazyIndexedStackState extends State<LazyIndexedStack> {
  /// 元素数组，未添加的填充一个空的sizedbox
  late List<Widget> _widgets;

  /// 判断当前索引的元素是否已经展示
  late List<bool> _widgetState;

  @override
  void initState() {
    super.initState();
    _rebuildWidgets();
  }

  @override
  void didUpdateWidget(covariant LazyIndexedStack oldWidget) {
    // 如果 children 数量变化，则整体重建
    if (oldWidget.children.length != widget.children.length) {
      _rebuildWidgets();
    } else {
      // 否则只处理当前 index 是否需要加载
      if (widget.index >= 0 &&
          widget.index < _widgets.length &&
          !_widgetState[widget.index]) {
        _widgetState[widget.index] = true;
        _widgets[widget.index] = widget.children[widget.index].child;
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  void _rebuildWidgets() {
    _widgets = List.generate(
      widget.children.length,
          (index) => index == widget.index || widget.children[index].preload
          ? widget.children[index].child
          : const SizedBox.shrink(),
    );

    _widgetState = List.generate(
      widget.children.length,
          (index) => index == widget.index || widget.children[index].preload,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      children: _widgets,
      alignment: widget.alignment,
      textDirection: widget.textDirection,
      sizing: widget.sizing,
      index: widget.index,
    );
  }
}
