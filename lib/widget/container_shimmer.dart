import 'package:flutter/material.dart';

class ContainerShimmer extends StatelessWidget {
  const ContainerShimmer({
    super.key,
    this.width,
    this.height,
    this.radius,
  });

  final double? width;
  final double? height;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius ?? 2),
        color: Colors.grey,
      ),
    );
  }
}
