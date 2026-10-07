import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

enum ImageProvenance {
  assetVerified,
  networkVerified,
  networkUnverified,
  generatedFallback,
  designedFallback,
}

class SmartImage extends StatelessWidget {
  final String source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget fallback;
  final ImageProvenance provenance;
  final bool showProvenanceBadge;

  const SmartImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback = const _DesignedFallback(),
    this.provenance = ImageProvenance.designedFallback,
    this.showProvenanceBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;

    final isHttp =
        source.startsWith('http://') || source.startsWith('https://');
    final isAsset = source.startsWith('assets/') ||
        source.endsWith('.png') ||
        source.endsWith('.jpg') ||
        source.endsWith('.jpeg');

    if (isHttp) {
      child = CachedNetworkImage(
        imageUrl: source,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => fallback,
      );
    } else if (isAsset || source.isNotEmpty) {
      child = Image.asset(
        source,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else {
      child = fallback;
    }

    if (showProvenanceBadge &&
        provenance != ImageProvenance.assetVerified &&
        provenance != ImageProvenance.networkVerified) {
      return Stack(
        children: [
          SizedBox(width: width, height: height, child: child),
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _badgeLabel(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(width: width, height: height, child: child);
  }

  String _badgeLabel() {
    switch (provenance) {
      case ImageProvenance.assetVerified:
      case ImageProvenance.networkVerified:
        return 'VERIFIED';
      case ImageProvenance.networkUnverified:
        return 'UNVERIFIED';
      case ImageProvenance.generatedFallback:
        return 'AI-GENERATED';
      case ImageProvenance.designedFallback:
        return 'FALLBACK';
    }
  }
}

class _DesignedFallback extends StatelessWidget {
  const _DesignedFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF3E0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.temple_hindu,
              size: 36,
              color: Color(0xFFEA7A1A),
            ),
            SizedBox(height: 4),
            Text(
              'Image unavailable',
              style: TextStyle(
                color: Color(0xFFEA7A1A),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
