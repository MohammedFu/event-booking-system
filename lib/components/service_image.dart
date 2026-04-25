import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

class ServiceImage extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final Color accentColor;
  final double iconSize;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ServiceImage({
    super.key,
    this.imageUrl,
    required this.fallbackIcon,
    this.accentColor = primaryColor,
    this.iconSize = 32,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final imageContent = imageUrl == null || imageUrl!.isEmpty
        ? _fallback()
        : CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: fit,
            placeholder: (_, __) => Container(
              color: accentColor.withOpacity(0.06),
              alignment: Alignment.center,
              child: SizedBox(
                width: iconSize * 0.75,
                height: iconSize * 0.75,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, __, ___) => _fallback(),
          );
    final image = SizedBox.expand(child: imageContent);

    if (borderRadius == null) {
      return image;
    }

    return ClipRRect(
      borderRadius: borderRadius!,
      child: image,
    );
  }

  Widget _fallback() {
    return Container(
      color: accentColor.withOpacity(0.1),
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        size: iconSize,
        color: accentColor,
      ),
    );
  }
}
