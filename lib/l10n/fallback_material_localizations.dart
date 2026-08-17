import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Flutter's built-in Material/Cupertino delegates do not include Somali (`so`).
/// Without a fallback, setting [MaterialApp.locale] to `so` fails localization
/// loading and the whole app paints a gray/error frame.
///
/// These delegates accept every locale and load English chrome (tooltips,
/// dialog buttons, etc.) when the stock delegate does not support it.
/// App copy still comes from [AppLocalizations] for `en` / `so`.

class FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    final stock = GlobalMaterialLocalizations.delegate;
    if (stock.isSupported(locale)) {
      return stock.load(locale);
    }
    return stock.load(const Locale('en'));
  }

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

class FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    final stock = GlobalCupertinoLocalizations.delegate;
    if (stock.isSupported(locale)) {
      return stock.load(locale);
    }
    return stock.load(const Locale('en'));
  }

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}
