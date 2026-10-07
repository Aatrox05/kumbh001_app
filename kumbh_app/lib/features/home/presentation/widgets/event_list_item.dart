import 'package:flutter/material.dart';
import 'package:kumbh_app/features/events/data/event_model.dart';
import '../../../common/common_widgets.dart';

class EventListItem extends StatelessWidget {
  final EventModel event;
  const EventListItem({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/events'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Builder(
                  builder: (context) {
                    final imageUrl = event.imageUrl.isNotEmpty
                        ? event.imageUrl
                        : 'assets/images/event_sample.jpg';
                    final isHttp = imageUrl.startsWith('http://') ||
                        imageUrl.startsWith('https://');
                    return SmartImage(
                      source: imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      provenance: isHttp
                          ? ImageProvenance.networkVerified
                          : ImageProvenance.assetVerified,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    if (event.startTime.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 12, color: Colors.black54),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              event.endTime.isNotEmpty
                                  ? '${event.startTime} – ${event.endTime}'
                                  : event.startTime,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.black54),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 2),
                    if (event.locationName.isNotEmpty)
                      Text(
                        event.locationName,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                  ],
                ),
              ),
              if (event.audioUrl.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Playing audio for ${event.name}...')),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color:
                              const Color(0xFFFFD54F).withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'Listen',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.play_circle_fill,
                            color: Colors.orange, size: 16),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
