import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/data/database_helper.dart';

class PlacesNotifier extends StateNotifier<List<Place>> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  PlacesNotifier() : super([]) {
    print('PlacesNotifier initialized');
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    print('Loading places...');
    final places = await _dbHelper.getPlaces();
    print('Loaded ${places.length} places');
    state = places;
  }

  Future<void> addPlace(Place place) async {
    print('Adding new place: ${place.title}');
    await _dbHelper.insertPlace(place);
    state = [...state, place];
    print('State updated with new place. Total places: ${state.length}');
  }

  Future<void> deletePlace(String id) async {
    print('Deleting place with id: $id');
    await _dbHelper.deletePlace(id);
    state = state.where((place) => place.id != id).toList();
    print('State updated after deletion. Remaining places: ${state.length}');
  }
}

final placesProvider =
    StateNotifierProvider<PlacesNotifier, List<Place>>((ref) {
  print('Creating PlacesNotifier provider');
  return PlacesNotifier();
});
