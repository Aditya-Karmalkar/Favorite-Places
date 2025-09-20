import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

const uuid = Uuid();

class PlaceLocation {
  const PlaceLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final String address;
}

class Place {
  Place({
    required this.title,
    required this.image,
    required this.location,
    String? id,
  }) : id = id ?? uuid.v4();

  final String id;
  final String title;
  final dynamic image; // Can be File or Uint8List
  final PlaceLocation location;

  Uint8List get imageBytes {
    if (kIsWeb) {
      return image as Uint8List;
    } else {
      return File(image.path).readAsBytesSync();
    }
  }
}
