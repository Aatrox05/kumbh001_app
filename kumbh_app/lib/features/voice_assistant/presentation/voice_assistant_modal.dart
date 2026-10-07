import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/network/connectivity_service.dart';
import '../services/voice_assistant_service.dart';

enum AssistantState {
  idle,
  listening,
  processing,
  responding,
  errorPermission,
  errorSpeechUnavailable,
  errorNetwork,
  errorAI,
  errorEmptyQuery,
}

class VoiceAssistantModal extends ConsumerStatefulWidget {
  const VoiceAssistantModal({super.key});

  @override
  ConsumerState<VoiceAssistantModal> createState() =>
      _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends ConsumerState<VoiceAssistantModal>
    with SingleTickerProviderStateMixin {
  late VoiceAssistantService _voiceService;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  AssistantState _state = AssistantState.idle;
  String _currentText = '';
  String _responseText = '';
  String _detectedLanguage = 'English';
  String _errorMessage = '';
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initialize();
  }

  Future<void> _initialize() async {
    _voiceService = VoiceAssistantService(ref.read(dioClientProvider));
    final initialized = await _voiceService.initialize();

    try {
      final connectivity = ConnectivityService();
      _isOnline = await connectivity.hasConnection();
    } catch (_) {
      _isOnline = true;
    }

    if (!initialized) {
      setState(() {
        _state = AssistantState.errorSpeechUnavailable;
        _errorMessage =
            'Speech recognition is not available on this device.';
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  String _getLocaleId() {
    return _detectedLanguage.toLowerCase() == 'hindi' ? 'hi_IN' : 'en_US';
  }

  Future<void> _startListening() async {
    if (_state == AssistantState.listening ||
        _state == AssistantState.processing ||
        _state == AssistantState.responding) {
      return;
    }

    setState(() {
      _state = AssistantState.listening;
      _currentText = '';
      _responseText = '';
      _errorMessage = '';
    });
    _pulseController.repeat(reverse: true);

    try {
      final connectivity = ConnectivityService();
      _isOnline = await connectivity.hasConnection();

      final result = await _voiceService.startListening(
        localeId: _getLocaleId(),
      );
      _pulseController.stop();
      _pulseController.value = 1.0;

      final recognizedText = (result['text'] as String? ?? '').trim();
      final language = result['language'] as String? ?? 'English';

      setState(() {
        _currentText = recognizedText;
        _detectedLanguage = language;
      });

      if (recognizedText.isEmpty) {
        setState(() {
          _state = AssistantState.errorEmptyQuery;
          _errorMessage = "I didn't catch that. Please try again.";
        });
        _resetToIdleAfterDelay();
        return;
      }

      await _processQuery(recognizedText);
    } catch (e) {
      _pulseController.stop();
      _pulseController.value = 1.0;
      final msg = e.toString().toLowerCase();

      if (msg.contains('permission') || msg.contains('denied')) {
        setState(() {
          _state = AssistantState.errorPermission;
          _errorMessage =
              'Microphone permission denied. Please enable it in your device settings.';
        });
      } else if (msg.contains('not available') ||
          msg.contains('unavailable') ||
          msg.contains('not initialized')) {
        setState(() {
          _state = AssistantState.errorSpeechUnavailable;
          _errorMessage =
              'Speech recognition is not available on this device.';
        });
      } else {
        setState(() {
          _state = AssistantState.errorEmptyQuery;
          _errorMessage = "I didn't catch that. Please try again.";
        });
      }
      _resetToIdleAfterDelay();
    }
  }

  Future<void> _processQuery(String query) async {
    setState(() {
      _state = AssistantState.processing;
    });

    bool queryOnline = true;
    try {
      final connectivity = ConnectivityService();
      queryOnline = await connectivity.hasConnection();
      _isOnline = queryOnline;
    } catch (_) {}

    try {
      final response =
          await _voiceService.processQuery(query, _detectedLanguage);
      final text = response['text'] as String? ?? '';
      final lang = response['language'] as String? ?? _detectedLanguage;
      final confidence = response['confidence'] as double? ?? 0.0;

      setState(() {
        _responseText = text;
        _detectedLanguage = lang;
        _state = AssistantState.responding;
      });

      if (!queryOnline) {
        setState(() {
          _state = AssistantState.errorNetwork;
          _errorMessage = 'Offline mode. Showing cached responses only.';
        });
      } else if (confidence < 0.5 && queryOnline) {
        setState(() {
          _state = AssistantState.errorAI;
          _errorMessage =
              'AI service currently unavailable. Showing cached guidance.';
        });
      }

      if (text.isNotEmpty) {
        await _voiceService.speak(text, _detectedLanguage);
      }

      _resetToIdleAfterDelay();
    } catch (e) {
      if (!queryOnline) {
        setState(() {
          _state = AssistantState.errorNetwork;
          _errorMessage = 'Offline mode. Showing cached responses only.';
        });
      } else {
        setState(() {
          _state = AssistantState.errorAI;
          _errorMessage =
              'AI service currently unavailable. Showing cached guidance.';
        });
      }
      _resetToIdleAfterDelay();
    }
  }

  void _resetToIdleAfterDelay() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          if (_state != AssistantState.listening &&
              _state != AssistantState.processing &&
              _state != AssistantState.responding) {
            // keep idle after errors only if no new actions
          }
          if (_state == AssistantState.errorEmptyQuery ||
              _state == AssistantState.errorNetwork) {
            _state = AssistantState.idle;
          }
        });
      }
    });
  }

  String _getStateText() {
    switch (_state) {
      case AssistantState.listening:
        return 'Listening...';
      case AssistantState.processing:
        return 'Processing...';
      case AssistantState.responding:
        return 'Responding...';
      case AssistantState.errorPermission:
        return 'Permission Denied';
      case AssistantState.errorSpeechUnavailable:
        return 'Speech Unavailable';
      case AssistantState.errorNetwork:
        return 'Offline Mode';
      case AssistantState.errorAI:
        return 'AI Unavailable';
      case AssistantState.errorEmptyQuery:
        return 'Try Again';
      case AssistantState.idle:
        return 'Tap to ask';
    }
  }

  Widget _buildStateIcon() {
    switch (_state) {
      case AssistantState.listening:
        return const Icon(Icons.mic, size: 32, color: Colors.white);
      case AssistantState.processing:
        return const Icon(Icons.hourglass_empty, size: 32, color: Colors.white);
      case AssistantState.responding:
        return const Icon(Icons.volume_up, size: 32, color: Colors.white);
      case AssistantState.errorPermission:
      case AssistantState.errorSpeechUnavailable:
      case AssistantState.errorNetwork:
      case AssistantState.errorAI:
      case AssistantState.errorEmptyQuery:
        return const Icon(Icons.error_outline, size: 32, color: Colors.white);
      case AssistantState.idle:
        return const Icon(Icons.mic_none, size: 32, color: Colors.white);
    }
  }

  Color _getButtonColor() {
    switch (_state) {
      case AssistantState.listening:
        return Colors.red;
      case AssistantState.processing:
        return Colors.orange;
      case AssistantState.responding:
        return Colors.green.shade600;
      case AssistantState.errorPermission:
      case AssistantState.errorSpeechUnavailable:
      case AssistantState.errorNetwork:
      case AssistantState.errorAI:
      case AssistantState.errorEmptyQuery:
        return Colors.grey.shade600;
      case AssistantState.idle:
        return const Color(0xFFEA7A1A);
    }
  }

  Color _getHeaderBgColor() {
    switch (_state) {
      case AssistantState.listening:
        return Colors.red.shade700;
      case AssistantState.processing:
        return Colors.orange.shade700;
      case AssistantState.responding:
        return Colors.green.shade700;
      default:
        return const Color(0xFFEA7A1A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActionable = _state == AssistantState.idle ||
        _state == AssistantState.errorPermission ||
        _state == AssistantState.errorSpeechUnavailable ||
        _state == AssistantState.errorNetwork ||
        _state == AssistantState.errorAI ||
        _state == AssistantState.errorEmptyQuery;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _getHeaderBgColor(),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    ScaleTransition(
                      scale: _state == AssistantState.listening
                          ? _pulseAnimation
                          : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: _state == AssistantState.listening
                              ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3)
                              : null,
                        ),
                        child: Icon(
                          _getHeaderIcon(),
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getHeaderTitle(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_state == AssistantState.errorPermission ||
                      _state == AssistantState.errorSpeechUnavailable ||
                      _state == AssistantState.errorNetwork ||
                      _state == AssistantState.errorAI ||
                      _state == AssistantState.errorEmptyQuery)
                    _buildErrorBanner(),
                  if (_currentText.isNotEmpty) _buildUserQueryCard(),
                  const SizedBox(height: 12),
                  if (_responseText.isNotEmpty) _buildAIResponseCard(),
                  if (_currentText.isEmpty &&
                      _responseText.isEmpty &&
                      !_isErrorState())
                    _buildIdleHint(),
                  const Spacer(),
                  _buildStateBadge(),
                  const SizedBox(height: 14),
                  Center(
                    child: GestureDetector(
                      onTap: isActionable ? _startListening : null,
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: _getButtonColor(),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(child: _buildStateIcon()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStateText(),
                    style: TextStyle(
                      color: _getStateTextColor(),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!_isErrorState())
                    Text(
                      'Ask about Kumbh Mela, events, routes, or safety.',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isErrorState() {
    return _state == AssistantState.errorPermission ||
        _state == AssistantState.errorSpeechUnavailable ||
        _state == AssistantState.errorNetwork ||
        _state == AssistantState.errorAI ||
        _state == AssistantState.errorEmptyQuery;
  }

  IconData _getHeaderIcon() {
    switch (_state) {
      case AssistantState.listening:
        return Icons.mic;
      case AssistantState.processing:
        return Icons.hourglass_empty;
      case AssistantState.responding:
        return Icons.volume_up;
      case AssistantState.errorPermission:
      case AssistantState.errorSpeechUnavailable:
      case AssistantState.errorNetwork:
      case AssistantState.errorAI:
      case AssistantState.errorEmptyQuery:
        return Icons.info_outline;
      case AssistantState.idle:
        return Icons.mic;
    }
  }

  String _getHeaderTitle() {
    switch (_state) {
      case AssistantState.listening:
        return 'Listening...';
      case AssistantState.processing:
        return 'Processing...';
      case AssistantState.responding:
        return 'Responding...';
      default:
        return 'AI Voice Assistant';
    }
  }

  Color _getStateTextColor() {
    switch (_state) {
      case AssistantState.listening:
        return Colors.red;
      case AssistantState.processing:
        return Colors.orange;
      case AssistantState.responding:
        return Colors.green.shade700;
      case AssistantState.errorPermission:
      case AssistantState.errorSpeechUnavailable:
      case AssistantState.errorEmptyQuery:
        return Colors.red.shade700;
      case AssistantState.errorNetwork:
      case AssistantState.errorAI:
        return Colors.orange.shade800;
      case AssistantState.idle:
        return Colors.grey.shade700;
    }
  }

  Widget _buildErrorBanner() {
    Color bg;
    Color border;
    Color textColor;
    IconData icon;

    switch (_state) {
      case AssistantState.errorPermission:
        bg = Colors.red.shade50;
        border = Colors.red.shade300;
        textColor = Colors.red.shade800;
        icon = Icons.mic_off;
        break;
      case AssistantState.errorSpeechUnavailable:
        bg = Colors.red.shade50;
        border = Colors.red.shade300;
        textColor = Colors.red.shade800;
        icon = Icons.not_interested;
        break;
      case AssistantState.errorNetwork:
        bg = Colors.orange.shade50;
        border = Colors.orange.shade300;
        textColor = Colors.orange.shade800;
        icon = Icons.wifi_off;
        break;
      case AssistantState.errorAI:
        bg = Colors.orange.shade50;
        border = Colors.orange.shade300;
        textColor = Colors.orange.shade800;
        icon = Icons.cloud_off;
        break;
      case AssistantState.errorEmptyQuery:
      default:
        bg = Colors.grey.shade100;
        border = Colors.grey.shade300;
        textColor = Colors.grey.shade800;
        icon = Icons.refresh;
        break;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserQueryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You asked:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentText,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIResponseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCC80), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFEA7A1A),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.temple_hindu, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Assistant:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEA7A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _responseText,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleHint() {
    return Expanded(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                size: 52,
                color: Colors.orange.shade200,
              ),
              const SizedBox(height: 16),
              const Text(
                'Try asking:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              _buildHintChip('What is Kumbh Mela?'),
              _buildHintChip('Tell me about Ramkund'),
              _buildHintChip('Emergency helpline numbers'),
              _buildHintChip('Best time for holy dip'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHintChip(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFFEA7A1A),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStateBadge() {
    if (_state == AssistantState.idle ||
        _state == AssistantState.errorPermission ||
        _state == AssistantState.errorSpeechUnavailable) {
      return const SizedBox.shrink();
    }

    IconData icon;
    String label;
    Color color;

    switch (_state) {
      case AssistantState.listening:
        icon = Icons.mic;
        label = 'Hearing you clearly';
        color = Colors.red;
        break;
      case AssistantState.processing:
        icon = Icons.autorenew;
        label = 'Finding the best answer...';
        color = Colors.orange;
        break;
      case AssistantState.responding:
        icon = Icons.volume_up;
        label = 'Speaking response aloud';
        color = Colors.green.shade700;
        break;
      case AssistantState.errorNetwork:
        icon = Icons.wifi_off;
        label = 'Using local knowledge base';
        color = Colors.orange;
        break;
      case AssistantState.errorAI:
        icon = Icons.cloud_off;
        label = 'Using cached guidance';
        color = Colors.orange.shade700;
        break;
      case AssistantState.errorEmptyQuery:
        icon = Icons.refresh;
        label = 'Tap mic to try again';
        color = Colors.grey;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
