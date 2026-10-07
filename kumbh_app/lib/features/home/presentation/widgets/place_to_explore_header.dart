import 'package:flutter/material.dart';
import 'package:kumbh_app/l10n/app_localizations.dart';

class PlaceToExploreHeader extends StatelessWidget {
  const PlaceToExploreHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          l10n?.placeToExplore ?? 'Place to Explore',
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
