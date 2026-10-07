/// Content filtering and moderation for AI responses
class ContentFilter {
  static const Set<String> _blockedKeywords = {
    'politics', 'political', 'election', 'vote', 'party',
    'religion debate', 'religious comparison', 'which religion',
    'better than', 'superior', 'inferior',
    'fake news', 'rumor', 'misinformation',
    'modern commentary', 'opinion', 'speculation',
  };

  static const Set<String> _kumbhRelatedKeywords = {
    'kumbh', 'mela', 'nashik', 'godavari', 'ghat', 'temple',
    'bath', 'snan', 'aarti', 'puja', 'pilgrimage', 'holy',
    'samudra manthan', 'amrita', 'nectar', 'devas', 'asuras',
    'simhastha', 'jupiter', 'leo', 'zodiac',
    'event', 'timing', 'schedule', 'location',
    'safety', 'emergency', 'help', 'lost', 'found',
    'route', 'direction', 'navigation', 'map',
    'history', 'mythology', 'story', 'origin', 'significance',
  };

  /// Check if content should be blocked
  static bool shouldBlock(String content) {
    final lowerContent = content.toLowerCase();
    for (final keyword in _blockedKeywords) {
      if (lowerContent.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  /// Check if content is Kumbh-related
  static bool isKumbhRelated(String content) {
    final lowerContent = content.toLowerCase();
    for (final keyword in _kumbhRelatedKeywords) {
      if (lowerContent.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  /// Filter and moderate response
  static String moderateResponse(String response, String originalQuery) {
    if (shouldBlock(response)) {
      return getSafeResponse();
    }

    if (!isKumbhRelated(originalQuery)) {
      return getGeneralResponse();
    }

    return response;
  }

  /// Public safe fallback response
  static String getSafeResponse() {
    return 'I\'m sorry, I can only provide information about Kumbh Mela events, history, safety guidance, and pilgrimage-related topics. Please ask about these subjects.';
  }

  /// Public general guidance response
  static String getGeneralResponse() {
    return 'I don\'t have verified information for this. Please verify with official authorities or check the app\'s main sections.';
  }
}
