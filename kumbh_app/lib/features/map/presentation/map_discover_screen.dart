import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:kumbh_app/l10n/app_localizations.dart';

class _MapLocation {
  final String name;
  final String category;
  final String description;
  final LatLng point;
  final IconData icon;
  final Color color;
  final String crowdLevel;

  const _MapLocation({
    required this.name,
    required this.category,
    required this.description,
    required this.point,
    required this.icon,
    required this.color,
    required this.crowdLevel,
  });
}

class MapDiscoverScreen extends ConsumerStatefulWidget {
  const MapDiscoverScreen({super.key});

  @override
  ConsumerState<MapDiscoverScreen> createState() => _MapDiscoverScreenState();
}

class _MapDiscoverScreenState extends ConsumerState<MapDiscoverScreen>
    with TickerProviderStateMixin {
  final List<String> tags = const [
    'All',
    'Ghats',
    'Temples',
    'Parking',
    'Hotels',
    'Help Centers'
  ];
  int selectedTagIndex = 0;

  final MapController _mapController = MapController();
  static const LatLng _kumbhCenter = LatLng(20.0069, 73.7925); // Ramkund Ghat

  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _gpsUnavailable = false;
  final TextEditingController _searchController = TextEditingController();
  _MapLocation? _selectedPlace;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Verified official Nashik Simhastha Kumbh landmark dataset
  final List<_MapLocation> _verifiedLocations = const [
    _MapLocation(
      name: 'Ramkund Ghat',
      category: 'Ghats',
      description:
          'Holiest bathing ghat on River Godavari where sacred Snan takes place.',
      point: LatLng(20.0069, 73.7925),
      icon: Icons.water_drop,
      color: Color(0xFFD32F2F),
      crowdLevel: 'HIGH',
    ),
    _MapLocation(
      name: 'Trimbakeshwar Temple',
      category: 'Temples',
      description:
          'Sacred Jyotirlinga temple at the origin of Godavari River in Trimbak.',
      point: LatLng(19.9318, 73.5307),
      icon: Icons.temple_hindu,
      color: Color(0xFFE65100),
      crowdLevel: 'MODERATE',
    ),
    _MapLocation(
      name: 'Kalaram Temple',
      category: 'Temples',
      description:
          'Historic black stone temple dedicated to Lord Rama in Panchavati.',
      point: LatLng(20.0078, 73.7952),
      icon: Icons.temple_hindu,
      color: Color(0xFFF57C00),
      crowdLevel: 'LOW',
    ),
    _MapLocation(
      name: 'Tapovan Ghat',
      category: 'Ghats',
      description:
          'Sacred grove and holy ghat associated with Lakshmana and River Godavari.',
      point: LatLng(20.0012, 73.8054),
      icon: Icons.water_drop,
      color: Color(0xFFC2185B),
      crowdLevel: 'MODERATE',
    ),
    _MapLocation(
      name: 'Sadhugram Outer Parking P1',
      category: 'Parking',
      description:
          'Primary high-capacity 5,000-vehicle designated parking hub with shuttles.',
      point: LatLng(19.9850, 73.7650),
      icon: Icons.local_parking,
      color: Color(0xFF1976D2),
      crowdLevel: 'LOW',
    ),
    _MapLocation(
      name: 'Nashik District Civil Hospital',
      category: 'Help Centers',
      description:
          '24x7 500-bed apex emergency hospital with dedicated trauma care.',
      point: LatLng(19.9975, 73.7898),
      icon: Icons.local_hospital,
      color: Color(0xFFD32F2F),
      crowdLevel: 'OPERATIONAL',
    ),
    _MapLocation(
      name: 'Panchavati Police Station',
      category: 'Help Centers',
      description:
          'Main law enforcement command & Kumbh Mela assistance desk (Call: 100).',
      point: LatLng(20.0055, 73.7915),
      icon: Icons.local_police,
      color: Color(0xFF00796B),
      crowdLevel: 'OPERATIONAL',
    ),
    _MapLocation(
      name: 'Central Sadhugram Emergency Desk',
      category: 'Help Centers',
      description:
          '24x7 administrative, lost person, and medical help desk (Toll-free: 1924).',
      point: LatLng(20.0020, 73.7980),
      icon: Icons.support_agent,
      color: Color(0xFF512DA8),
      crowdLevel: 'OPERATIONAL',
    ),
    _MapLocation(
      name: 'Nashik Road Railway Station',
      category: 'Transport',
      description:
          'Primary Central Railway junction for incoming pilgrim trains.',
      point: LatLng(19.9547, 73.8344),
      icon: Icons.train,
      color: Color(0xFF388E3C),
      crowdLevel: 'HIGH',
    ),
    _MapLocation(
      name: 'Hotel Saffron & Pilgrim Lodge',
      category: 'Hotels',
      description:
          'Verified pilgrim accommodation with tourist facilitation desk.',
      point: LatLng(20.0028, 73.7845),
      icon: Icons.hotel,
      color: Color(0xFF689F38),
      crowdLevel: 'MODERATE',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    _requestLocationAndShow();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<_MapLocation> get _filteredLocations {
    final selectedTag = tags[selectedTagIndex];
    if (selectedTag == 'All') return _verifiedLocations;
    return _verifiedLocations
        .where((loc) => loc.category.toLowerCase() == selectedTag.toLowerCase())
        .toList();
  }

  Future<void> _requestLocationAndShow() async {
    setState(() {
      _isLoadingLocation = true;
      _gpsUnavailable = false;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _isLoadingLocation = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _gpsUnavailable = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _gpsUnavailable = true;
        });
      }
    }
  }

  void _centerOnUser() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15.5,
      );
    } else {
      if (_gpsUnavailable && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'GPS unavailable. Please enable device location settings.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      _requestLocationAndShow();
    }
  }

  void _centerOnKumbh() {
    _mapController.move(_kumbhCenter, 14.5);
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  void _onLocationSelected(_MapLocation loc) {
    setState(() {
      _selectedPlace = loc;
    });
    _mapController.move(loc.point, 16.0);
  }

  void _showSearchResults(String query) {
    final results = query.isEmpty
        ? _verifiedLocations
        : _verifiedLocations.where((p) {
            return p.name.toLowerCase().contains(query.toLowerCase()) ||
                p.category.toLowerCase().contains(query.toLowerCase());
          }).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                query.isEmpty ? 'All Verified Locations' : 'Search results for "$query"',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No verified locations match your search.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final place = results[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: place.color.withValues(alpha: 0.15),
                          child: Icon(place.icon, color: place.color, size: 20),
                        ),
                        title: Text(
                          place.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${place.category} · Crowd: ${place.crowdLevel}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          _onLocationSelected(place);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchDirections(_MapLocation? destination) async {
    Uri uri;
    if (destination != null) {
      if (_currentPosition != null) {
        uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&destination=${destination.point.latitude},${destination.point.longitude}',
        );
      } else {
        uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${destination.point.latitude},${destination.point.longitude}',
        );
      }
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=Nashik+Kumbh+Mela+Ramkund',
      );
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch maps application')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayedLocations = _filteredLocations;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E9),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(l10n),
                const SizedBox(height: 8),
                _buildSearchBar(l10n),
                const SizedBox(height: 8),
                _buildCategoryChips(),
                const SizedBox(height: 8),
                // Real interactive map taking remaining vertical space
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: const MapOptions(
                            initialCenter: _kumbhCenter,
                            initialZoom: 14.2,
                            minZoom: 9.0,
                            maxZoom: 18.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.kumbh.mela.app',
                              maxZoom: 19,
                            ),
                            MarkerLayer(
                              markers: [
                                // 1. Verified Kumbh Landmarks
                                for (final loc in displayedLocations)
                                  Marker(
                                    point: loc.point,
                                    width: 44,
                                    height: 44,
                                    child: GestureDetector(
                                      onTap: () => _onLocationSelected(loc),
                                      child: _buildPin(loc),
                                    ),
                                  ),

                                // 2. Live GPS User Position Marker (if available)
                                if (_currentPosition != null)
                                  Marker(
                                    point: LatLng(
                                      _currentPosition!.latitude,
                                      _currentPosition!.longitude,
                                    ),
                                    width: 48,
                                    height: 48,
                                    child: AnimatedBuilder(
                                      animation: _pulseAnimation,
                                      builder: (context, child) {
                                        return Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 44 * _pulseAnimation.value,
                                              height: 44 * _pulseAnimation.value,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.blue.withValues(
                                                    alpha: 0.25),
                                              ),
                                            ),
                                            Container(
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.blue.shade700,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 3,
                                                ),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: Colors.black38,
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        // GPS loading / status overlay
                        if (_isLoadingLocation)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Getting GPS...',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Interactive Map Controls (Zoom & Location)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Column(
                            children: [
                              _buildMapButton(
                                icon: Icons.add,
                                onTap: _zoomIn,
                                tooltip: 'Zoom In',
                              ),
                              const SizedBox(height: 6),
                              _buildMapButton(
                                icon: Icons.remove,
                                onTap: _zoomOut,
                                tooltip: 'Zoom Out',
                              ),
                              const SizedBox(height: 12),
                              _buildMapButton(
                                icon: Icons.my_location,
                                onTap: _centerOnUser,
                                tooltip: 'My Location',
                                color: _currentPosition != null
                                    ? Colors.blue.shade700
                                    : Colors.black54,
                              ),
                              const SizedBox(height: 6),
                              _buildMapButton(
                                icon: Icons.center_focus_strong,
                                onTap: _centerOnKumbh,
                                tooltip: 'Center Kumbh',
                                color: const Color(0xFFFF7A00),
                              ),
                            ],
                          ),
                        ),

                        // Selected Place Bottom Detail Card
                        if (_selectedPlace != null)
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: _buildPlaceDetailCard(_selectedPlace!),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPin(_MapLocation loc) {
    final isSelected = _selectedPlace?.name == loc.name;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF7A00) : loc.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(loc.icon, color: Colors.white, size: isSelected ? 22 : 18),
        ),
      ],
    );
  }

  Widget _buildPlaceDetailCard(_MapLocation loc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: loc.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(loc.icon, color: loc.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      loc.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: loc.crowdLevel == 'HIGH'
                      ? Colors.red.shade100
                      : loc.crowdLevel == 'MODERATE'
                          ? Colors.orange.shade100
                          : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  loc.crowdLevel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: loc.crowdLevel == 'HIGH'
                        ? Colors.red.shade800
                        : loc.crowdLevel == 'MODERATE'
                            ? Colors.orange.shade800
                            : Colors.green.shade800,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _selectedPlace = null),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            loc.description,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () => _launchDirections(loc),
              icon: const Icon(Icons.directions, size: 16),
              label: const Text('Directions via Google Maps',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color color = Colors.black87,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations? l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.asset(
              'assets/images/ghat_dawn.jpg',
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.2),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.discover ?? 'Simhastha Kumbh 2027',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Nashik & Trimbakeshwar Interactive GIS Map',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations? l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onSubmitted: _showSearchResults,
                decoration: InputDecoration(
                  hintText: l10n?.searchLocation ?? 'Search verified locations...',
                  hintStyle: const TextStyle(color: Colors.black45, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                textInputAction: TextInputAction.search,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.list, color: Color(0xFFFF7A00)),
              onPressed: () => _showSearchResults(''),
              tooltip: 'Browse All',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: tags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = selectedTagIndex == index;
          return InkWell(
            onTap: () {
              setState(() {
                selectedTagIndex = index;
                _selectedPlace = null;
              });
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFF7A00)
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))
                ],
              ),
              child: Text(
                tags[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
