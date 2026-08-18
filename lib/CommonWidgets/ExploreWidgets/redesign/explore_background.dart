import 'package:flutter/material.dart';
import 'package:outspot/Utils/colors.dart';

/// The Explore screen's backdrop, extracted so every screen pushed out of the
/// feed paints the identical gradient.
///
/// Copying the `RadialGradient` into each screen worked until one of them was
/// edited and the others weren't; sharing one widget makes that impossible.
class ExploreBackground extends StatelessWidget {
  final Widget child;

  const ExploreBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          stops: [0.0, 0.6],
        ),
      ),
      // Transparent Scaffold so the gradient above shows through; without it
      // the theme's opaque canvas paints over the whole thing.
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: SafeArea(child: child),
      ),
    );
  }
}
