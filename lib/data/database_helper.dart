import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:favorite_places/models/place.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'places.db');
    print('Database path: $path');

    // Delete existing database for testing
    // await deleteDatabase(path);
    // print('Deleted existing database');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        print('Creating database...');
        await db.execute('''
          CREATE TABLE places(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            image TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            address TEXT NOT NULL
          )
        ''');
        print('Database created successfully');
      },
      onOpen: (db) async {
        print('Database opened');
        // Verify table exists
        final tables = await db.query('sqlite_master',
            where: 'type = ? AND name = ?', whereArgs: ['table', 'places']);
        print('Tables in database: ${tables.length}');
        if (tables.isEmpty) {
          print('Places table not found, creating it...');
          await db.execute('''
            CREATE TABLE places(
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              image TEXT NOT NULL,
              latitude REAL NOT NULL,
              longitude REAL NOT NULL,
              address TEXT NOT NULL
            )
          ''');
          print('Places table created');
        }
      },
    );
  }

  Future<void> insertPlace(Place place) async {
    print('Inserting place: ${place.title}');
    final db = await database;
    try {
      await db.insert(
        'places',
        {
          'id': place.id,
          'title': place.title,
          'image': place.image is String ? place.image : place.image.path,
          'latitude': place.location.latitude,
          'longitude': place.location.longitude,
          'address': place.location.address,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Place inserted successfully');

      // Verify insertion
      final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM places'));
      print('Total places in database: $count');
    } catch (e) {
      print('Error inserting place: $e');
      rethrow;
    }
  }

  Future<List<Place>> getPlaces() async {
    print('Getting places from database...');
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('places');
      print('Found ${maps.length} places in database');
      print('Raw data: $maps');

      return List.generate(maps.length, (i) {
        print('Creating Place object for: ${maps[i]['title']}');
        return Place(
          id: maps[i]['id'],
          title: maps[i]['title'],
          image: maps[i]['image'],
          location: PlaceLocation(
            latitude: maps[i]['latitude'],
            longitude: maps[i]['longitude'],
            address: maps[i]['address'],
          ),
        );
      });
    } catch (e) {
      print('Error getting places: $e');
      return [];
    }
  }

  Future<void> deletePlace(String id) async {
    print('Deleting place with id: $id');
    final db = await database;
    await db.delete(
      'places',
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Place deleted successfully');
  }
}
