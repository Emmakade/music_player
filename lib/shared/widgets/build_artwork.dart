import 'dart:io';
import 'package:flutter/material.dart';

Widget buildArtwork(
  String? artwork, {
  double size = 110,
  bool isCircular = true,
  double borderRadius = 12,
}) {
  Widget imageWidget;

  if (artwork != null && artwork.isNotEmpty) {
    if (artwork.startsWith('http://') || artwork.startsWith('https://')) {
      imageWidget = Image.network(
        artwork,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackArtwork(size),
      );
    } else if (artwork.startsWith('/') || artwork.contains(':\\')) {
      imageWidget = Image.file(
        File(artwork),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackArtwork(size),
      );
    } else {
      imageWidget = Image.asset(
        artwork,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackArtwork(size),
      );
    }
  } else {
    imageWidget = _fallbackArtwork(size);
  }

  return isCircular
      ? ClipOval(
          child: SizedBox(width: size, height: size, child: imageWidget),
        )
      : ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox(width: size, height: size, child: imageWidget),
        );
}

Widget _fallbackArtwork(double size) {
  return Container(
    width: size,
    height: size,
    color: Colors.grey.shade800,
    child: const Icon(Icons.album, size: 90, color: Colors.white70),
  );
}
