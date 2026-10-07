import 'package:flutter/material.dart';
import 'package:kumbh_app/features/explore/data/place_model.dart';
import '../../../common/common_widgets.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  const PlaceCard({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    Color crowdColor;
    Color crowdBgColor;
    switch (place.crowdLevel.toUpperCase()) {
      case 'HIGH':
        crowdColor = const Color(0xFFD32F2F);
        crowdBgColor = const Color(0xFFFFE2E2);
        break;
      case 'MEDIUM':
        crowdColor = const Color(0xFFE65100);
        crowdBgColor = const Color(0xFFFFF3E0);
        break;
      case 'LOW':
      default:
        crowdColor = const Color(0xFF2E7D32);
        crowdBgColor = const Color(0xFFE8F5E9);
        break;
    }

    final imageUrl = place.imageUrl.isNotEmpty
        ? place.imageUrl
        : 'assets/images/place_sample.jpg';
    final isHttp =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    return SizedBox(
      width: 180,
      child: Card(
        elevation: 3,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SmartImage(
                source: imageUrl,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                provenance: isHttp
                    ? ImageProvenance.networkVerified
                    : ImageProvenance.assetVerified,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Text(
                place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text(
                    '${place.distanceKm.toStringAsFixed(1)} KM away',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: crowdBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${place.crowdLevel} Crowd',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: crowdColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
