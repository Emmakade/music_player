import 'package:equatable/equatable.dart';

abstract class LibraryEvent extends Equatable {
  const LibraryEvent();
  @override
  List<Object?> get props => [];
}

class CheckPermissionEvent extends LibraryEvent {}

class RequestPermissionEvent extends LibraryEvent {}

class LoadLibrary extends LibraryEvent {}
