class DbTables {
  // Places table
  static const String places = 'places';
  static const String placesId = 'id';
  static const String placesName = 'name';
  static const String placesImageUrl = 'image_url';
  static const String placesDistanceKm = 'distance_km';
  static const String placesCrowdLevel = 'crowd_level';
  static const String placesCategory = 'category';

  // Events table
  static const String events = 'events';
  static const String eventsId = 'id';
  static const String eventsName = 'name';
  static const String eventsLocationName = 'location_name';
  static const String eventsStartTime = 'start_time';
  static const String eventsEndTime = 'end_time';
  static const String eventsAudioUrl = 'audio_url';

  // Announcements table
  static const String announcements = 'announcements';

  // Contacts table
  static const String contacts = 'contacts';

  // Lost & Found reports table
  static const String lostFound = 'lost_found_reports';
  static const String lostFoundId = 'id';
  static const String lostFoundName = 'name';
  static const String lostFoundAge = 'age';
  static const String lostFoundGender = 'gender';
  static const String lostFoundLocation = 'location';
  static const String lostFoundContact = 'contact';
  static const String lostFoundDescription = 'description';
  static const String lostFoundIsLost = 'is_lost';
  static const String lostFoundSynced = 'synced';

  // Emergency Facilities table
  static const String emergencyFacilities = 'emergency_facilities';
}
