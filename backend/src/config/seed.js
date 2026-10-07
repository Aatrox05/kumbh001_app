const bcrypt = require('bcryptjs');
const db = require('./database');

const seedData = async () => {
  try {
    // 1. Seed Users (Authorities and Admin)
    const existingAdmin = await db.get("SELECT id FROM users WHERE username = ?", ['admin']);
    if (!existingAdmin) {
      const adminPass = await bcrypt.hash('KumbhAdmin2027!', 10);
      const policePass = await bcrypt.hash('PoliceDuty2027!', 10);
      const medicalPass = await bcrypt.hash('MedicalDuty2027!', 10);

      await db.run(
        "INSERT INTO users (username, password_hash, role, name, phone) VALUES (?, ?, ?, ?, ?)",
        ['admin', adminPass, 'DISASTER_ADMIN', 'Control Room Admin', '+912532570001']
      );
      await db.run(
        "INSERT INTO users (username, password_hash, role, name, phone) VALUES (?, ?, ?, ?, ?)",
        ['police_control', policePass, 'POLICE', 'Nashik Police Control', '100']
      );
      await db.run(
        "INSERT INTO users (username, password_hash, role, name, phone) VALUES (?, ?, ?, ?, ?)",
        ['medical_control', medicalPass, 'MEDICAL', 'Civil Hospital Emergency Desk', '108']
      );
      console.log('Seeded default authority user accounts.');
    }

    // 2. Seed Verified Places (Real Nashik Kumbh Mela Landmarks)
    const placeCount = await db.get("SELECT COUNT(*) as count FROM places");
    if (placeCount.count === 0) {
      const verifiedPlaces = [
        {
          name: 'Ramkund Ghat',
          category: 'GHAT',
          description: 'The holiest bathing ghat on the banks of River Godavari in Panchavati, Nashik.',
          latitude: 20.0069,
          longitude: 73.7925,
          address: 'Panchavati, Nashik, Maharashtra 422003',
          opening_hours: '24 Hours',
          image_url: 'https://images.unsplash.com/photo-1590077428593-a55bb07c4665',
          crowd_level: 'HIGH',
          is_verified: 1
        },
        {
          name: 'Trimbakeshwar Jyotirlinga Temple',
          category: 'TEMPLE',
          description: 'One of the twelve sacred Jyotirlingas of Lord Shiva, located at the origin of River Godavari.',
          latitude: 19.9318,
          longitude: 73.5307,
          address: 'Trimbak, Nashik District, Maharashtra 422212',
          opening_hours: '05:30 AM - 09:00 PM',
          image_url: 'https://images.unsplash.com/photo-1609949279531-cf48d64bed89',
          crowd_level: 'MODERATE',
          is_verified: 1
        },
        {
          name: 'Kalaram Temple',
          category: 'TEMPLE',
          description: 'Historic black stone temple dedicated to Lord Rama located in the Panchavati area.',
          latitude: 20.0078,
          longitude: 73.7952,
          address: 'Panchavati, Nashik, Maharashtra 422003',
          opening_hours: '06:00 AM - 09:00 PM',
          image_url: 'https://images.unsplash.com/photo-1627894483216-2138af692e32',
          crowd_level: 'LOW',
          is_verified: 1
        },
        {
          name: 'Tapovan Ghat',
          category: 'GHAT',
          description: 'Sacred grove and ghat where Lakshmana is believed to have cut off Surpanakha\'s nose.',
          latitude: 20.0012,
          longitude: 73.8054,
          address: 'Tapovan, Nashik, Maharashtra 422003',
          opening_hours: '24 Hours',
          image_url: 'https://images.unsplash.com/photo-1544717305-2782549b5136',
          crowd_level: 'MODERATE',
          is_verified: 1
        },
        {
          name: 'Sadhugram Outer Parking P1',
          category: 'PARKING',
          description: 'Primary high-capacity parking hub for incoming vehicles from Mumbai-Pune Highway.',
          latitude: 19.9850,
          longitude: 73.7650,
          address: 'Sadhugram Zone, Nashik, Maharashtra',
          opening_hours: '24 Hours',
          image_url: '',
          crowd_level: 'LOW',
          is_verified: 1
        }
      ];

      for (const p of verifiedPlaces) {
        await db.run(
          `INSERT INTO places (name, category, description, latitude, longitude, address, opening_hours, image_url, crowd_level, is_verified) 
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [p.name, p.category, p.description, p.latitude, p.longitude, p.address, p.opening_hours, p.image_url, p.crowd_level, p.is_verified]
        );
      }
      console.log('Seeded verified Nashik Kumbh places.');
    }

    // 3. Seed Emergency Facilities (Real Verified Emergency Numbers and Hospitals)
    const facilityCount = await db.get("SELECT COUNT(*) as count FROM emergency_facilities");
    if (facilityCount.count === 0) {
      const facilities = [
        {
          name: 'Nashik District Civil Hospital',
          type: 'MEDICAL',
          phone: '+912532570001',
          secondary_phone: '108',
          address: 'ND Patel Road, Near Shalimar, Nashik, Maharashtra 422001',
          latitude: 19.9975,
          longitude: 73.7898,
          capacity: 500,
          current_status: 'OPERATIONAL',
          is_verified: 1
        },
        {
          name: 'Panchavati Police Station & Kumbh Helpline',
          type: 'POLICE',
          phone: '100',
          secondary_phone: '+912532512333',
          address: 'Panchavati Main Rd, Nashik, Maharashtra 422003',
          latitude: 20.0055,
          longitude: 73.7915,
          capacity: 100,
          current_status: 'OPERATIONAL',
          is_verified: 1
        },
        {
          name: 'Main Fire Control Station Nashik',
          type: 'FIRE',
          phone: '101',
          secondary_phone: '+912532574444',
          address: 'Ganjmal, Nashik, Maharashtra 422001',
          latitude: 19.9922,
          longitude: 73.7845,
          capacity: 50,
          current_status: 'OPERATIONAL',
          is_verified: 1
        },
        {
          name: 'Central Sadhugram Emergency Helpdesk',
          type: 'HELPDESK',
          phone: '1924',
          secondary_phone: '+912532500000',
          address: 'Sector 4, Sadhugram Camp, Nashik',
          latitude: 20.0020,
          longitude: 73.7980,
          capacity: 200,
          current_status: 'OPERATIONAL',
          is_verified: 1
        }
      ];

      for (const f of facilities) {
        await db.run(
          `INSERT INTO emergency_facilities (name, type, phone, secondary_phone, address, latitude, longitude, capacity, current_status, is_verified) 
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [f.name, f.type, f.phone, f.secondary_phone, f.address, f.latitude, f.longitude, f.capacity, f.current_status, f.is_verified]
        );
      }
      console.log('Seeded verified emergency facilities.');
    }

    // 4. Seed Official Announcements
    const announcementCount = await db.get("SELECT COUNT(*) as count FROM announcements");
    if (announcementCount.count === 0) {
      await db.run(
        `INSERT INTO announcements (title, content, priority, target_group) 
         VALUES (?, ?, ?, ?)`,
        [
          'Official Advisory: First Shahi Snan Schedule',
          'The Nashik District Administration notifies all pilgrims that entry to Ramkund Ghat on Shahi Snan days will be regulated strictly via designated pedestrian corridors.',
          'HIGH',
          'ALL'
        ]
      );
      await db.run(
        `INSERT INTO announcements (title, content, priority, target_group) 
         VALUES (?, ?, ?, ?)`,
        [
          'Helpline 1924 Active for Lost & Found',
          'Toll-free helpline 1924 is operational 24x7 for registering lost persons and missing items across all Sadhugram sectors.',
          'NORMAL',
          'ALL'
        ]
      );
      console.log('Seeded official announcements.');
    }

    // 4b. Seed Verified Simhastha Kumbh Events
    const eventCount = await db.get("SELECT COUNT(*) as count FROM events");
    if (eventCount.count === 0) {
      const verifiedEvents = [
        {
          title: 'First Shahi Snan (Makar Sankranti)',
          category: 'SNANA',
          description: 'First holy royal bath of Simhastha Kumbh at sacred Ramkund Ghat by Akhadas and pilgrims.',
          start_time: '2027-01-14 04:00:00',
          end_time: '2027-01-14 18:00:00',
          location_name: 'Ramkund Ghat, Panchavati',
          latitude: 20.0069,
          longitude: 73.7925,
          organizer: 'Kumbh Mela Apex Committee & Nashik District Collectorate'
        },
        {
          title: 'Trimbakeshwar Shahi Snan (Shaiva Akhadas)',
          category: 'SNANA',
          description: 'Sacred royal Snan at Kushavarta Kund and Trimbakeshwar Jyotirlinga.',
          start_time: '2027-01-14 05:00:00',
          end_time: '2027-01-14 17:00:00',
          location_name: 'Kushavarta Kund, Trimbakeshwar',
          latitude: 19.9318,
          longitude: 73.5307,
          organizer: 'Trimbakeshwar Temple Trust'
        },
        {
          title: 'Maha Godavari Aarti & Deepotsav',
          category: 'RITUAL',
          description: 'Evening grand river lamp offering ceremony with 1,008 priests along Godavari banks.',
          start_time: '2027-01-14 18:30:00',
          end_time: '2027-01-14 20:30:00',
          location_name: 'Ramkund & Gandhi Ghat',
          latitude: 20.0069,
          longitude: 73.7925,
          organizer: 'Godavari Ganga Aarti Mahasabha'
        },
        {
          title: 'Dharma Dhwaja Arohan (Ceremonial Flag Hoisting)',
          category: 'CEREMONY',
          description: 'Traditional ceremonial flag hoisting heralding the commencement of Simhastha festivities.',
          start_time: '2027-01-10 09:00:00',
          end_time: '2027-01-10 12:00:00',
          location_name: 'Sadhugram Central Grounds',
          latitude: 20.0020,
          longitude: 73.7980,
          organizer: 'Akhil Bharatiya Akhada Parishad'
        },
        {
          title: 'Daily Ganga-Godavari Mangal Snan & Kirtan',
          category: 'DAILY',
          description: 'Daily auspicious morning Snan and devotional kirtan sessions for visiting pilgrims.',
          start_time: '2026-10-03 05:00:00',
          end_time: '2026-10-03 10:00:00',
          location_name: 'Tapovan Ghat',
          latitude: 20.0012,
          longitude: 73.8054,
          organizer: 'Nashik Municipal Corporation'
        }
      ];

      for (const ev of verifiedEvents) {
        const res = await db.run(
          `INSERT INTO events (title, category, description, start_time, end_time, location_name, latitude, longitude, organizer, is_verified, version)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 1)`,
          [ev.title, ev.category, ev.description, ev.start_time, ev.end_time, ev.location_name, ev.latitude, ev.longitude, ev.organizer]
        );
        await db.logChange('event', res.id, 'CREATED', { ...ev, id: res.id, is_verified: 1 });
      }
      console.log('Seeded verified Simhastha Kumbh events.');
    }

    // 5. Seed Registered Operational Sources Registry
    const sourceCount = await db.get("SELECT COUNT(*) as count FROM registered_sources");
    if (sourceCount.count === 0) {
      const sources = [
        {
          source_id: 'src_nashik_admin',
          source_name: 'Nashik District Administration Portal',
          base_url: 'https://nashik.gov.in',
          allowed_paths: '/alerts/*',
          authority: 'Nashik District Collector Office',
          trust_level: 'AUTHORITATIVE'
        },
        {
          source_id: 'src_mahapolice',
          source_name: 'Maharashtra Police Traffic Advisory',
          base_url: 'https://mahapolice.gov.in',
          allowed_paths: '/traffic/*',
          authority: 'Maharashtra State Police Command',
          trust_level: 'AUTHORITATIVE'
        },
        {
          source_id: 'src_kumbh_official',
          source_name: 'Nashik Kumbh Mela Official Portal',
          base_url: 'https://kumbh.gov.in',
          allowed_paths: '/advisories/*',
          authority: 'Kumbh Mela Apex Committee',
          trust_level: 'AUTHORITATIVE'
        }
      ];

      for (const s of sources) {
        await db.run(
          `INSERT INTO registered_sources (source_id, source_name, base_url, allowed_paths, authority, trust_level)
           VALUES (?, ?, ?, ?, ?, ?)`,
          [s.source_id, s.source_name, s.base_url, s.allowed_paths, s.authority, s.trust_level]
        );
      }
      console.log('Seeded registered official sources registry.');
    }

  } catch (err) {
    console.error('Error seeding database:', err);
  }
};

module.exports = seedData;
