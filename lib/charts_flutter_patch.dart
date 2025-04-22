import 'package:flutter/material.dart';

// Patch for hashValues
extension HashValuesExtension on Object {
  int hashValues(Object? o1, [Object? o2, Object? o3, Object? o4, Object? o5, Object? o6, Object? o7]) {
    return Object.hash(o1, o2, o3, o4, o5, o6, o7);
  }
}

// Patch for TextTheme
extension TextThemeExtension on TextTheme {
  TextStyle? get bodyText2 => bodyMedium;
}