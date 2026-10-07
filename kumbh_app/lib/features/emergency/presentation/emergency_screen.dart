import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kumbh_app/l10n/app_localizations.dart';
import 'package:kumbh_app/app/providers.dart';
import 'package:geolocator/geolocator.dart';

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  int _selectedIndex = -1;
  bool _showContextPanel = false;
  bool _isTyping = false;
  final List<_ChatMessage> _messages = [];
  DateTime? _lastSosAt;

  List<_EmergencyOption> _getOptions(AppLocalizations l10n) => [
        _EmergencyOption(l10n.emergencyHelpNeeded, '112', Icons.phone_in_talk,
            isPrimary: true, isNationalStandard: true, verifiedNumber: '112'),
        _EmergencyOption(l10n.policeHelpline, '100', Icons.local_police,
            isNationalStandard: true, verifiedNumber: '100'),
        _EmergencyOption(l10n.ambulanceService, '102', Icons.medical_services,
            isNationalStandard: true, verifiedNumber: '102'),
        const _EmergencyOption('Women Helpline', '1091', Icons.woman,
            isNationalStandard: true, verifiedNumber: '1091'),
        _EmergencyOption(l10n.lostAndFound, '', Icons.search,
            isNationalStandard: false, verifiedNumber: null),
        const _EmergencyOption('Medical Camp', '', Icons.health_and_safety,
            isNationalStandard: false, verifiedNumber: null),
      ];

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startSosPulse() {
    _pulseController.repeat();
  }

  void _stopSosPulse() {
    _pulseController.stop();
    _pulseController.reset();
  }

  Future<void> _dialVerified(String? verifiedNumber, String optionName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Call $optionName?'),
        content: const Text('This will open your phone dialer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Call'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (verifiedNumber == null || verifiedNumber.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Contact Unavailable'),
          content: const Text(
              'Verified emergency contact is currently unavailable.\nPlease use your device\'s emergency calling options.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    _dialNumber(verifiedNumber);
  }

  Future<void> _onSosTap(AppLocalizations l10n) async {
    if (_lastSosAt != null &&
        DateTime.now().difference(_lastSosAt!).inSeconds < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'SOS already submitted recently. Please wait for authorities to respond.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    _pulseController
      ..reset()
      ..forward();

    double? lat;
    double? lng;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      lat = position.latitude;
      lng = position.longitude;
    } catch (e) {
      debugPrint('[SOS] Location unavailable: $e');
    }

    final contacts = ref.read(contactsProvider);
    final distressPayload = {
      'device_id': 'device_${DateTime.now().millisecondsSinceEpoch}',
      'contact_name': 'Kumbh Pilgrim',
      'contact_phone': contacts.isNotEmpty ? contacts.first.phone : '112',
      'latitude': lat,
      'longitude': lng,
      'emergency_type': 'GENERAL',
      'remarks': 'SOS: Emergency help required at Kumbh Mela Nashik.',
    };

    bool sentViaApi = false;
    try {
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.postSOS(distressPayload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        sentViaApi = true;
        debugPrint('[SOS] SOS POST successful. Response: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[SOS] SOS POST failed: $e. Triggering SMS fallback.');
    }

    if (!sentViaApi) {
      final contacts = ref.read(contactsProvider);
      if (contacts.isEmpty) {
        debugPrint('[SOS] SMS fallback: No family contacts configured. Sending to default helpline.');
        _sendSms('112', 'EMERGENCY SOS: ${distressPayload['remarks']} Location: lat=${distressPayload['latitude']}, lng=${distressPayload['longitude']}');
      } else {
        for (final contact in contacts) {
          _sendSms(
            contact.phone,
            'EMERGENCY SOS from ${distressPayload['contact_name']}: ${distressPayload['remarks']} '
            'Location: lat=${distressPayload['latitude']}, lng=${distressPayload['longitude']} '
            'Time: ${DateTime.now().toIso8601String()}',
          );
        }
      }
    }

    _lastSosAt = DateTime.now();

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('SOS Request Sent'),
          content: Text(sentViaApi
              ? 'SOS request sent to server. Awaiting authority acknowledgment.'
              : 'Network unavailable. Attempting to open SMS with your emergency contacts.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  Future<void> _sendSms(String phoneNumber, String message) async {
    final uri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('[SOS-SMS] Could not open SMS app for $phoneNumber');
    }
  }

  Future<void> _dialNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('[DIAL] Could not open phone app for $number');
    }
  }

  void _onOptionSelected(int index) {
    setState(() {
      _selectedIndex = index;
      _showContextPanel = true;
    });
  }

  void _simulateChat(String prompt) async {
    setState(() {
      _messages.add(_ChatMessage(text: prompt, isUser: true));
      _isTyping = true;
    });

    String reply;
    try {
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.postAISos(prompt);
      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['success'] == true) {
        reply = response.data['answer'].toString();
      } else {
        reply = _getFallbackReply(prompt);
      }
    } catch (e) {
      debugPrint('[AI-SOS] API call failed: $e');
      reply = _getFallbackReply(prompt);
    }

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: reply));
      });
    }
  }

  String _getFallbackReply(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    final buffer = StringBuffer(
        'For immediate safety, please move to the nearest public area with other pilgrims and dial 100 for police assistance.');

    if (lowerPrompt.contains('medical') ||
        lowerPrompt.contains('doctor') ||
        lowerPrompt.contains('hospital') ||
        lowerPrompt.contains('sick') ||
        lowerPrompt.contains('health')) {
      buffer.write('\n\nIf this is a medical emergency, please dial 102 immediately.');
    }

    if (lowerPrompt.contains('lost') ||
        lowerPrompt.contains('missing') ||
        lowerPrompt.contains('find') ||
        lowerPrompt.contains('separated')) {
      buffer.write(
          '\n\nPlease visit the nearest Lost & Found help desk or call the national police helpline 100.');
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = _getOptions(l10n);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                l10n.emergencyHelpNeeded,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.holdToCall,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final v = _pulseController.value;
                        return Opacity(
                          opacity: (1.0 - v).clamp(0.0, 1.0),
                          child: Container(
                            width: 220 * (1 + v * 0.3),
                            height: 220 * (1 + v * 0.3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFF1744)
                                  .withValues(alpha: 0.08),
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 20,
                          ),
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.1),
                            blurRadius: 40,
                            spreadRadius: 40,
                          ),
                        ],
                      ),
                      child: Center(
                        child: GestureDetector(
                          onLongPressStart: (_) => _startSosPulse(),
                          onLongPressEnd: (_) {
                            _stopSosPulse();
                            _onSosTap(l10n);
                          },
                          child: AnimatedScale(
                            scale: _pulseController.isAnimating ? 1.06 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFF1744),
                                    Color(0xFFD50000)
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    l10n.sos,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Press 5 for second',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              Text(
                l10n.whatsYourEmergency,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.0,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: List.generate(options.length, (i) {
                  final o = options[i];
                  final selected = _selectedIndex == i;
                  final bgColor =
                      o.isPrimary ? Colors.red.shade50 : Colors.white;
                  return GestureDetector(
                    onTap: () {
                      _onOptionSelected(i);
                      _dialVerified(o.verifiedNumber, o.title);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFFF7A00)
                              : (o.isPrimary
                                  ? Colors.red
                                  : Colors.grey.shade300),
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFF7A00)
                                      .withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                )
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            o.icon,
                            color: selected
                                ? const Color(0xFFFF7A00)
                                : (o.isPrimary ? Colors.red : Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            o.title,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: selected
                                  ? const Color(0xFFFF7A00)
                                  : (o.isPrimary ? Colors.red : Colors.black87),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            o.sub.isEmpty ? 'N/A' : o.sub,
                            style: TextStyle(
                              fontSize: 10,
                              color: o.sub.isEmpty
                                  ? Colors.grey
                                  : (selected
                                      ? const Color(0xFFFF7A00)
                                          .withValues(alpha: 0.7)
                                      : (o.isPrimary
                                          ? Colors.red.withValues(alpha: 0.7)
                                          : Colors.black54)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _showContextPanel
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.aiAssistant,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _simulateChat('I am lost'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFA000),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'I am lost',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Get help finding the nearest police booth.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _simulateChat('I need a doctor'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFA000),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'I need a doctor',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Find nearest medical camps & hospitals.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          for (final m in _messages)
                            Align(
                              alignment: m.isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: m.isUser
                                      ? const Color(0xFFFFF3E0)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: m.isUser
                                          ? const Color(0xFFFFA000)
                                          : Colors.grey.shade300),
                                ),
                                child: Text(
                                  m.text,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: m.isUser
                                        ? const Color(0xFFFF7A00)
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          if (_isTyping)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  _TypingDot(),
                                  SizedBox(width: 4),
                                  _TypingDot(),
                                  SizedBox(width: 4),
                                  _TypingDot(),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                secondChild: const SizedBox.shrink(),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingDot extends StatelessWidget {
  const _TypingDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
    );
  }
}

class _EmergencyOption {
  final String title;
  final String sub;
  final IconData icon;
  final bool isPrimary;
  final bool isNationalStandard;
  final String? verifiedNumber;
  const _EmergencyOption(this.title, this.sub, this.icon,
      {this.isPrimary = false,
      this.isNationalStandard = false,
      this.verifiedNumber});
}

class _ChatMessage {
  final String text;
  final bool isUser;
  const _ChatMessage({required this.text, this.isUser = false});
}
