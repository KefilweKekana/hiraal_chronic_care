import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../config/env_config.dart';

/// Singleton app logger.
final log = Logger(
  level: EnvConfig.enableVerboseLogging ? Level.debug : Level.info,
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 5,
    lineLength: 80,
    colors: !kReleaseMode,
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
