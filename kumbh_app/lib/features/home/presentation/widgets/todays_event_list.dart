import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kumbh_app/app/providers.dart';
import 'event_list_item.dart';

class TodaysEventList extends ConsumerWidget {
  const TodaysEventList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsListProvider);

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text('No verified events available for this date.', textAlign: TextAlign.center),
              ),
            ),
          );
        }
        return SliverList.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            return EventListItem(event: events[index]);
          },
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (err, stack) => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Text('Error loading events: $err'),
          ),
        ),
      ),
    );
  }
}
