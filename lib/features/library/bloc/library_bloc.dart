import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mediastore_audio/mediastore_audio.dart';
import '../../../core/models/track.dart';
import 'library_event.dart';
import 'library_state.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final MediastoreAudio _mediastoreAudio;
  final Box<Track> _trackBox;

  LibraryBloc(this._mediastoreAudio, this._trackBox) : super(LibraryInitial()) {
    on<LoadLibrary>(_onLoadLibrary);
    on<CheckPermissionEvent>(_onCheckPermission);
    on<RequestPermissionEvent>(_onRequestPermission);
  }

  Box<Track> get trackBox => _trackBox;

  Future<void> _onCheckPermission(
    CheckPermissionEvent event,
    Emitter<LibraryState> emit,
  ) async {
    final storage = await Permission.storage.status;
    final audio = await Permission.audio.status;

    if (storage.isGranted || audio.isGranted) {
      add(LoadLibrary());
    } else {
      emit(LibraryPermissionDenied());
    }
  }

  Future<void> _onRequestPermission(
    RequestPermissionEvent event,
    Emitter<LibraryState> emit,
  ) async {
    final storage = await Permission.storage.status;
    final audio = await Permission.audio.status;
    if (storage.isGranted || audio.isGranted) {
      add(LoadLibrary());
    } else {
      emit(LibraryPermissionDenied());
    }
  }

  Future<void> _onLoadLibrary(
    LoadLibrary event,
    Emitter<LibraryState> emit,
  ) async {
    emit(LibraryLoading());

    try {
      final audios = await _mediastoreAudio.getAudios();
      final tracks = audios.map((dynamic a) {
        final Map<Object?, Object?> originalMap = a as Map<Object?, Object?>;
        final stringMap = <String, dynamic>{};
        originalMap.forEach((key, value) {
          stringMap[key.toString()] = value;
        });
        return Track.fromMap(stringMap);
      }).toList();

      // Persist by ID to keep queue restoration reliable
      await _trackBox.clear();
      for (final track in tracks) {
        await _trackBox.put(track.id, track);
      }

      emit(LibraryLoaded(tracks: tracks));
    } catch (e, trace) {
      emit(LibraryError(message: "Failed to load library: $e \n$trace"));
    }
  }
}
