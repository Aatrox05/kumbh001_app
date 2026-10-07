import 'package:flutter/material.dart';
import 'package:kumbh_app/features/map/presentation/map_discover_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (_) => const MapDiscoverScreen(),
          );
        },
      ),
    );
  }
}

// Navigation to nearby is triggered from MapDiscoverScreen when user selects "Hotels" tag.
