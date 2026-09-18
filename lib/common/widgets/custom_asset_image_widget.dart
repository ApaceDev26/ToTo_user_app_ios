import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomAssetImageWidget extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final Color? color;

  const CustomAssetImageWidget(this.image,
      {super.key,
      this.height,
      this.width,
      this.fit = BoxFit.cover,
      this.color});

  @override
  Widget build(BuildContext context) {
    final isSvg = image.contains('.svg', image.length - '.svg'.length);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = width != null && width!.isFinite && width! > 0
        ? (width! * pixelRatio).ceil()
        : null;
    final cacheHeight = height != null && height!.isFinite && height! > 0
        ? (height! * pixelRatio).ceil()
        : null;
    return isSvg
        ? SvgPicture.asset(
            image,
            width: width,
            height: height,
            colorFilter: color != null
                ? ColorFilter.mode(color!, BlendMode.srcIn)
                : null,
            fit: fit!,
          )
        : Image.asset(image,
            fit: fit, width: width, height: height, color: color,
            cacheWidth: cacheWidth, cacheHeight: cacheHeight);
  }
}
