//生成一个头像框组件，可以设置头像框大小，头像url，描边大小，描边颜色
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:biz/base/assets/image_path.dart';

import '../../core/util/cached_image.dart';

class AvatarView extends StatelessWidget {
  final double size;
  final String url;
  final double strokeWidth;
  final Color strokeColor;

  //添加一个可选的点击回调函数，当用户点击头像框时调用
  final VoidCallback? onTap;

  const AvatarView({super.key, this.size = 40, this.url = '', this.strokeWidth = 0, this.strokeColor = Colors.transparent, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(strokeWidth),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(size / 2)),
        color: Colors.transparent,
        border: Border.all(color: strokeColor, width: strokeWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedImage(
        imageUrl: url,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) {
          return Container(color: Colors.grey, width: size, height: size);
        },
      ),
    );
  }
}
