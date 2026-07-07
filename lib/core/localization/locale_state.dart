part of 'locale_cubit.dart';

abstract class LocaleState {
  final Locale locale;
  const LocaleState(this.locale);
}

class ChangeLocaleState extends LocaleState {
  const ChangeLocaleState(Locale locale) : super(locale);
}
