import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String _baseUrl = 'https://v6.exchangerate-api.com/v6/3eb7599b469dc7556ee3c58f/latest';
  static const String _restCountriesUrl = 'https://restcountries.com/v3.1/all';
  
  // Cache for rates and currency metadata
  static final Map<String, dynamic> _ratesCache = {};
  static Map<String, Map<String, String>> _currencyCache = {};
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(hours: 1);

  /// Debug logging helper
  static void _log(String message) {
    if (kDebugMode) {
      print('[ApiService] $message');
    }
  }

  /// Check if internet connection is available
  static Future<bool> checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get network error message
  static String _getNetworkErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'No internet connection. Please check your network.';
    } else if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    } else if (error.toString().contains('Connection refused')) {
      return 'Cannot connect to API server.';
    } else if (error.toString().contains('Failed host')) {
      return 'Network error. Check your connection.';
    }
    return 'Network error occurred.';
  }

  /// Get cached exchange rates for a currency
  static Future<Map<String, double>> getExchangeRates(String baseCurrency) async {
    try {
      _log('Fetching exchange rates for: $baseCurrency');
      
      // Check internet connection first
      final hasConnection = await checkConnection();
      _log('Internet connection available: $hasConnection');
      if (!hasConnection) {
        throw SocketException('No internet connection');
      }

      final url = '$_baseUrl/$baseCurrency';
      _log('Calling API: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'ExpenseVault/1.0',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('API request timeout'),
      );

      _log('Response status: ${response.statusCode}');
      _log('Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _log('Response decoded successfully');
        _log('Response keys: ${data.keys.toList()}');
        
        // V6 API returns rates in 'conversion_rates' field
        if (data['conversion_rates'] == null) {
          _log('ERROR: Missing conversion_rates in response');
          throw Exception('Invalid API response: missing conversion_rates');
        }

        final rates = <String, double>{};
        (data['conversion_rates'] as Map).forEach((key, value) {
          rates[key] = (value as num).toDouble();
        });

        _log('Successfully parsed ${rates.length} exchange rates');

        // Cache the rates
        _ratesCache[baseCurrency] = rates;
        _lastFetchTime = DateTime.now();

        return rates;
      } else if (response.statusCode == 400) {
        _log('ERROR: Bad request - Invalid currency code');
        throw Exception('Invalid currency code: $baseCurrency');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _log('ERROR: API authentication failed');
        throw Exception('API authentication failed. Check API key.');
      } else if (response.statusCode == 429) {
        _log('ERROR: Rate limit exceeded');
        throw Exception('API rate limit exceeded. Please try again later.');
      } else if (response.statusCode >= 500) {
        _log('ERROR: API server error (${response.statusCode})');
        throw Exception('API server error. Try again later.');
      } else {
        _log('ERROR: Unexpected status code ${response.statusCode}');
        throw Exception('Failed to fetch exchange rates: HTTP ${response.statusCode}');
      }
    } on SocketException catch (e) {
      final message = _getNetworkErrorMessage(e);
      _log('SocketException: $message');
      throw Exception(message);
    } on TimeoutException catch (e) {
      final message = _getNetworkErrorMessage(e);
      _log('TimeoutException: $message');
      throw Exception(message);
    } on Exception catch (e) {
      _log('Exception: ${e.toString()}');
      throw Exception(e.toString());
    }
  }

  /// Get detailed exchange rate information
  static Future<Map<String, dynamic>> getExchangeRateDetail(String baseCurrency) async {
    try {
      final hasConnection = await checkConnection();
      if (!hasConnection) {
        throw SocketException('No internet connection');
      }

      final url = '$_baseUrl/$baseCurrency';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'ExpenseVault/1.0',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('API request timeout'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 400) {
        throw Exception('Invalid currency code: $baseCurrency');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('API authentication failed');
      } else if (response.statusCode == 429) {
        throw Exception('API rate limit exceeded');
      } else {
        throw Exception('Failed to fetch details: HTTP ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw Exception(_getNetworkErrorMessage(e));
    } on TimeoutException catch (e) {
      throw Exception(_getNetworkErrorMessage(e));
    } on Exception catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Fetch currency metadata from REST Countries API
  static Future<Map<String, Map<String, String>>> getCurrencyMetadata() async {
    // Return cached data if still valid
    if (_currencyCache.isNotEmpty && _lastFetchTime != null) {
      if (DateTime.now().difference(_lastFetchTime!).inHours < 24) {
        _log('Returning cached currency metadata');
        return _currencyCache;
      }
    }

    try {
      _log('Fetching currency metadata from REST Countries API');
      final hasConnection = await checkConnection();
      _log('Internet connection available: $hasConnection');
      if (!hasConnection) {
        throw SocketException('No internet connection');
      }

      _log('Calling REST Countries API: $_restCountriesUrl');
      final response = await http.get(
        Uri.parse(_restCountriesUrl),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'ExpenseVault/1.0',
        },
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('API request timeout'),
      );

      _log('REST Countries response status: ${response.statusCode}');
      _log('Response body length: ${response.body.length}');
      
      // Log response body for debugging
      if (response.statusCode != 200) {
        _log('Error response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      }

      if (response.statusCode == 200) {
        final List<dynamic> countries = jsonDecode(response.body);
        _log('Successfully decoded ${countries.length} countries');
        final Map<String, Map<String, String>> currencyData = {};

        for (var country in countries) {
          try {
            final countryName = country['name']?['common'] ?? 'Unknown';
            final currencies = country['currencies'] as Map?;

            if (currencies != null) {
              currencies.forEach((currencyCode, currencyInfo) {
                final name = currencyInfo['name'] ?? currencyCode;
                final symbol = currencyInfo['symbol'] ?? currencyCode;

                currencyData[currencyCode.toString().toUpperCase()] = {
                  'name': name.toString(),
                  'country': countryName.toString(),
                  'symbol': symbol.toString(),
                };
              });
            }
          } catch (e) {
            // Skip malformed entries
            continue;
          }
        }

        if (currencyData.isEmpty) {
          _log('ERROR: No currency data received from API');
          throw Exception('No currency data received');
        }

        _log('Successfully parsed ${currencyData.length} currencies');

        // Cache the metadata
        _currencyCache = currencyData;
        _lastFetchTime = DateTime.now();

        return currencyData;
      } else {
        _log('ERROR: Failed to fetch currency data - HTTP ${response.statusCode}');
        _log('Falling back to default currency data');
        // Use fallback data instead of throwing
        final fallbackData = _getFallbackCurrencies();
        _currencyCache = fallbackData;
        _lastFetchTime = DateTime.now();
        return fallbackData;
      }
    } on SocketException catch (e) {
      final message = _getNetworkErrorMessage(e);
      _log('SocketException in getCurrencyMetadata: $message');
      _log('Falling back to default currency data');
      // Use fallback data instead of throwing
      final fallbackData = _getFallbackCurrencies();
      _currencyCache = fallbackData;
      _lastFetchTime = DateTime.now();
      return fallbackData;
    } on TimeoutException catch (e) {
      final message = _getNetworkErrorMessage(e);
      _log('TimeoutException in getCurrencyMetadata: $message');
      _log('Falling back to default currency data');
      // Use fallback data instead of throwing
      final fallbackData = _getFallbackCurrencies();
      _currencyCache = fallbackData;
      _lastFetchTime = DateTime.now();
      return fallbackData;
    } on Exception catch (e) {
      _log('Exception in getCurrencyMetadata: ${e.toString()}');
      _log('Falling back to default currency data');
      // Use fallback data instead of throwing
      final fallbackData = _getFallbackCurrencies();
      _currencyCache = fallbackData;
      _lastFetchTime = DateTime.now();
      return fallbackData;
    }
  }

  /// Get a fallback map of currencies with basic data
  static Map<String, Map<String, String>> _getFallbackCurrencies() {
    _log('Using fallback currency data');
    return {
      'AED': {'name': 'UAE Dirham', 'country': 'United Arab Emirates', 'symbol': 'د.إ'},
      'AFN': {'name': 'Afghan Afghani', 'country': 'Afghanistan', 'symbol': '؋'},
      'ALL': {'name': 'Albanian Lek', 'country': 'Albania', 'symbol': 'L'},
      'AMD': {'name': 'Armenian Dram', 'country': 'Armenia', 'symbol': '֏'},
      'ANG': {'name': 'Neth. Antillean Guilder', 'country': 'Netherlands Antilles', 'symbol': 'ƒ'},
      'AOA': {'name': 'Angolan Kwanza', 'country': 'Angola', 'symbol': 'Kz'},
      'ARS': {'name': 'Argentine Peso', 'country': 'Argentina', 'symbol': '\$'},
      'AUD': {'name': 'Australian Dollar', 'country': 'Australia', 'symbol': 'A\$'},
      'AWG': {'name': 'Aruban Florin', 'country': 'Aruba', 'symbol': 'ƒ'},
      'AZN': {'name': 'Azerbaijani Manat', 'country': 'Azerbaijan', 'symbol': '₼'},
      'BAM': {'name': 'Bosnia-Herzegovina Mark', 'country': 'Bosnia and Herzegovina', 'symbol': 'KM'},
      'BBD': {'name': 'Barbados Dollar', 'country': 'Barbados', 'symbol': '\$'},
      'BDT': {'name': 'Bangladeshi Taka', 'country': 'Bangladesh', 'symbol': '৳'},
      'BGN': {'name': 'Bulgarian Lev', 'country': 'Bulgaria', 'symbol': 'лв'},
      'BHD': {'name': 'Bahraini Dinar', 'country': 'Bahrain', 'symbol': '.د.ب'},
      'BIF': {'name': 'Burundian Franc', 'country': 'Burundi', 'symbol': 'FBu'},
      'BMD': {'name': 'Bermudian Dollar', 'country': 'Bermuda', 'symbol': '\$'},
      'BND': {'name': 'Brunei Dollar', 'country': 'Brunei', 'symbol': '\$'},
      'BOB': {'name': 'Boliviano', 'country': 'Bolivia', 'symbol': 'Bs.'},
      'BRL': {'name': 'Brazilian Real', 'country': 'Brazil', 'symbol': 'R\$'},
      'BSD': {'name': 'Bahamian Dollar', 'country': 'Bahamas', 'symbol': '\$'},
      'BTN': {'name': 'Bhutanese Ngultrum', 'country': 'Bhutan', 'symbol': 'Nu.'},
      'BWP': {'name': 'Botswana Pula', 'country': 'Botswana', 'symbol': 'P'},
      'BZD': {'name': 'Belize Dollar', 'country': 'Belize', 'symbol': 'BZ\$'},
      'CAD': {'name': 'Canadian Dollar', 'country': 'Canada', 'symbol': 'C\$'},
      'CDF': {'name': 'Congolese Franc', 'country': 'Democratic Republic of the Congo', 'symbol': 'FC'},
      'CHE': {'name': 'Swiss Franc (convertible)', 'country': 'Switzerland', 'symbol': 'CHF'},
      'CHF': {'name': 'Swiss Franc', 'country': 'Switzerland', 'symbol': 'CHF'},
      'CHW': {'name': 'Swiss Franc (for bonds)', 'country': 'Switzerland', 'symbol': 'CHF'},
      'CLF': {'name': 'Chilean Unit of Account', 'country': 'Chile', 'symbol': 'UF'},
      'CLP': {'name': 'Chilean Peso', 'country': 'Chile', 'symbol': '\$'},
      'CNY': {'name': 'Chinese Yuan', 'country': 'China', 'symbol': '¥'},
      'COP': {'name': 'Colombian Peso', 'country': 'Colombia', 'symbol': '\$'},
      'COU': {'name': 'Colombian Real Value Unit', 'country': 'Colombia', 'symbol': '\$'},
      'CRC': {'name': 'Costa Rican Colón', 'country': 'Costa Rica', 'symbol': '₡'},
      'CUC': {'name': 'Cuban Convertible Peso', 'country': 'Cuba', 'symbol': '\$'},
      'CUP': {'name': 'Cuban Peso', 'country': 'Cuba', 'symbol': '₱'},
      'CVE': {'name': 'Cape Verdean Escudo', 'country': 'Cape Verde', 'symbol': '\$'},
      'CZK': {'name': 'Czech Koruna', 'country': 'Czech Republic', 'symbol': 'Kč'},
      'DJF': {'name': 'Djiboutian Franc', 'country': 'Djibouti', 'symbol': 'Fdj'},
      'DKK': {'name': 'Danish Krone', 'country': 'Denmark', 'symbol': 'kr'},
      'DOP': {'name': 'Dominican Peso', 'country': 'Dominican Republic', 'symbol': 'RD\$'},
      'DZD': {'name': 'Algerian Dinar', 'country': 'Algeria', 'symbol': 'دج'},
      'EGP': {'name': 'Egyptian Pound', 'country': 'Egypt', 'symbol': '£'},
      'ERN': {'name': 'Eritrean Nakfa', 'country': 'Eritrea', 'symbol': 'Nfk'},
      'ETB': {'name': 'Ethiopian Birr', 'country': 'Ethiopia', 'symbol': 'Br'},
      'EUR': {'name': 'Euro', 'country': 'European Union', 'symbol': '€'},
      'FJD': {'name': 'Fiji Dollar', 'country': 'Fiji', 'symbol': 'FJ\$'},
      'FKP': {'name': 'Falkland Pound', 'country': 'Falkland Islands', 'symbol': '£'},
      'GBP': {'name': 'British Pound', 'country': 'United Kingdom', 'symbol': '£'},
      'GEL': {'name': 'Georgian Lari', 'country': 'Georgia', 'symbol': '₾'},
      'GHS': {'name': 'Ghanaian Cedi', 'country': 'Ghana', 'symbol': '₵'},
      'GIP': {'name': 'Gibraltar Pound', 'country': 'Gibraltar', 'symbol': '£'},
      'GMD': {'name': 'Gambian Dalasi', 'country': 'Gambia', 'symbol': 'D'},
      'GNF': {'name': 'Guinean Franc', 'country': 'Guinea', 'symbol': 'FG'},
      'GTQ': {'name': 'Guatemalan Quetzal', 'country': 'Guatemala', 'symbol': 'Q'},
      'GYD': {'name': 'Guyanese Dollar', 'country': 'Guyana', 'symbol': '\$'},
      'HKD': {'name': 'Hong Kong Dollar', 'country': 'Hong Kong', 'symbol': 'HK\$'},
      'HNL': {'name': 'Honduran Lempira', 'country': 'Honduras', 'symbol': 'L'},
      'HRK': {'name': 'Croatian Kuna', 'country': 'Croatia', 'symbol': 'kn'},
      'HTG': {'name': 'Haitian Gourde', 'country': 'Haiti', 'symbol': 'G'},
      'HUF': {'name': 'Hungarian Forint', 'country': 'Hungary', 'symbol': 'Ft'},
      'IDR': {'name': 'Indonesian Rupiah', 'country': 'Indonesia', 'symbol': 'Rp'},
      'ILS': {'name': 'Israeli New Shekel', 'country': 'Israel', 'symbol': '₪'},
      'INR': {'name': 'Indian Rupee', 'country': 'India', 'symbol': '₹'},
      'IQD': {'name': 'Iraqi Dinar', 'country': 'Iraq', 'symbol': 'ع.د'},
      'IRR': {'name': 'Iranian Rial', 'country': 'Iran', 'symbol': '﷼'},
      'ISK': {'name': 'Icelandic Króna', 'country': 'Iceland', 'symbol': 'kr'},
      'JMD': {'name': 'Jamaican Dollar', 'country': 'Jamaica', 'symbol': 'J\$'},
      'JOD': {'name': 'Jordanian Dinar', 'country': 'Jordan', 'symbol': 'د.ا'},
      'JPY': {'name': 'Japanese Yen', 'country': 'Japan', 'symbol': '¥'},
      'KES': {'name': 'Kenyan Shilling', 'country': 'Kenya', 'symbol': 'KSh'},
      'KGS': {'name': 'Kyrgyzstani Som', 'country': 'Kyrgyzstan', 'symbol': 'лв'},
      'KHR': {'name': 'Cambodian Riel', 'country': 'Cambodia', 'symbol': '៛'},
      'KMF': {'name': 'Comorian Franc', 'country': 'Comoros', 'symbol': 'CF'},
      'KPW': {'name': 'North Korean Won', 'country': 'North Korea', 'symbol': '₩'},
      'KRW': {'name': 'South Korean Won', 'country': 'South Korea', 'symbol': '₩'},
      'KWD': {'name': 'Kuwaiti Dinar', 'country': 'Kuwait', 'symbol': 'د.ك'},
      'KYD': {'name': 'Cayman Islands Dollar', 'country': 'Cayman Islands', 'symbol': '\$'},
      'KZT': {'name': 'Kazakhstani Tenge', 'country': 'Kazakhstan', 'symbol': '₸'},
      'LAK': {'name': 'Laotian Kip', 'country': 'Laos', 'symbol': '₭'},
      'LBP': {'name': 'Lebanese Pound', 'country': 'Lebanon', 'symbol': '£'},
      'LKR': {'name': 'Sri Lankan Rupee', 'country': 'Sri Lanka', 'symbol': 'Rs'},
      'LRD': {'name': 'Liberian Dollar', 'country': 'Liberia', 'symbol': '\$'},
      'LSL': {'name': 'Lesotho Loti', 'country': 'Lesotho', 'symbol': 'L'},
      'LYD': {'name': 'Libyan Dinar', 'country': 'Libya', 'symbol': 'ل.د'},
      'MAD': {'name': 'Moroccan Dirham', 'country': 'Morocco', 'symbol': 'د.م.'},
      'MDL': {'name': 'Moldovan Leu', 'country': 'Moldova', 'symbol': 'L'},
      'MGA': {'name': 'Malagasy Ariary', 'country': 'Madagascar', 'symbol': 'Ar'},
      'MKD': {'name': 'Macedonian Denar', 'country': 'North Macedonia', 'symbol': 'ден'},
      'MMK': {'name': 'Myanmar Kyat', 'country': 'Myanmar', 'symbol': 'K'},
      'MNT': {'name': 'Mongolian Tugrik', 'country': 'Mongolia', 'symbol': '₮'},
      'MOP': {'name': 'Macanese Pataca', 'country': 'Macao', 'symbol': 'P'},
      'MRU': {'name': 'Mauritanian Ouguiya', 'country': 'Mauritania', 'symbol': 'UM'},
      'MUR': {'name': 'Mauritian Rupee', 'country': 'Mauritius', 'symbol': '₨'},
      'MVR': {'name': 'Maldivian Rufiyaa', 'country': 'Maldives', 'symbol': 'Rf'},
      'MWK': {'name': 'Malawian Kwacha', 'country': 'Malawi', 'symbol': 'MK'},
      'MXN': {'name': 'Mexican Peso', 'country': 'Mexico', 'symbol': '\$'},
      'MXV': {'name': 'Mexican Investment Unit', 'country': 'Mexico', 'symbol': 'UDI'},
      'MYR': {'name': 'Malaysian Ringgit', 'country': 'Malaysia', 'symbol': 'RM'},
      'MZN': {'name': 'Mozambican Metical', 'country': 'Mozambique', 'symbol': 'MT'},
      'NAD': {'name': 'Namibian Dollar', 'country': 'Namibia', 'symbol': '\$'},
      'NGN': {'name': 'Nigerian Naira', 'country': 'Nigeria', 'symbol': '₦'},
      'NIO': {'name': 'Nicaraguan Córdoba', 'country': 'Nicaragua', 'symbol': 'C\$'},
      'NOK': {'name': 'Norwegian Krone', 'country': 'Norway', 'symbol': 'kr'},
      'NPR': {'name': 'Nepalese Rupee', 'country': 'Nepal', 'symbol': '₨'},
      'NZD': {'name': 'New Zealand Dollar', 'country': 'New Zealand', 'symbol': 'NZ\$'},
      'OMR': {'name': 'Omani Rial', 'country': 'Oman', 'symbol': 'ر.ع.'},
      'PAB': {'name': 'Panamanian Balboa', 'country': 'Panama', 'symbol': 'B/.'},
      'PEN': {'name': 'Peruvian Sol', 'country': 'Peru', 'symbol': 'S/.'},
      'PGK': {'name': 'Papua New Guinean Kina', 'country': 'Papua New Guinea', 'symbol': 'K'},
      'PHP': {'name': 'Philippine Peso', 'country': 'Philippines', 'symbol': '₱'},
      'PKR': {'name': 'Pakistani Rupee', 'country': 'Pakistan', 'symbol': '₨'},
      'PLN': {'name': 'Polish Zloty', 'country': 'Poland', 'symbol': 'zł'},
      'PYG': {'name': 'Paraguayan Guarani', 'country': 'Paraguay', 'symbol': '₲'},
      'QAR': {'name': 'Qatari Rial', 'country': 'Qatar', 'symbol': 'ر.ق'},
      'RON': {'name': 'Romanian Leu', 'country': 'Romania', 'symbol': 'lei'},
      'RSD': {'name': 'Serbian Dinar', 'country': 'Serbia', 'symbol': 'дин.'},
      'RUB': {'name': 'Russian Ruble', 'country': 'Russia', 'symbol': '₽'},
      'RWF': {'name': 'Rwandan Franc', 'country': 'Rwanda', 'symbol': 'FRw'},
      'SAR': {'name': 'Saudi Riyal', 'country': 'Saudi Arabia', 'symbol': 'ر.س'},
      'SBD': {'name': 'Solomon Islands Dollar', 'country': 'Solomon Islands', 'symbol': '\$'},
      'SCR': {'name': 'Seychellois Rupee', 'country': 'Seychelles', 'symbol': '₨'},
      'SDG': {'name': 'Sudanese Pound', 'country': 'Sudan', 'symbol': 'ج.س'},
      'SEK': {'name': 'Swedish Krona', 'country': 'Sweden', 'symbol': 'kr'},
      'SGD': {'name': 'Singapore Dollar', 'country': 'Singapore', 'symbol': 'S\$'},
      'SHP': {'name': 'St. Helena Pound', 'country': 'Saint Helena', 'symbol': '£'},
      'SLL': {'name': 'Sierra Leonean Leone', 'country': 'Sierra Leone', 'symbol': 'Le'},
      'SOS': {'name': 'Somali Shilling', 'country': 'Somalia', 'symbol': 'Sh'},
      'SPL': {'name': 'Surinamese Guilder', 'country': 'Suriname', 'symbol': 'ƒ'},
      'SRD': {'name': 'Surinamese Dollar', 'country': 'Suriname', 'symbol': '\$'},
      'STN': {'name': 'São Tomé & Príncipe Dobra', 'country': 'São Tomé and Príncipe', 'symbol': 'Db'},
      'SYP': {'name': 'Syrian Pound', 'country': 'Syria', 'symbol': '£'},
      'SZL': {'name': 'Swazi Lilangeni', 'country': 'Eswatini', 'symbol': 'L'},
      'THB': {'name': 'Thai Baht', 'country': 'Thailand', 'symbol': '฿'},
      'TJS': {'name': 'Tajikistani Somoni', 'country': 'Tajikistan', 'symbol': 'ЅМ'},
      'TMT': {'name': 'Turkmenistani Manat', 'country': 'Turkmenistan', 'symbol': 'm'},
      'TND': {'name': 'Tunisian Dinar', 'country': 'Tunisia', 'symbol': 'د.ت'},
      'TOP': {'name': 'Tongan Paanga', 'country': 'Tonga', 'symbol': 'T\$'},
      'TRY': {'name': 'Turkish Lira', 'country': 'Turkey', 'symbol': '₺'},
      'TTD': {'name': 'Trinidad & Tobago Dollar', 'country': 'Trinidad and Tobago', 'symbol': 'TT\$'},
      'TVD': {'name': 'Tuvaluan Dollar', 'country': 'Tuvalu', 'symbol': '\$'},
      'TWD': {'name': 'New Taiwan Dollar', 'country': 'Taiwan', 'symbol': 'NT\$'},
      'TZS': {'name': 'Tanzanian Shilling', 'country': 'Tanzania', 'symbol': 'TSh'},
      'UAH': {'name': 'Ukrainian Hryvnia', 'country': 'Ukraine', 'symbol': '₴'},
      'UGX': {'name': 'Ugandan Shilling', 'country': 'Uganda', 'symbol': 'USh'},
      'USD': {'name': 'US Dollar', 'country': 'United States', 'symbol': '\$'},
      'USN': {'name': 'US Dollar (Next day)', 'country': 'United States', 'symbol': '\$'},
      'UYI': {'name': 'Uruguayan Peso', 'country': 'Uruguay', 'symbol': '\$U'},
      'UYU': {'name': 'Uruguayan Peso', 'country': 'Uruguay', 'symbol': '\$U'},
      'UZS': {'name': 'Uzbekistani Som', 'country': 'Uzbekistan', 'symbol': 'лв'},
      'VED': {'name': 'Venezuelan Bolívar', 'country': 'Venezuela', 'symbol': 'Bs.'},
      'VES': {'name': 'Venezuelan Bolívar Soberano', 'country': 'Venezuela', 'symbol': 'Bs.'},
      'VND': {'name': 'Vietnamese Dong', 'country': 'Vietnam', 'symbol': '₫'},
      'VUV': {'name': 'Vanuatu Vatu', 'country': 'Vanuatu', 'symbol': 'Vt'},
      'WST': {'name': 'Samoan Tala', 'country': 'Samoa', 'symbol': 'T'},
      'XAG': {'name': 'Silver (one troy ounce)', 'country': 'Precious Metal', 'symbol': 'Ag'},
      'XAU': {'name': 'Gold (one troy ounce)', 'country': 'Precious Metal', 'symbol': 'Au'},
      'XBA': {'name': 'European Composite Unit', 'country': 'Europe', 'symbol': 'EURCO'},
      'XBB': {'name': 'European Monetary Unit', 'country': 'Europe', 'symbol': 'EMU-6'},
      'XBC': {'name': 'European Unit of Account 9', 'country': 'Europe', 'symbol': 'EUA-9'},
      'XBD': {'name': 'European Unit of Account 17', 'country': 'Europe', 'symbol': 'EUA-17'},
      'XCD': {'name': 'East Caribbean Dollar', 'country': 'East Caribbean', 'symbol': '\$'},
      'XDR': {'name': 'Special Drawing Right', 'country': 'IMF', 'symbol': 'XDR'},
      'XOF': {'name': 'West African CFA Franc', 'country': 'West Africa', 'symbol': 'Fr'},
      'XPD': {'name': 'Palladium (one troy ounce)', 'country': 'Precious Metal', 'symbol': 'Pd'},
      'XPF': {'name': 'CFP Franc', 'country': 'French Polynesia', 'symbol': '₣'},
      'XPT': {'name': 'Platinum (one troy ounce)', 'country': 'Precious Metal', 'symbol': 'Pt'},
      'XSU': {'name': 'Sucre', 'country': 'ALBA', 'symbol': 'XSU'},
      'XTS': {'name': 'Code reserved for testing', 'country': 'Testing', 'symbol': 'XTS'},
      'XUA': {'name': 'ADB Unit of Account', 'country': 'ADB', 'symbol': 'XUA'},
      'XXX': {'name': 'No currency', 'country': 'Unknown', 'symbol': 'XXX'},
      'YER': {'name': 'Yemeni Rial', 'country': 'Yemen', 'symbol': 'ر.ي'},
      'ZAR': {'name': 'South African Rand', 'country': 'South Africa', 'symbol': 'R'},
      'ZMW': {'name': 'Zambian Kwacha', 'country': 'Zambia', 'symbol': 'ZK'},
      'ZWL': {'name': 'Zimbabwean Dollar', 'country': 'Zimbabwe', 'symbol': '\$'},
    };
  }

  /// Get currency info with fallback for unknown currencies
  static Map<String, String> _getCurrencyInfo(String currencyCode, Map<String, Map<String, String>> currencyMap) {
    final code = currencyCode.toUpperCase();
    
    // Check if currency exists in the database
    if (currencyMap.containsKey(code)) {
      return currencyMap[code]!;
    }
    
    // Generate a default entry for unknown currencies using country region codes
    final countryMap = _getCurrencyToCountryMap();
    final country = countryMap[code] ?? code;
    
    return {
      'name': code,
      'country': country,
      'symbol': code,
    };
  }

  /// Map of currency codes to country/region names for fallback
  static Map<String, String> _getCurrencyToCountryMap() {
    return {
      'AED': 'United Arab Emirates',
      'AFN': 'Afghanistan',
      'ALL': 'Albania',
      'AMD': 'Armenia',
      'ANG': 'Netherlands Antilles',
      'AOA': 'Angola',
      'ARS': 'Argentina',
      'AUD': 'Australia',
      'AWG': 'Aruba',
      'AZN': 'Azerbaijan',
      'BAM': 'Bosnia and Herzegovina',
      'BBD': 'Barbados',
      'BDT': 'Bangladesh',
      'BGN': 'Bulgaria',
      'BHD': 'Bahrain',
      'BIF': 'Burundi',
      'BMD': 'Bermuda',
      'BND': 'Brunei',
      'BOB': 'Bolivia',
      'BRL': 'Brazil',
      'BSD': 'Bahamas',
      'BTN': 'Bhutan',
      'BWP': 'Botswana',
      'BZD': 'Belize',
      'CAD': 'Canada',
      'CDF': 'Democratic Republic of the Congo',
      'CHE': 'Switzerland',
      'CHF': 'Switzerland',
      'CHW': 'Switzerland',
      'CLF': 'Chile',
      'CLP': 'Chile',
      'CNY': 'China',
      'COP': 'Colombia',
      'COU': 'Colombia',
      'CRC': 'Costa Rica',
      'CUC': 'Cuba',
      'CUP': 'Cuba',
      'CVE': 'Cape Verde',
      'CZK': 'Czech Republic',
      'DJF': 'Djibouti',
      'DKK': 'Denmark',
      'DOP': 'Dominican Republic',
      'DZD': 'Algeria',
      'EGP': 'Egypt',
      'ERN': 'Eritrea',
      'ETB': 'Ethiopia',
      'EUR': 'European Union',
      'FJD': 'Fiji',
      'FKP': 'Falkland Islands',
      'GBP': 'United Kingdom',
      'GEL': 'Georgia',
      'GHS': 'Ghana',
      'GIP': 'Gibraltar',
      'GMD': 'Gambia',
      'GNF': 'Guinea',
      'GTQ': 'Guatemala',
      'GYD': 'Guyana',
      'HKD': 'Hong Kong',
      'HNL': 'Honduras',
      'HRK': 'Croatia',
      'HTG': 'Haiti',
      'HUF': 'Hungary',
      'IDR': 'Indonesia',
      'ILS': 'Israel',
      'INR': 'India',
      'IQD': 'Iraq',
      'IRR': 'Iran',
      'ISK': 'Iceland',
      'JMD': 'Jamaica',
      'JOD': 'Jordan',
      'JPY': 'Japan',
      'KES': 'Kenya',
      'KGS': 'Kyrgyzstan',
      'KHR': 'Cambodia',
      'KMF': 'Comoros',
      'KPW': 'North Korea',
      'KRW': 'South Korea',
      'KWD': 'Kuwait',
      'KYD': 'Cayman Islands',
      'KZT': 'Kazakhstan',
      'LAK': 'Laos',
      'LBP': 'Lebanon',
      'LKR': 'Sri Lanka',
      'LRD': 'Liberia',
      'LSL': 'Lesotho',
      'LYD': 'Libya',
      'MAD': 'Morocco',
      'MDL': 'Moldova',
      'MGA': 'Madagascar',
      'MKD': 'North Macedonia',
      'MMK': 'Myanmar',
      'MNT': 'Mongolia',
      'MOP': 'Macao',
      'MRU': 'Mauritania',
      'MUR': 'Mauritius',
      'MVR': 'Maldives',
      'MWK': 'Malawi',
      'MXN': 'Mexico',
      'MXV': 'Mexico',
      'MYR': 'Malaysia',
      'MZN': 'Mozambique',
      'NAD': 'Namibia',
      'NGN': 'Nigeria',
      'NIO': 'Nicaragua',
      'NOK': 'Norway',
      'NPR': 'Nepal',
      'NZD': 'New Zealand',
      'OMR': 'Oman',
      'PAB': 'Panama',
      'PEN': 'Peru',
      'PGK': 'Papua New Guinea',
      'PHP': 'Philippines',
      'PKR': 'Pakistan',
      'PLN': 'Poland',
      'PYG': 'Paraguay',
      'QAR': 'Qatar',
      'RON': 'Romania',
      'RSD': 'Serbia',
      'RUB': 'Russia',
      'RWF': 'Rwanda',
      'SAR': 'Saudi Arabia',
      'SBD': 'Solomon Islands',
      'SCR': 'Seychelles',
      'SDG': 'Sudan',
      'SEK': 'Sweden',
      'SGD': 'Singapore',
      'SHP': 'Saint Helena',
      'SLL': 'Sierra Leone',
      'SOS': 'Somalia',
      'SPL': 'Suriname',
      'SRD': 'Suriname',
      'STN': 'São Tomé and Príncipe',
      'SYP': 'Syria',
      'SZL': 'Eswatini',
      'THB': 'Thailand',
      'TJS': 'Tajikistan',
      'TMT': 'Turkmenistan',
      'TND': 'Tunisia',
      'TOP': 'Tonga',
      'TRY': 'Turkey',
      'TTD': 'Trinidad and Tobago',
      'TVD': 'Tuvalu',
      'TWD': 'Taiwan',
      'TZS': 'Tanzania',
      'UAH': 'Ukraine',
      'UGX': 'Uganda',
      'USD': 'United States',
      'USN': 'United States',
      'UYI': 'Uruguay',
      'UYU': 'Uruguay',
      'UZS': 'Uzbekistan',
      'VED': 'Venezuela',
      'VES': 'Venezuela',
      'VND': 'Vietnam',
      'VUV': 'Vanuatu',
      'WST': 'Samoa',
      'XAG': 'Precious Metal',
      'XAU': 'Precious Metal',
      'XBA': 'Europe',
      'XBB': 'Europe',
      'XBC': 'Europe',
      'XBD': 'Europe',
      'XCD': 'East Caribbean',
      'XDR': 'IMF',
      'XOF': 'West Africa',
      'XPD': 'Precious Metal',
      'XPF': 'French Polynesia',
      'XPT': 'Precious Metal',
      'XSU': 'ALBA',
      'XTS': 'Testing',
      'XUA': 'ADB',
      'XXX': 'Unknown',
      'YER': 'Yemen',
      'ZAR': 'South Africa',
      'ZMW': 'Zambia',
      'ZWL': 'Zimbabwe',
    };
  }
  static Future<List<String>> getSupportedCurrencies() async {
    try {
      final hasConnection = await checkConnection();
      if (!hasConnection) {
        throw SocketException('No internet connection');
      }

      // Use USD as base to get all available currencies
      final rates = await getExchangeRates('USD');
      return rates.keys.toList()..sort();
    } catch (e) {
      throw Exception('Failed to get currency list: $e');
    }
  }

  /// Clear all caches
  static void clearCache() {
    _ratesCache.clear();
    _currencyCache.clear();
    _lastFetchTime = null;
  }

  /// Get cache status
  static bool isCacheValid() {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }
}

