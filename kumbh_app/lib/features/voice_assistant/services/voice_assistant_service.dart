import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../../../core/network/dio_client.dart';
import 'content_filter.dart';

class VoiceAssistantService {
  final DioClient? _dioClient;
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechInitialized = false;
  String _lastRecognizedWords = '';
  Completer<String>? _listenCompleter;

  VoiceAssistantService([this._dioClient]);

  final Map<String, Map<String, String>> _knowledgeBase = {
    'english': {
      'kumbh mela':
          'The Kumbh Mela is a sacred Hindu pilgrimage held every 12 years at four locations. Nashik hosts the Simhastha Kumbh when Jupiter is in Leo.',
      'ramkund':
          'Ramkund is the holy bathing ghat in Panchavati, Nashik on the banks of River Godavari.',
      'emergency':
          'In case of emergency, please use the Emergency SOS screen or dial 100 (Police), 108 (Ambulance), or 1924 (Kumbh Helpline).',
    },
    'hindi': {
      'कुंभ मेला':
          'कुंभ मेला हिंदू धर्म की एक पवित्र तीर्थयात्रा है जो हर 12 वर्षों में आयोजित होती है।',
      'रामकुंड':
          'रामकुंड नासिक के पंचवटी क्षेत्र में गोदावरी नदी के तट पर स्थित पवित्र स्नान घाट है।',
      'आपातकाल':
          'आपात स्थिति में कृपया 100, 108 या कुंभ हेल्पलाइन 1924 पर कॉल करें।',
    },
  };

  Future<bool> initialize() async {
    try {
      _speechInitialized = await _speechToText.initialize(
        onError: (error) {
          debugPrint('[VoiceAssistantService] Speech init error: $error');
        },
        onStatus: (status) {
          debugPrint('[VoiceAssistantService] Speech status: $status');
        },
      );
      debugPrint(
          '[VoiceAssistantService] Speech initialized: $_speechInitialized');
      return _speechInitialized;
    } catch (e) {
      debugPrint('[VoiceAssistantService] Initialization error: $e');
      _speechInitialized = false;
      return false;
    }
  }

  bool get isSpeechInitialized => _speechInitialized;
  bool get isListening => _speechToText.isListening;

  Future<Map<String, dynamic>> startListening(
      {String localeId = 'en_US'}) async {
    if (!_speechInitialized) {
      final ok = await initialize();
      if (!ok) {
        throw Exception('Speech recognition unavailable on this device');
      }
    }

    _lastRecognizedWords = '';
    _listenCompleter = Completer<String>();

    try {
      await _speechToText.listen(
        localeId: localeId,
        onResult: (SpeechRecognitionResult result) {
          _onSpeechResult(result);
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      );

      final transcription = await _listenCompleter!.future;
      final language = LanguageDetector.detectLanguage(transcription);

      return {
        'text': transcription,
        'language': language,
        'confidence': 0.85,
      };
    } catch (e) {
      debugPrint('[VoiceAssistantService] startListening error: $e');
      if (_listenCompleter != null && !_listenCompleter!.isCompleted) {
        _listenCompleter!.complete('');
      }
      rethrow;
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastRecognizedWords = result.recognizedWords;
    if (result.finalResult) {
      debugPrint('[VoiceAssistantService] Final result: $_lastRecognizedWords');
      if (_listenCompleter != null && !_listenCompleter!.isCompleted) {
        _listenCompleter!.complete(_lastRecognizedWords);
      }
    }
  }

  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
      if (_listenCompleter != null && !_listenCompleter!.isCompleted) {
        _listenCompleter!.complete(_lastRecognizedWords);
      }
    } catch (e) {
      debugPrint('[VoiceAssistantService] stopListening error: $e');
    }
  }

  Future<void> cancelListening() async {
    try {
      await _speechToText.cancel();
      if (_listenCompleter != null && !_listenCompleter!.isCompleted) {
        _listenCompleter!.complete('');
      }
    } catch (e) {
      debugPrint('[VoiceAssistantService] cancelListening error: $e');
    }
  }

  Future<Map<String, dynamic>> processQuery(
    String query,
    String fallbackLanguage,
  ) async {
    try {
      final detectedLanguage = LanguageDetector.detectLanguage(query);

      if (ContentFilter.shouldBlock(query)) {
        return createResponse(
          ContentFilter.getSafeResponse(),
          detectedLanguage,
          0.0,
        );
      }

      if (!ContentFilter.isKumbhRelated(query)) {
        return createResponse(
          ContentFilter.getGeneralResponse(),
          detectedLanguage,
          0.0,
        );
      }

      if (_dioClient != null) {
        try {
          final res = await _dioClient!.postAIQuery(query);
          if (res.statusCode == 200 &&
              res.data != null &&
              res.data['success'] == true) {
            final String aiText = res.data['answer'] ?? '';
            if (aiText.isNotEmpty) {
              return createResponse(aiText, detectedLanguage, 0.95);
            }
          }
        } catch (e) {
          debugPrint(
              '[VoiceAssistantService] AI Backend query failed, falling back: $e');
        }
      }

      final langKey = detectedLanguage.toLowerCase();
      final processedQuery = query.toLowerCase();
      final langData = _knowledgeBase[langKey] ?? _knowledgeBase['english']!;

      String response = findBestResponse(processedQuery, langData);

      if (response.isEmpty) {
        response =
            "I do not have verified official information for this query. Please contact the 24x7 Kumbh Helpline at 1924.";
      }

      response = ContentFilter.moderateResponse(response, query);

      return createResponse(response, detectedLanguage, 0.9);
    } catch (_) {
      return createResponse(
        ContentFilter.getGeneralResponse(),
        fallbackLanguage,
        0.0,
      );
    }
  }

  Map<String, dynamic> createResponse(
    String text,
    String language,
    double confidence,
  ) {
    return {
      'text': text,
      'language': language,
      'confidence': confidence,
    };
  }

  String findBestResponse(
    String query,
    Map<String, String> knowledgeBase,
  ) {
    for (final entry in knowledgeBase.entries) {
      final keywords = entry.key.split(' ');
      int matches = 0;

      for (final word in keywords) {
        if (query.contains(word)) {
          matches++;
        }
      }

      if (matches > 0 && matches >= keywords.length / 2) {
        return entry.value;
      }
    }
    return '';
  }

  Future<void> speak(String text, String language) async {
    try {
      if (language.toLowerCase() == 'hindi') {
        await _tts.setLanguage('hi-IN');
      } else {
        await _tts.setLanguage('en-US');
      }
      await _tts.setSpeechRate(0.9);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[VoiceAssistantService] TTS error: $e');
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('[VoiceAssistantService] TTS stop error: $e');
    }
  }

  void dispose() {
    try {
      _speechToText.cancel();
      _tts.stop();
    } catch (e) {
      debugPrint('[VoiceAssistantService] Disposal error: $e');
    }
  }
}

class LanguageDetector {
  static String detectLanguage(String text) {
    if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
      return 'Hindi';
    }
    return 'English';
  }
}
