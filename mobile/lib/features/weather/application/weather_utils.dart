import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';

class WeatherUtils {
  /// Maps WMO Weather Interpretation Codes (Open-Meteo) to accurate weather icons.
  /// Ref: https://open-meteo.com/en/docs#weathervariables
  static IconData getWeatherIcon(int code, {bool isDay = true}) {
    // 0: Clear sky
    if (code == 0) {
      return isDay ? PhosphorIcons.sun : PhosphorIcons.moon;
    }
    // 1: Mainly clear
    if (code == 1) {
      return isDay ? PhosphorIcons.sun : PhosphorIcons.moon;
    }
    // 2: Partly cloudy
    if (code == 2) {
      return isDay ? PhosphorIcons.cloudSun : PhosphorIcons.cloud;
    }
    // 3: Overcast
    if (code == 3) {
      return PhosphorIcons.cloud;
    }
    // 45, 48: Fog and depositing rime fog
    if (code >= 45 && code <= 48) {
      return PhosphorIcons.cloudFog;
    }
    // 56, 57, 66, 67, 71..77, 85..86: Snow, Freezing Rain, Sleet, Ice
    if ((code >= 56 && code <= 57) ||
        (code >= 66 && code <= 67) ||
        (code >= 71 && code <= 77) ||
        (code >= 85 && code <= 86)) {
      return PhosphorIcons.cloudSnow;
    }
    // 51..55: Drizzle
    if (code >= 51 && code <= 55) {
      return PhosphorIcons.cloudRain;
    }
    // 61..65, 80..82: Rain / Showers
    if ((code >= 61 && code <= 65) || (code >= 80 && code <= 82)) {
      return PhosphorIcons.cloudRain;
    }
    // 95..99: Thunderstorm with/without hail
    if (code >= 95 && code <= 99) {
      return PhosphorIcons.cloudLightning;
    }
    return PhosphorIcons.cloud;
  }

  /// Returns contextual theme color based on weather conditions.
  static Color getWeatherColor(int code, AppColors colors, {bool isDay = true}) {
    // Clear / Sunny
    if (code == 0 || code == 1) {
      return isDay ? colors.warning : colors.accent;
    }
    // Partly Cloudy
    if (code == 2) {
      return isDay ? colors.warning : colors.textSecondary;
    }
    // Overcast / Fog
    if (code == 3 || (code >= 45 && code <= 48)) {
      return colors.textSecondary;
    }
    // Snow / Sleet
    if ((code >= 56 && code <= 57) ||
        (code >= 66 && code <= 67) ||
        (code >= 71 && code <= 77) ||
        (code >= 85 && code <= 86)) {
      return colors.textPrimary;
    }
    // Rain / Drizzle / Showers
    if ((code >= 51 && code <= 55) ||
        (code >= 61 && code <= 65) ||
        (code >= 80 && code <= 82)) {
      return colors.accent;
    }
    // Thunderstorm
    if (code >= 95) {
      return colors.warning;
    }
    return colors.accent;
  }

  /// Human-readable description of WMO weather code.
  static String getWeatherDescription(int code) {
    if (code == 0) return 'Clear Sky';
    if (code == 1) return 'Mainly Clear';
    if (code == 2) return 'Partly Cloudy';
    if (code == 3) return 'Overcast';
    if (code == 45) return 'Fog';
    if (code == 48) return 'Rime Fog';
    if (code == 51) return 'Light Drizzle';
    if (code == 53) return 'Moderate Drizzle';
    if (code == 55) return 'Dense Drizzle';
    if (code == 56 || code == 57) return 'Freezing Drizzle';
    if (code == 61) return 'Slight Rain';
    if (code == 63) return 'Moderate Rain';
    if (code == 65) return 'Heavy Rain';
    if (code == 66 || code == 67) return 'Freezing Rain';
    if (code == 71) return 'Slight Snow';
    if (code == 73) return 'Moderate Snow';
    if (code == 75) return 'Heavy Snow';
    if (code == 77) return 'Snow Grains';
    if (code == 80) return 'Slight Showers';
    if (code == 81) return 'Moderate Showers';
    if (code == 82) return 'Heavy Showers';
    if (code == 85 || code == 86) return 'Snow Showers';
    if (code == 95) return 'Thunderstorm';
    if (code == 96 || code == 99) return 'Thunderstorm with Hail';
    return 'Cloudy';
  }
}
