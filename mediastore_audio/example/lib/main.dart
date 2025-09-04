import 'package:flutter/material.dart';
import 'package:mediastore_audio/mediastore_audio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Mediastore Audio Plugin')),
        body: FutureBuilder<String?>(
          future: MediastoreAudio.getPlatformVersion(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(child: Text('Platform: ${snapshot.data}'));
          },
        ),
      ),
    );
  }
}
