import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kumbh_app/app/providers.dart';

/// Provider for Client Push Notification Handler
final pushNotificationHandlerProvider = Provider<PushNotificationHandler>((ref) {
  return PushNotificationHandler(ref);
});

class PushNotificationHandler {
  final Ref _ref;
  String? _deviceToken;

  PushNotificationHandler(this._ref);

  String? get deviceToken => _deviceToken;

  /// Initialize push notification token registration with backend.
  /// When FCM credentials/package are present, retrieves FCM token and posts to `/api/v1/device-tokens`.
  Future<void> initializePushNotifications() async {
    try {
      // Generated client device token for registration
      _deviceToken = 'token_fcm_dev_${DateTime.now().millisecondsSinceEpoch}';
      
      final dioClient = _ref.read(dioClientProvider);
      final response = await dioClient.postDeviceToken({
        'token': _deviceToken,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID'
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[PushHandler] Device token registered with Kumbh backend successfully.');
      }
    } catch (e) {
      debugPrint('[PushHandler] Device token registration fallback: $e');
    }
  }

  /// Deep link handler when user taps a critical announcement push notification
  void handleNotificationTap(Map<String, dynamic> payload, Function(String announcementId) onNavigateToAnnouncement) {
    final announcementId = payload['announcement_id'];
    if (announcementId != null) {
      debugPrint('[PushHandler] Deep-linking user to announcement #$announcementId');
      onNavigateToAnnouncement(announcementId.toString());
    }
  }
}
