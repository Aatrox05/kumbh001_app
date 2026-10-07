import 'package:flutter/material.dart';
import 'package:kumbh_app/l10n/app_localizations.dart';

class SpiritualPathHeader extends StatelessWidget {
  const SpiritualPathHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          l10n?.spiritualPath ?? 'Spiritual Path',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
