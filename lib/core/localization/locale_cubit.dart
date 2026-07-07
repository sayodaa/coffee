import 'package:coffee_app/core/localization/language_cache_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'locale_state.dart';

class LocaleCubit extends Cubit<LocaleState> {
  final LanguageCacheHelper languageCacheHelper;

  LocaleCubit(this.languageCacheHelper)
    : super(const ChangeLocaleState(Locale('en')));

  Future<void> getSavedLanguage() async {
    final String cachedLanguageCode = await languageCacheHelper
        .getCachedLanguageCode();
    emit(ChangeLocaleState(Locale(cachedLanguageCode)));
  }

  Future<void> changeLanguage(String languageCode) async {
    await languageCacheHelper.cacheLanguageCode(languageCode);
    emit(ChangeLocaleState(Locale(languageCode)));
  }
}
