import 'package:flutter/material.dart';
import 'package:kumbh_app/l10n/app_localizations.dart';

class TodaysEventHeader extends StatelessWidget {
  const TodaysEventHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n?.todaysEvent ?? "Today's Event",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/events'),
            child: Text(
              '${l10n?.viewAll ?? 'View all'} >>',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFFEA7A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
