import 'package:favorite_places/models/place.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.location,
    this.isSelecting = true,
  });

  final PlaceLocation? location;
  final bool isSelecting;

  @override
  State<MapScreen> createState() {
    return _MapScreenState();
  }
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _pickedLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.location == null
        ? null
        : LatLng(widget.location!.latitude, widget.location!.longitude);
  }

  void _selectLocation(TapPosition tapPosition, LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
  }

  void _getCurrentLocation() async {
    if (kIsWeb) {
      // For web, we'll use a default location since geolocation might not work
      setState(() {
        _pickedLocation = LatLng(18.5204, 73.8567); // Default to Pune
      });
      _mapController.move(_pickedLocation!, 15.0);
      return;
    }

    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationData = await location.getLocation();
    final lng = locationData.longitude;
    final lat = locationData.latitude;

    if (lat == null || lng == null) {
      return;
    }

    setState(() {
      _pickedLocation = LatLng(lat, lng);
    });
    _mapController.move(_pickedLocation!, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelecting ? 'Pick Location' : 'Your Location'),
        actions: [
          if (widget.isSelecting)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _pickedLocation == null
                  ? null
                  : () {
                      Navigator.of(context).pop(_pickedLocation);
                    },
            ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _pickedLocation ??
              LatLng(
                widget.location?.latitude ?? 18.5204,
                widget.location?.longitude ?? 73.8567,
              ),
          initialZoom: 13.0,
          onTap: widget.isSelecting ? _selectLocation : null,
          interactionOptions: const InteractionOptions(
            enableScrollWheel: true,
            enableMultiFingerGestureRace: true,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.app',
          ),
          if (_pickedLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _pickedLocation!,
                  width: 80,
                  height: 80,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: widget.isSelecting
          ? FloatingActionButton(
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location),
            )
          : null,
    );
  }
}
