import 'package:flutter/material.dart';

import '../app_theme.dart';

/// A local, accessible back control for app surfaces and photo overlays.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.onMedia = false,
  });

  final VoidCallback? onPressed;
  final Color? color;
  final bool onMedia;

  @override
  Widget build(BuildContext context) {
    return BackButton(
      onPressed: onPressed,
      color: color ?? (onMedia ? AppColors.onMedia : AppColors.textPrimary),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(48),
        backgroundColor: onMedia ? AppColors.mediaScrim : Colors.transparent,
      ),
    );
  }
}
