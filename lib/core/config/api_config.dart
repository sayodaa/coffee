


class ApiConfig {
  // Stored securely - in a real app this would be in .env or a secure vault
  // static const String _rawApiKey = 'AQ.Ab8RN6KLYttLbRPL7Zf5LL3Xh9t8a4RgM49ncubezYR41W5seA';
  // static const String _rawApiKey = 'AQ.AQ.Ab8RN6KqrtZTcZHWnz-Fc5RJeWfNFBB2iwxIYA1fCDmAcAVXTQ';
  static const String _rawApiKey = 'AQ.Ab8RN6KqrtZTcZHWnz-Fc5RJeWfNFBB2iwxIYA1fCDmAcAVXTQ';

  // Trimmed API key or access token. In production keep this in secure storage.
  static String get GeminiApiKey => _rawApiKey.trim();

  // Core base for Generative Language REST calls (no trailing slash)
  // We'll compose the full model endpoint in the service class.
  static const String GeminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta2/models';

  // Model name to use for Gemini 1.5 Flash
  static const String GeminiModel = 'gemini-1.5-flash';

  // Helper to detect whether the provided secret looks like a plain API key
  // Google API keys usually start with 'AIza'. Access tokens (OAuth) start
  // with different prefixes like 'ya29.' or 'AQ' etc.
  static bool get _looksLikeApiKey => GeminiApiKey.startsWith('AQ') || GeminiApiKey.startsWith('AIza');

  // Returns the query parameter to use when the key is an API key.
  static String get keyQueryParam => _looksLikeApiKey ? '?key=$GeminiApiKey' : '';

  // Returns an Authorization header map when the stored value looks like
  // an OAuth access token (not an API key). For API keys this returns {}.
  static Map<String, String> get authHeader {
    if (_looksLikeApiKey) return {};
    return {'Authorization': 'Bearer $GeminiApiKey'};
  }
}
