import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kumbh_app/l10n/app_localizations.dart';
import 'package:kumbh_app/app/providers.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen> {
  static const Color brand = Color(0xFFEA7A1A);
  static const languages = <String>[
    'English',
    'हिंदी',
    'मराठी',
    'ગુજરાતી',
    'ಕನ್ನಡ',
    'বাংলা',
    'മലയാളം',
    'తెలుగు',
  ];

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

  String? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentLocale = ref.read(localeProvider);
      final currentCode = currentLocale.languageCode;
      
      final entry = languageMap.entries.firstWhere(
        (e) => e.value == currentCode,
        orElse: () => languageMap.entries.first,
      );
      setState(() {
        _selected = entry.key;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: brand,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/kumbh_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.temple_hindu,
                            size: 64, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n?.chooseYourLanguage ?? 'Choose your Language',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: languages
                        .map(
                          (lang) => _LanguageChip(
                            label: lang,
                            selected: _selected == lang,
                            onTap: () async {
                              setState(() {
                                _selected = lang;
                              });
                              // Capture navigator before async gap
                              final nav = Navigator.of(context);
                              // Update global locale via Riverpod
                              final code = languageMap[lang] ?? 'en';
                              await ref.read(localeProvider.notifier).setLocale(code);

                              if (mounted) {
                                nav.pushReplacementNamed(
                                  '/language_selected',
                                  arguments: lang,
                                );
                              }
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Power by IronPixel',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LanguageSelectedScreen extends StatefulWidget {
  final String selectedLanguage;
  const LanguageSelectedScreen({super.key, required this.selectedLanguage});

  @override
  State<LanguageSelectedScreen> createState() => _LanguageSelectedScreenState();
}

class _LanguageSelectedScreenState extends State<LanguageSelectedScreen> {
  static const Color brand = Color(0xFFEA7A1A);
  static const languages = <String>[
    'English',
    'हिंदी',
    'मराठी',
    'ગુજરાતી',
    'ಕನ್ನಡ',
    'বাংলা',
    'മലയാളം',
    'తెలుగు',
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home',
          arguments: widget.selectedLanguage);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: brand,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/kumbh_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.temple_hindu,
                          size: 64, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n?.chooseYourLanguage ?? 'Choose your Language',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: languages
                      .map(
                        (lang) => _LanguageChip(
                          label: lang,
                          selected: widget.selectedLanguage == lang,
                          onTap: () {},
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Power by IronPixel',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color brand = Color(0xFFEA7A1A);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: selected ? Colors.white : Colors.transparent,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? brand : Colors.white,
          ),
        ),
      ),
    );
  }
}
