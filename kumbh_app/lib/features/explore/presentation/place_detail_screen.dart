import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/place_model.dart';
import '../../common/common_widgets.dart';

class PlaceDetailScreen extends StatelessWidget {
  final Place place;

  const PlaceDetailScreen({super.key, required this.place});

  Color _crowdColor(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _crowdIcon(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return Icons.people_outline;
      case 'medium':
        return Icons.people;
      case 'high':
        return Icons.groups;
      default:
        return Icons.people_outline;
    }
  }

  Future<void> _openInMaps(BuildContext context) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final crowdColor = _crowdColor(place.crowdLevel);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E9),
      body: CustomScrollView(
        slivers: [
          // ── Hero image app bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: screenHeight * 0.38,
            pinned: true,
            backgroundColor: const Color(0xFFEA7A1A),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.arrow_back, color: Colors.black, size: 18),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  SmartImage(
                    source: place.imageUrl,
                    fit: BoxFit.cover,
                    provenance: place.imageUrl.startsWith('http')
                        ? ImageProvenance.networkVerified
                        : ImageProvenance.assetVerified,
                  ),
                  // Gradient overlay so title is readable
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                  // Place name at bottom of image
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          place.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Color(0xFFFF8A65), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              place.category,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.near_me,
                                color: Colors.white70, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              '${place.distanceKm.toStringAsFixed(1)} km away',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body content ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Info chips row ─────────────────────────────────────
                  Row(
                    children: [
                      // Crowd level chip
                      _InfoChip(
                        icon: _crowdIcon(place.crowdLevel),
                        label: 'Crowd: ${place.crowdLevel}',
                        color: crowdColor,
                      ),
                      const SizedBox(width: 8),
                      // Category chip
                      _InfoChip(
                        icon: Icons.category_outlined,
                        label: place.category,
                        color: const Color(0xFFEA7A1A),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Description ────────────────────────────────────────
                  const Text(
                    'About this place',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    place.description.isNotEmpty
                        ? place.description
                        : 'No description available for this place.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Location coordinates card ──────────────────────────
                  if (place.latitude != 0.0 && place.longitude != 0.0) ...[
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFF3E0),
                          child: Icon(Icons.map_outlined,
                              color: Color(0xFFEA7A1A)),
                        ),
                        title: Text(
                          '${place.latitude.toStringAsFixed(5)}, ${place.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text('Tap to open in Maps',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black45)),
                        trailing: const Icon(Icons.open_in_new,
                            color: Color(0xFFEA7A1A)),
                        onTap: () => _openInMaps(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Action buttons ─────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openInMaps(context),
                          icon: const Icon(Icons.directions),
                          label: const Text('Get Directions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA7A1A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
