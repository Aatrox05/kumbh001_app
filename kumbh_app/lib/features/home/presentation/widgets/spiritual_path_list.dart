import 'package:flutter/material.dart';
import 'spiritual_path_card.dart';
import 'spiritual_path_data.dart';

class SpiritualPathList extends StatelessWidget {
  const SpiritualPathList({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final topic = spiritualTopics[index];
          return SpiritualPathCard(topic: topic);
        },
        childCount: spiritualTopics.length,
      ),
    );
  }
}
