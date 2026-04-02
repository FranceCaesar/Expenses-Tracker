import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class CurrencyService {
  static const String _currencyKey = 'selected_currency';
  static const String _defaultCurrency = 'PHP';

  // Dynamic currency database fetched from API
  static Map<String, Map<String, String>> _currencyDatabase = {};
  static Future<Map<String, Map<String, String>>>? _currencyFuture;

  /// Initialize currency data from API (call this at app startup)
  static Future<void> initializeCurrencyData() async {
    try {
      _currencyDatabase = await ApiService.getCurrencyMetadata();
    } catch (e) {
      // If initialization fails, fetch will be attempted later during usage
      // Silently fail to avoid blocking app startup
    }
  }

  /// Get currency data with lazy loading from API
  static Future<Map<String, Map<String, String>>> _getCurrencyDatabase() async {
    if (_currencyDatabase.isNotEmpty) {
      return _currencyDatabase;
    }

    // Use singleton pattern to avoid multiple API calls
    _currencyFuture ??= ApiService.getCurrencyMetadata();

    try {
      _currencyDatabase = await _currencyFuture!;
      return _currencyDatabase;
    } catch (e) {
      throw Exception('Failed to load currency data: $e');
    }
  }

  static Future<String> getSelectedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? _defaultCurrency;
  }

  static Future<void> setSelectedCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency);
  }

  static Future<bool> isCurrencySet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_currencyKey);
  }

  /// Get list of all supported currencies from API
  static Future<List<String>> getPopularCurrencies() async {
    try {
      final db = await _getCurrencyDatabase();
      return db.keys.toList()..sort();
    } catch (e) {
      throw Exception('Failed to get currency list: $e');
    }
  }

  /// Get currency information (name, country, symbol) from API
  static Future<Map<String, String>> getCurrencyInfo(String currencyCode) async {
    try {
      final db = await _getCurrencyDatabase();
      final code = currencyCode.toUpperCase();
      return db[code] ?? {
        'name': code,
        'country': 'Unknown',
        'symbol': code,
      };
    } catch (e) {
      throw Exception('Failed to get currency info: $e');
    }
  }

  /// Get currency symbol from API
  static Future<String> getCurrencySymbol(String currencyCode) async {
    try {
      final db = await _getCurrencyDatabase();
      final code = currencyCode.toUpperCase();
      return db[code]?['symbol'] ?? currencyCode;
    } catch (e) {
      throw Exception('Failed to get currency symbol: $e');
    }
  }

  /// Get currency name from API
  static Future<String> getCurrencyName(String currencyCode) async {
    try {
      final db = await _getCurrencyDatabase();
      final code = currencyCode.toUpperCase();
      return db[code]?['name'] ?? currencyCode;
    } catch (e) {
      throw Exception('Failed to get currency name: $e');
    }
  }

  /// Get currency country from API
  static Future<String> getCurrencyCountry(String currencyCode) async {
    try {
      final db = await _getCurrencyDatabase();
      final code = currencyCode.toUpperCase();
      return db[code]?['country'] ?? 'Unknown';
    } catch (e) {
      throw Exception('Failed to get currency country: $e');
    }
  }

  /// Get all countries mapped to currencies from API
  static Future<Map<String, String>> getCurrencyCountries() async {
    try {
      final db = await _getCurrencyDatabase();
      final Map<String, String> countries = {};
      db.forEach((code, data) {
        countries[code] = data['country']!;
      });
      return countries;
    } catch (e) {
      throw Exception('Failed to get currency countries: $e');
    }
  }

  /// Search currencies by name or country from API
  static Future<List<String>> searchCurrencies(String query) async {
    try {
      final db = await _getCurrencyDatabase();
      final lowerQuery = query.toLowerCase();
      return db.entries
          .where((entry) =>
              entry.key.toLowerCase().contains(lowerQuery) ||
              entry.value['name']!.toLowerCase().contains(lowerQuery) ||
              entry.value['country']!.toLowerCase().contains(lowerQuery))
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      throw Exception('Failed to search currencies: $e');
    }
  }

  /// Clear currency cache
  static Future<void> clearCache() async {
    _currencyDatabase.clear();
    _currencyFuture = null;
  }
}


