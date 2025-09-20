import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

import 'dart:io';
import 'package:favorite_places/models/place.dart';

Future<Database> _getDatabase() async {
  final dbPath = await sql.getDatabasesPath();
  final db = await sql.openDatabase(path.join(dbPath, 'places.db'),
      onCreate: (db, version) {
    return db.execute(
        'CREATE TABLE user_places(id TEXT PRIMARY KEY,title TEXT, image TEXT, lat REAL , lng REAL, address TEXT)');
  }, version: 1);
  return db;
}

class UserPlacesNotifier extends StateNotifier<List<Place>> {
  UserPlacesNotifier() : super(const []);

  Future<void> loadPlaces() async {
    final db = await _getDatabase();
    final data = await db.query('user_places');
    final places = data.map((row) {
      if (kIsWeb) {
        final imageData = row['image'] as String;
        final imageBytes = base64Decode(imageData);
        return Place(
          id: row['id'] as String,
          title: row['title'] as String,
          image: imageBytes,
          location: PlaceLocation(
            latitude: row['lat'] as double,
            longitude: row['lng'] as double,
            address: row['address'] as String,
          ),
        );
      } else {
        return Place(
          id: row['id'] as String,
          title: row['title'] as String,
          image: File(row['image'] as String),
          location: PlaceLocation(
            latitude: row['lat'] as double,
            longitude: row['lng'] as double,
            address: row['address'] as String,
          ),
        );
      }
    }).toList();
    state = places;
  }

  void addPlace(String title, dynamic image, PlaceLocation location) async {
    final db = await _getDatabase();
    String imagePath;

    if (kIsWeb) {
      final imageBytes = image as List<int>;
      imagePath = base64Encode(imageBytes);
    } else {
      final appDir = await syspaths.getApplicationCacheDirectory();
      final filename = path.basename(image.path);
      final copiedImage = await image.copy('${appDir.path}/$filename');
      imagePath = copiedImage.path;
    }

    final newPlace = Place(
      title: title,
      image: image,
      location: location,
    );

    db.insert('user_places', {
      'id': newPlace.id,
      'title': newPlace.title,
      'image': imagePath,
      'lat': newPlace.location.latitude,
      'lng': newPlace.location.longitude,
      'address': newPlace.location.address,
    });

    state = [newPlace, ...state];
  }
}

final UserPlacesProvider =
    StateNotifierProvider<UserPlacesNotifier, List<Place>>(
  (ref) => UserPlacesNotifier(),
);
