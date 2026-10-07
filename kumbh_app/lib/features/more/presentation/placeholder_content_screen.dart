import 'package:flutter/material.dart';

class PlaceholderContentScreen extends StatelessWidget {
  final String title;
  const PlaceholderContentScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E9),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFF7A00),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: _buildContentForTitle(context, title),
        ),
      ),
    );
  }

  List<Widget> _buildContentForTitle(BuildContext context, String screenTitle) {
    final lower = screenTitle.toLowerCase();

    if (lower.contains('do') && lower.contains('don')) {
      return _buildDosAndDonts(context);
    } else if (lower.contains('faq')) {
      return _buildFaqs(context);
    } else if (lower.contains('announcement')) {
      return _buildKeyAnnouncements(context);
    } else if (lower.contains('study')) {
      return _buildStudyOnKumbh(context);
    }

    return _buildGeneralAdvisory(context, screenTitle);
  }

  List<Widget> _buildDosAndDonts(BuildContext context) {
    return [
      _buildHeaderCard(
        title: 'Official Pilgrim Safety Guidelines',
        subtitle:
            'Issued by the Nashik District Disaster Management Authority for Simhastha Kumbh Mela.',
        icon: Icons.verified_user,
        iconColor: Colors.green.shade700,
      ),
      const SizedBox(height: 16),
      const Text(
        'DO\'S (अवश्य करें)',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E7D32),
        ),
      ),
      const SizedBox(height: 8),
      _buildRuleCard(
        icon: Icons.badge,
        color: Colors.green,
        title: 'Child & Senior Citizen Identification',
        body:
            'Attach an emergency contact wristband or ID card to children and elderly family members with their name and phone number.',
      ),
      _buildRuleCard(
        icon: Icons.directions_walk,
        color: Colors.green,
        title: 'Follow Designated Corridors',
        body:
            'Always move along the demarcated one-way pedestrian routes towards Ramkund Ghat and respect queue barricades.',
      ),
      _buildRuleCard(
        icon: Icons.local_hospital,
        color: Colors.green,
        title: 'Seek Immediate First Aid',
        body:
            'Emergency Medical Units are stationed every 500 meters along all major routes. Dial 108 or 102 for quick ambulance support.',
      ),
      _buildRuleCard(
        icon: Icons.restore_from_trash,
        color: Colors.green,
        title: 'Keep Sacred Ghats Clean',
        body:
            'Dispose of ritual offerings, wet clothes, and biodegradable items only in green bio-bins provided along River Godavari.',
      ),
      const SizedBox(height: 20),
      const Text(
        'DON\'TS (कदापि न करें)',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFFC62828),
        ),
      ),
      const SizedBox(height: 8),
      _buildRuleCard(
        icon: Icons.block,
        color: Colors.red,
        title: 'No Plastic Allowed',
        body:
            'Single-use plastic bags and bottles are strictly prohibited across the entire Kumbh Mela riverbank perimeter.',
      ),
      _buildRuleCard(
        icon: Icons.pool,
        color: Colors.red,
        title: 'Do Not Bathe Beyond Safety Nets',
        body:
            'Never cross safety barriers or warning buoys into deep waters or fast currents of the Godavari River.',
      ),
      _buildRuleCard(
        icon: Icons.pan_tool,
        color: Colors.red,
        title: 'Do Not Halt on Bridges & Stairs',
        body:
            'Stopping on narrow pedestrian bridges, flyovers, or entry ramps causes sudden crowd stampedes. Keep moving continuously.',
      ),
      _buildRuleCard(
        icon: Icons.flight,
        color: Colors.red,
        title: 'Unauthorized Drones Prohibited',
        body:
            'Civilian drone flying is banned in the high-security airspace over Panchavati and Sadhugram without official police permission.',
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _buildFaqs(BuildContext context) {
    return [
      _buildHeaderCard(
        title: 'Frequently Asked Questions (FAQs)',
        subtitle:
            'Common queries regarding ritual bathing timings, transit, stay, and lost assistance.',
        icon: Icons.help_center,
        iconColor: const Color(0xFFFF7A00),
      ),
      const SizedBox(height: 16),
      _buildFaqTile(
        question: 'What are the main Shahi Snan (Royal Bathing) dates?',
        answer:
            'The three primary Shahi Snan dates for Nashik-Trimbakeshwar Simhastha are:\n1. First Shahi Snan: Makar Sankranti\n2. Second Shahi Snan (Maha Snan): Mauni Amavasya\n3. Third Shahi Snan: Basant Panchami.\nEntry to Ramkund Ghat on these dates is strictly regulated for sadhu akhadas during the morning hours.',
      ),
      _buildFaqTile(
        question: 'Can private vehicles drive directly to Ramkund Ghat?',
        answer:
            'No. During the festival period, inner city zones are designated as pedestrian-only. All personal cars, taxis, and buses must park at outer satellite parking hubs (e.g., Sadhugram Outer P1). Free government shuttle buses transport pilgrims from parking zones to entry points.',
      ),
      _buildFaqTile(
        question: 'Where can I report a lost person or child?',
        answer:
            'You can register an instant photo report directly within this app under the "Lost & Found" section. Alternatively, call the 24x7 Kumbh Helpline at 1924, or visit the Central Lost & Found Control Booth in Sadhugram Sector 4.',
      ),
      _buildFaqTile(
        question: 'Is drinking water and food available near the ghats?',
        answer:
            'Yes. Hundreds of municipal Jal Seva filtered water stations and approved Annakshetra (free food distribution centers) operate 24x7 throughout Panchavati, Tapovan, and Sadhugram.',
      ),
      _buildFaqTile(
        question: 'What should I do in case of a medical emergency?',
        answer:
            'Immediately tap the Emergency SOS button on your screen or dial 108 / 102. If internet is down, the app will dispatch an automated SMS with your GPS coordinates to your family contacts and emergency responders.',
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _buildKeyAnnouncements(BuildContext context) {
    return [
      _buildHeaderCard(
        title: 'Official Key Advisories & Notices',
        subtitle:
            'Live updates from the Divisional Commissioner & Police Commissionerate, Nashik.',
        icon: Icons.campaign,
        iconColor: Colors.deepOrange,
      ),
      const SizedBox(height: 16),
      _buildNoticeCard(
        date: 'Today, 06:00 AM',
        priority: 'HIGH PRIORITY',
        title: 'Shahi Snan Pedestrian Flow Regulations',
        body:
            'Pilgrims arriving from Mumbai highway are advised to utilize Corridor 2 (via Tapovan road) to avoid congestion at Godavari main bridge. Queue clearance time is estimated at 35 minutes.',
      ),
      _buildNoticeCard(
        date: 'Yesterday, 04:30 PM',
        priority: 'INFORMATION',
        title: 'Special Festival Express Trains Added',
        body:
            'Central Railway has commissioned 48 additional MEMU and Superfast special trains connecting Nashik Road station to Pune, Mumbai CSMT, Nagpur, and Shirdi.',
      ),
      _buildNoticeCard(
        date: '02 Oct, 10:00 AM',
        priority: 'SAFETY',
        title: 'Weather & River Current Update',
        body:
            'Water discharge from Gangapur Dam is stabilized. All bathing ghats are operating under normal green alert levels with continuous water monitoring.',
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _buildStudyOnKumbh(BuildContext context) {
    return [
      _buildHeaderCard(
        title: 'The Simhastha Kumbh: Heritage & Science',
        subtitle:
            'A comprehensive overview of the cosmic origins, historical lineage, and modern megacity logistics.',
        icon: Icons.menu_book,
        iconColor: Colors.indigo,
      ),
      const SizedBox(height: 16),
      _buildArticleSection(
        title: '1. The Astrological Basis: Brihaspati in Leo',
        content:
            'The Nashik-Trimbakeshwar Kumbh Mela is designated as "Simhastha" because it occurs when Jupiter (Brihaspati) enters the zodiac sign of Simha (Leo), while the Sun and Moon align during the month of Bhadrapada. This rare planetary conjunction takes place every 12 years and is believed to charge the waters of the sacred Godavari River with spiritual energy.',
      ),
      _buildArticleSection(
        title: '2. The Mythological Nectar: Samudra Manthan',
        content:
            'According to Vedic texts, during the cosmic churning of the ocean (Samudra Manthan), Dhanvantari appeared with the Kumbh (pot) of Amrita (nectar of immortality). During the subsequent pursuit between Devas and Asuras, drops of nectar touched four sacred spots on earth: Prayagraj, Haridwar, Ujjain, and Nashik (at Ramkund).',
      ),
      _buildArticleSection(
        title: '3. Pop-Up Megacity Architecture',
        content:
            'Sadhugram in Nashik is engineered as a temporary smart city accommodating over 300,000 sadhus, akharas, and millions of pilgrims. It features underground electricity cables, temporary sewage networks, GIS-monitored crowd density cameras, and specialized bio-toilets to protect the river ecology.',
      ),
      _buildArticleSection(
        title: '4. Crowd Flow Dynamics & Safe Corridor Design',
        content:
            'Modern Kumbh management incorporates spatial queueing theory. Pedestrian corridors are decoupled into entry and exit arcs so arriving pilgrims never meet departing crowds, preventing wave turbulence and bottleneck pressure.',
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _buildGeneralAdvisory(BuildContext context, String text) {
    return [
      _buildHeaderCard(
        title: text,
        subtitle: 'Official information bulletin for Kumbh pilgrims.',
        icon: Icons.info_outline,
        iconColor: const Color(0xFFFF7A00),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: const Text(
          'Please refer to official signage and control room announcements for real-time schedule adjustments during the Simhastha festival.',
          style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
        ),
      ),
    ];
  }

  Widget _buildHeaderCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withValues(alpha: 0.15),
            radius: 24,
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
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

  Widget _buildRuleCard({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
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

  Widget _buildFaqTile({
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        iconColor: const Color(0xFFFF7A00),
        collapsedIconColor: Colors.grey,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard({
    required String date,
    required String priority,
    required String title,
    required String body,
  }) {
    final isHigh = priority == 'HIGH PRIORITY';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isHigh ? Colors.red : const Color(0xFFFF7A00),
            width: 4,
          ),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isHigh
                      ? Colors.red.shade100
                      : const Color(0xFFFF7A00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isHigh ? Colors.red.shade900 : const Color(0xFFFF7A00),
                  ),
                ),
              ),
              Text(
                date,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleSection({
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF283593),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
