class ApiConfig {
  static const String baseUrl = "https://schoolcare-backend.vercel.app";
  static const String geoapifyApiKey = String.fromEnvironment(
    'GEOAPIFY_API_KEY',
  );

  static String staticMapUrl({
    required double latitude,
    required double longitude,
    required int width,
    required int height,
  }) {
    final queryParameters = <String, String>{
      'style': 'osm-carto',
      'width': '$width',
      'height': '$height',
      'center': 'lonlat:$longitude,$latitude',
      'zoom': '16',
      'marker': 'lonlat:$longitude,$latitude;color:%23ff0000;size:medium',
    };
    if (geoapifyApiKey.isNotEmpty) {
      queryParameters['apiKey'] = geoapifyApiKey;
    }
    return Uri.https(
      'maps.geoapify.com',
      '/v1/staticmap',
      queryParameters,
    ).toString();
  }
}