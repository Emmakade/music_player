import 'package:equatable/equatable.dart';

import '../../../core/models/track.dart';

abstract class LibraryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LibraryInitial extends LibraryState {}

class LibraryLoading extends LibraryState {}

class LibraryLoaded extends LibraryState {
  final List<Track> tracks;
  LibraryLoaded({required this.tracks});

  @override
  List<Object?> get props => [tracks];
}

class LibraryError extends LibraryState {
  final String message;
  LibraryError({required this.message});

  @override
  List<Object?> get props => [message];
}

class LibraryPermissionDenied extends LibraryState {}
