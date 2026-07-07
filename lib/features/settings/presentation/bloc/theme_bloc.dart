import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ThemeEvent {}

class ToggleThemeEvent extends ThemeEvent {}

class ThemeState {
  final ThemeMode themeMode;
  ThemeState(this.themeMode);
}

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeState(ThemeMode.system)) {
    on<ToggleThemeEvent>((event, emit) {
      if (state.themeMode == ThemeMode.light) {
        emit(ThemeState(ThemeMode.dark));
      } else if (state.themeMode == ThemeMode.dark) {
        emit(ThemeState(ThemeMode.light));
      } else {
        emit(ThemeState(ThemeMode.light)); // Default to light if system
      }
    });
  }
}
