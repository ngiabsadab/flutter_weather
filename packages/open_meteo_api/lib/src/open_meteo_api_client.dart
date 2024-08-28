import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:open_meteo_api/open_meteo_api.dart';

class LocationRequestFailure implements Exception {}

class LocationNotFoundFailure implements Exception {}

class WeatherRequestFailure implements Exception {}

class WeatherNotFoundFailure implements Exception {}

class OpenMeteoApiClient {
  OpenMeteoApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  static const _baseUrlWeather = 'api.open-meteo.com';
  static const _baseUrlGeocoding = 'geocoding-api.open-meteo.com';

  final http.Client _httpClient;

  /// Finds a [Location] `/v1/search/?name=(query)`.
  Future<Location> locationSearch(String query) async {
    // 1. set endpoint URL to fetch data
    final locationRequest = Uri.https(
      _baseUrlGeocoding,
      '/v1/search',
      {'name': query, 'count': '1'},
    );

    // 2. fetch data with get method via http package.
    final locationResponse = await _httpClient.get(locationRequest);

    // 3. check error responding and handle.
    if (locationResponse.statusCode != 200) {
      throw LocationRequestFailure();
    }

    // 4. decode data response string type to raw json.
    final locationJson = jsonDecode(locationResponse.body) as Map;

    // 5. check expecting data which must have results inside.
    if (!locationJson.containsKey('results')) throw LocationNotFoundFailure();

    // 6. store result in list
    final results = locationJson['results'] as List;

    // 7. check empty final results
    if (results.isEmpty) throw LocationNotFoundFailure();

    // 8. return result in Location
    return Location.formJson(results.first as Map<String, dynamic>);
  }

  /// Fetches [Weather] for a given [latitude] and [longitude].
  Future<Weather> getWeather({required double latitude, required double longitude}) async {
    // 1. set endpoint URL to fetch data
    final weatherRequest = Uri.https(_baseUrlWeather, 'v1/forecast', {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'current_weather': 'true',
    });

    // 2. fetch data with get method via http package.
    final weatherResponse = await _httpClient.get(weatherRequest);

    // 3. check error responding and handle.
    if (weatherResponse.statusCode != 200) {
      throw WeatherRequestFailure();
    }

    // 4. decode data response string type to raw json.
    final bodyJson = jsonDecode(weatherResponse.body) as Map<String, dynamic>;

    // 6. store result in list
    if (!bodyJson.containsKey('current_weather')) {
      throw WeatherNotFoundFailure();
    }

    // 7. check empty final results
    final weatherJson = bodyJson['current_weather'] as Map<String, dynamic>;

    // 8. return result in Location
    return Weather.fromJson(weatherJson);
  }
}
