import 'package:flutter/material.dart';

const crossHeroAssetPath = 'asset/illustrations/cross_hero.png';

/// Full-page presentation of the dashboard's single decorative artwork.
class CrossHeroArtwork extends StatelessWidget {
  final BoxFit fit;
  final Alignment alignment;
  final double opacity;

  const CrossHeroArtwork({
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.centerRight,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Opacity(
          opacity: opacity,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                Color(0xFF000000),
                Color(0xE6000000),
                Color(0x8A000000),
                Color(0x00000000),
              ],
              stops: [0, 0.42, 0.72, 1],
            ).createShader(bounds),
            child: Image.asset(
              crossHeroAssetPath,
              fit: fit,
              alignment: alignment,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}
