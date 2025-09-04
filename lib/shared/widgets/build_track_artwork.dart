import 'dart:io';
import 'package:flutter/material.dart';

Widget buildTrackArtwork(String? artwork, {double size = 50}) {
  Widget imageWidget;

  if (artwork != null && artwork.isNotEmpty) {
    if (artwork.startsWith('http://') || artwork.startsWith('https://')) {
      // Case 1: Remote URL
      imageWidget = Image.network(
        artwork,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackArtwork(size),
      );
    } else if (artwork.startsWith('/') || artwork.contains(':\\')) {
      // Case 2: Local file
      imageWidget = Image.file(
        File(artwork),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackArtwork(size),
      );
    } else {
      // Case 3: Asset
      imageWidget = Image.asset(
        artwork,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackArtwork(size),
      );
    }
  } else {
    // Case 4: No artwork
    imageWidget = _fallbackArtwork(size);
  }

  // Circular with border
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2), // border stroke
    ),
    child: ClipOval(
      child: SizedBox(width: size, height: size, child: imageWidget),
    ),
  );
}

Widget _fallbackArtwork(double size) {
  return Container(
    width: size,
    height: size,
    color: Colors.grey.shade800,
    child: const Icon(Icons.music_note, color: Colors.white70, size: 24),
  );
}
