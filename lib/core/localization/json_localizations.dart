import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class JsonLocalizations {
  final Locale locale;
  final Map<String, String> _strings;

  const JsonLocalizations._(this.locale, this._strings);

  static JsonLocalizations? of(BuildContext context) {
    return Localizations.of<JsonLocalizations>(context, JsonLocalizations);
  }

  static const LocalizationsDelegate<JsonLocalizations> delegate =
      _JsonLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  String tr(String key) {
    final value = _strings[key];
    if (value != null) return value;

    // Fallback: return the key name instead of crashing
    // This ensures the app never crashes due to missing translations
    debugPrint('[i18n WARNING] Missing translation key "$key" for locale ${locale.languageCode}');
    return key;
  }

  static Future<JsonLocalizations> load(Locale locale) async {
    final lang = locale.languageCode;
    final path = 'assets/l10n/$lang.json';
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw);

    if (decoded is! Map<String, dynamic>) {
      throw FlutterError('Invalid localization JSON at $path');
    }

    final strings = decoded.map((k, v) => MapEntry(k, v.toString()));
    return JsonLocalizations._(locale, strings);
  }
}

class _JsonLocalizationsDelegate extends LocalizationsDelegate<JsonLocalizations> {
  const _JsonLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ar'].contains(locale.languageCode);

  @override
  Future<JsonLocalizations> load(Locale locale) => JsonLocalizations.load(locale);

  @override
  bool shouldReload(_JsonLocalizationsDelegate old) => false;
}

extension JsonLocalizationX on BuildContext {
  String tr(String key) => JsonLocalizations.of(this)!.tr(key);
}
