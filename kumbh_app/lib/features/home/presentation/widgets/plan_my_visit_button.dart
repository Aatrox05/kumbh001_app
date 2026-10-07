import 'package:flutter/material.dart';
import 'package:kumbh_app/l10n/app_localizations.dart';

class PlanMyVisitButton extends StatelessWidget {
  const PlanMyVisitButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/chat'),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFFEA7A1A),
            disabledBackgroundColor: const Color(0xFFEA7A1A),
            shape: const StadiumBorder(),
          ),
          child: Text(
            l10n?.planMyVisit ?? 'Plan My Visit',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
