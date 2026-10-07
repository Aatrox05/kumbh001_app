import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kumbh_app/l10n/app_localizations.dart';
import 'package:kumbh_app/app/providers.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  static const Map<String, String> languageMap = {
    'English': 'en',
    'हिंदी': 'hi',
    'मराठी': 'mr',
    'ગુજરાતી': 'gu',
    'ಕನ್ನಡ': 'kn',
    'বাংলা': 'bn',
    'മലയാളം': 'ml',
    'తెలుగు': 'te',
  };

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    final currentLocaleCode = currentLocale.languageCode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.chooseYourLanguage,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEA7A1A),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: languageMap.entries.map((entry) {
                    final isSelected = entry.value == currentLocaleCode;
                    return ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: const Color(0xFFEA7A1A),
                      ),
                      title: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFFEA7A1A)
                              : Colors.black87,
                        ),
                      ),
                      onTap: () async {
                        await ref.read(localeProvider.notifier).setLocale(entry.value);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFFEA7A1A))
                          : null,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => _showLanguagePicker(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEA7A1A), width: 1.5),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.translate, color: Color(0xFFEA7A1A)),
              const SizedBox(width: 8),
              Text(
                l10n?.chooseYourLanguage ?? 'Choose your Language',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFEA7A1A),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, color: Color(0xFFEA7A1A)),
            ],
          ),
        ),
      ),
    );
  }
}
