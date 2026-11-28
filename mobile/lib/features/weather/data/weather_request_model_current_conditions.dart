class WeatherRequest {
  const WeatherRequest(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
  Map<String, dynamic> get coordinates => {
    'latitude': latitude,
    'longitude': longitude,
  };
}
