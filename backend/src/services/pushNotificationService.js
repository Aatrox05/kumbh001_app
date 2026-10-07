class PushNotificationService {
  static async sendCriticalAlert(announcement) {
    if (announcement.priority !== 'CRITICAL' && announcement.priority !== 'IMPORTANT') {
      return;
    }

    console.log(`====================================================`);
    console.log(`🚨 [PUSH NOTIFICATION DISPATCHED]`);
    console.log(`Title: 🔔 ${announcement.title}`);
    console.log(`Priority: ${announcement.priority}`);
    console.log(`Content: ${announcement.content}`);
    console.log(`Target: ${announcement.target_group || 'ALL_USERS'}`);
    console.log(`====================================================`);
  }
}

module.exports = PushNotificationService;
