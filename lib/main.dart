// ignore_for_file: deprecated_member_use

import 'package:favorite_places/screens/places.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
// import your generated firebase_options.dart if using FlutterFire CLI

import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final colorScheme = ColorScheme.fromSeed(
  brightness: Brightness.dark,
  seedColor: const Color.fromARGB(255, 102, 6, 247),
  background: const Color.fromARGB(255, 56, 49, 66),
);

final theme = ThemeData().copyWith(
  useMaterial3: true,
  scaffoldBackgroundColor: colorScheme.background,
  colorScheme: colorScheme,
  textTheme: GoogleFonts.ubuntuCondensedTextTheme().copyWith(
    titleSmall: GoogleFonts.ubuntuCondensed(
      fontWeight: FontWeight.bold,
    ),
    titleMedium: GoogleFonts.ubuntuCondensed(
      fontWeight: FontWeight.bold,
    ),
    titleLarge: GoogleFonts.ubuntuCondensed(
      fontWeight: FontWeight.bold,
    ),
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Great Places',
      theme: theme,
      home: const PlacesScreen(),
    );
  }
}

class PlacesList extends StatelessWidget {
  const PlacesList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('places').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final places = snapshot.data!.docs;
        if (places.isEmpty) {
          return const Center(child: Text('No Places added yet'));
        }
        return ListView.builder(
          itemCount: places.length,
          itemBuilder: (ctx, index) {
            final data = places[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['title'] ?? ''),
              subtitle: Text(data['location']['address'] ?? ''),
            );
          },
        );
      },
    );
  }
}

Future<void> addPlace(Map<String, dynamic> placeData) async {
  await FirebaseFirestore.instance.collection('places').add(placeData);
}

Stream<List<Map<String, dynamic>>> getPlacesStream() {
  return FirebaseFirestore.instance
      .collection('places')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
}

Widget buildAddPlaceButton() {
  return ElevatedButton(
    onPressed: () {
      addPlace({
        'title': 'My Place',
        'location': {'address': '123 Main St'},
      });
    },
    child: const Text('Add Place'),
  );
}
