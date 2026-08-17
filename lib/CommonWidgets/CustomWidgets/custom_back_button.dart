import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class CustomBackButton extends StatelessWidget {
  final Color containerColor;
  final VoidCallback? onTap;

  const CustomBackButton({
    super.key,
    this.containerColor = Colors.transparent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Opaque so the whole padded area is tappable, not just the icon glyph.
      behavior: HitTestBehavior.opaque,
      onTap: onTap ?? () => Get.back(),
      child: Container(
        color: containerColor,
        padding: const EdgeInsets.all(4),
        child: SvgPicture.asset("assets/svg/icons/back_icon.svg"),
      ),
    );
  }
}
