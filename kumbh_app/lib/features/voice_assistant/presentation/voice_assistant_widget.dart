import 'package:flutter/material.dart';
import 'voice_assistant_modal.dart';

class VoiceAssistantWidget extends StatelessWidget {
  const VoiceAssistantWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFEA7A1A),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const VoiceAssistantModal(),
            );
          },
          borderRadius: BorderRadius.circular(28),
          child: const Center(
            child: Icon(
              Icons.mic,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
