import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

/// A reusable shimmer placeholder for CachedNetworkImage loading states.
class ShimmerPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final double? radius;

  const ShimmerPlaceholder({super.key, this.width, this.height, this.radius});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2D0731),
      highlightColor: const Color(0xFF4A1466),
      child: Container(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF2D0731),
          borderRadius: BorderRadius.circular(radius ?? 10.r),
        ),
      ),
    );
  }
}

/// A circular shimmer placeholder for avatar images.
class ShimmerPlaceholderCircle extends StatelessWidget {
  final double size;

  const ShimmerPlaceholderCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2D0731),
      highlightColor: const Color(0xFF4A1466),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          // color: Color(0xFF2D0731),
          // shape: BoxShape.circle,
        ),
      ),
    );
  }
}
