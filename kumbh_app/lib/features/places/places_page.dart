import 'package:flutter/material.dart';

class PlacesPage extends StatelessWidget {
  const PlacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Places')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Awaiting official updates from Kumbh Authorities',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
