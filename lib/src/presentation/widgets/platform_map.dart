import 'dart:io' show Platform;

import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

class PlatformMapMarker {
  const PlatformMapMarker({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class PlatformMap extends StatelessWidget {
  const PlatformMap({
    super.key,
    required this.center,
    this.markers = const <PlatformMapMarker>[],
    this.zoom = 13,
  });

  final PlatformMapMarker center;
  final List<PlatformMapMarker> markers;
  final double zoom;

  bool get _useAppleMap => !kIsWeb && Platform.isIOS;

  @override
  Widget build(BuildContext context) {
    if (_useAppleMap) {
      return _buildAppleMap();
    }
    return _buildFlutterMap(context);
  }

  Widget _buildAppleMap() {
    final annotations = <apple.Annotation>{};
    for (var i = 0; i < markers.length; i++) {
      final marker = markers[i];
      annotations.add(
        apple.Annotation(
          annotationId: apple.AnnotationId('marker_$i'),
          position: apple.LatLng(marker.latitude, marker.longitude),
        ),
      );
    }

    return apple.AppleMap(
      initialCameraPosition: apple.CameraPosition(
        target: apple.LatLng(center.latitude, center.longitude),
        zoom: zoom,
      ),
      annotations: annotations,
    );
  }

  Widget _buildFlutterMap(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: latlng.LatLng(center.latitude, center.longitude),
        initialZoom: zoom,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: markers
              .map(
                (marker) => Marker(
                  width: 40,
                  height: 40,
                  point: latlng.LatLng(marker.latitude, marker.longitude),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
