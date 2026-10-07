import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kumbh_app/l10n/app_localizations.dart';
import 'package:kumbh_app/features/more/presentation/family_safety_screen.dart';
import 'package:kumbh_app/features/more/presentation/lost_found_screen.dart';
import 'package:kumbh_app/features/sos/authority_responder_screen.dart';
import 'package:kumbh_app/app/providers.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E9),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
          children: [
            const SizedBox(height: 16),
            _languageRow(context, ref, locale, l10n),
            const SizedBox(height: 16),
            _heroHelpCard(l10n),
            const SizedBox(height: 16),
            Text(l10n.helpAndSafety,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _primaryCard(
              context,
              title: l10n.familySafety,
              subtitle: 'Stay connected and safe',
              icon: Icons.family_restroom,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FamilySafetyScreen())),
            ),
            const SizedBox(height: 12),
            _primaryCard(
              context,
              title: l10n.lostAndFound,
              subtitle: 'Lost/Found something? Find it here.',
              icon: Icons.search,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LostFoundScreen())),
            ),
            const SizedBox(height: 12),
            _primaryCard(
              context,
              title: 'Authority SOS Command Desk',
              subtitle: 'Police & Medical Incident Dispatch',
              icon: Icons.shield,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AuthorityResponderScreen())),
            ),
            const SizedBox(height: 16),
            Text(l10n.helpAndSafety,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF7A00)),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8)
                ],
              ),
              child: Column(
                children: [
                  _listItem(context, l10n.events, Icons.event,
                      onTap: () => Navigator.pushNamed(context, '/events')),
                  const Divider(height: 1),
                  _listItem(context, l10n.doSAndDonTs, Icons.rule,
                      onTap: () => Navigator.pushNamed(context, '/content',
                          arguments: 'Do’s & Don’ts')),
                  const Divider(height: 1),
                  _listItem(context, l10n.keyAnnouncement, Icons.campaign,
                      onTap: () => Navigator.pushNamed(context, '/content',
                          arguments: 'Key Announcement')),
                  const Divider(height: 1),
                  _listItem(context, l10n.faqs, Icons.help_outline,
                      onTap: () => Navigator.pushNamed(context, '/content',
                          arguments: 'FAQs')),
                  const Divider(height: 1),
                  _listItem(context, l10n.studyOnKumbh, Icons.school,
                      onTap: () => Navigator.pushNamed(context, '/content',
                          arguments: 'Study on Kumbh')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listItem(BuildContext context, String title, IconData icon,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFFEEEEEE),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.grey[600], size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFFF7A00)),
      onTap: onTap,
    );
  }

  Widget _heroHelpCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.helpAndSafety,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('We are here to help you,\nwhat help you need?',
                    style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 84,
            height: 60,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.center,
                  child: Icon(Icons.support_agent,
                      color: Colors.black87, size: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFEEEEEE),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.black87),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFFF7A00)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageRow(BuildContext context, WidgetRef ref, Locale locale, AppLocalizations l10n) {
    return Row(
      children: [
        Text(l10n.chooseYourLanguage,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => ref.read(localeProvider.notifier).setLocale('en'),
          child:
              _langChip('English', selected: locale.languageCode == 'en'),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => ref.read(localeProvider.notifier).setLocale('hi'),
          child:
              _langChip('हिंदी', selected: locale.languageCode == 'hi'),
        ),
      ],
    );
  }

  Widget _langChip(String label, {bool selected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFF7A00) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF7A00)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Text(
        label,
        style: TextStyle(
            color: selected ? Colors.white : const Color(0xFFFF7A00),
            fontWeight: FontWeight.w600),
      ),
    );
  }
}
