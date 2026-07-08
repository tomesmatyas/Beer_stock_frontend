import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../cubits/cart_cubit.dart';
import 'dart:developer' as developer;

import 'package:url_launcher/url_launcher.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _definedBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    final configuredBaseUrl = _definedBaseUrl.trim();
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    // In release fallback to production API unless overridden by --dart-define.
    if (kReleaseMode) {
      return 'https://api.skladpivark.cz';
    }

    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'https://api.skladpivark.cz';
    }
    return 'http://localhost:8000';
  }
}

class ApiService {
  static String? _accessToken;

  static void setAuthToken(String token) {
    _accessToken = token;
  }

  static void clearAuthToken() {
    _accessToken = null;
  }

  static Map<String, String> _headers({bool requiresAuth = false}) {
    final headers = <String, String>{"Content-Type": "application/json"};
    if (requiresAuth && _accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  // 1. Propojení na tvůj chytrý konfigurátor
  static String get baseUrl => ApiConfig.baseUrl;

  // 2. Ostatní adresy musí být 'get', aby se přizpůsobily aktuální baseUrl
  static String get apiUrl => '$baseUrl/api/products/';
  static String get loginUrl => '$baseUrl/api/login/';

  // Objednávky a vratky
  static String get orderUrl => '$baseUrl/api/orders/create/';
  static String get refundUrl => '$baseUrl/api/orders/refund/';
  static String get pendingOrdersUrl => '$baseUrl/api/orders/pending/';
  static String get historyUrl => '$baseUrl/api/orders/history/';
  static String get fulfillOrderUrl => '$baseUrl/api/orders/';
  static String get createReservationUrl => '$baseUrl/api/orders/reserve/';

  // Produkty a sklad
  static String get allProductsUrl => '$baseUrl/api/web/products/';
  static String get webProductsUrl => '$baseUrl/api/web/products/';
  static String get restockUrl => '$baseUrl/api/products/restock/';

  // Reporty
  static String get dailyPdfUrl => '$baseUrl/api/reports/daily-pdf/';
  static String get monthlyPdfUrl => '$baseUrl/api/reports/monthly-pdf/';
  static String get createProductUrl => '$baseUrl/api/products/create/';
  static String get categoriesUrl => '$baseUrl/api/categories/';

  Future<List<ProductCategory>> fetchCategories() async {
    final response = await http.get(
      Uri.parse(categoriesUrl),
      headers: _headers(requiresAuth: true),
    );

    final String body = utf8.decode(response.bodyBytes);
    developer.log(
      'fetchCategories status=${response.statusCode} body=$body',
      name: 'api.service',
    );

    if (response.statusCode == 200) {
      final dynamic decoded = json.decode(body);
      final List<dynamic> data;
      if (decoded is List<dynamic>) {
        data = decoded;
      } else if (decoded is Map<String, dynamic> &&
          decoded['results'] is List) {
        data = decoded['results'];
      } else {
        throw Exception(
          'Neznámý formát odpovědi kategorií: ${decoded.runtimeType}',
        );
      }

      return data
          .map((item) => ProductCategory.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    if (response.statusCode == 404) {
      developer.log(
        'Kategorie endpoint neexistuje (404); vracím prázdný seznam',
        name: 'api.service',
      );
      return [];
    }

    throw Exception(
      'Chyba při načítání kategorií (${response.statusCode}): $body',
    );
  }

  // Stáhne úplně všechny produkty
  Future<List<dynamic>> fetchAllProducts() async {
    final response = await http.get(
      Uri.parse(allProductsUrl),
      headers: _headers(requiresAuth: true),
    );

    // --- PŘIDEJ TENTO ŘÁDEK PRO DEBUG ---
    developer.log('Data ze serveru: ${response.body}', name: 'api.service');
    // ------------------------------------
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Chyba při načítání všech produktů');
    }
  }

  // Funkce pro vytvoření nového produktu
  Future<void> createProduct(Map<String, dynamic> productData) async {
    final response = await http.post(
      Uri.parse(
        createProductUrl,
      ), // Většinou se POST posílá na stejnou URL jako GET seznamu
      headers: _headers(requiresAuth: true),
      body: json.encode(productData),
    );

    // 200 = OK, 201 = Created (Django REST framework vrací často 201)
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Nepodařilo se vytvořit produkt. Server vrátil: ${response.statusCode}',
      );
    }
  }

  // Odešle data k naskladnění
  Future<void> restockProducts(List<Map<String, dynamic>> items) async {
    final response = await http.post(
      Uri.parse(restockUrl),
      headers: _headers(requiresAuth: true),

      body: json.encode({"items": items}),
    );

    if (response.statusCode != 200) {
      throw Exception('Chyba při naskladnění: ${response.body}');
    }
  }

  // 1. Stáhne čekající rezervace
  Future<List<dynamic>> fetchPendingOrders() async {
    final response = await http.get(
      Uri.parse(pendingOrdersUrl),
      headers: _headers(requiresAuth: true),
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Chyba při stahování rezervací');
    }
  }

  Future<List<dynamic>> fetchOrderHistory() async {
    final response = await http.get(
      Uri.parse(historyUrl),
      headers: _headers(requiresAuth: true),
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Chyba historie');
  }

  // 2. Vyřídí (zaplatí) konkrétní rezervaci
  Future<void> fulfillOrder(
    int orderId,
    List<CartItem> items,
    double totalAmount,
  ) async {
    final List<Map<String, dynamic>> orderItems = items
        .map(
          (item) => {"product_id": item.product.id, "quantity": item.quantity},
        )
        .toList();

    final response = await http.post(
      Uri.parse('$fulfillOrderUrl$orderId/fulfill/'),
      headers: _headers(requiresAuth: true),
      body: json.encode({"items": orderItems, "total_amount": totalAmount}),
    );

    if (response.statusCode != 200) {
      throw Exception('Chyba při vyřizování rezervace: ${response.body}');
    }
  }

  // 3. Zruší propadlou rezervaci (vrátí sudy na sklad)
  Future<void> cancelOrder(int orderId) async {
    final response = await http.post(
      Uri.parse('$fulfillOrderUrl$orderId/cancel/'),
      headers: _headers(requiresAuth: true),
    );
    if (response.statusCode != 200) {
      throw Exception('Chyba při rušení rezervace');
    }
  }

  // NOVÁ FUNKCE PRO BĚŽNÝ PRODEJ
  Future<void> createOrder(
    List<CartItem> items,
    double totalAmount,
    int kegsRented, // <--- NOVÉ
    int kegsReturned,
  ) async {
    // Převedeme naše sudy z košíku do formátu pro Django
    final List<Map<String, dynamic>> orderItems = items
        .map(
          (item) => {"product_id": item.product.id, "quantity": item.quantity},
        )
        .toList();

    final response = await http.post(
      Uri.parse(orderUrl),
      headers: _headers(requiresAuth: true),
      body: json.encode({
        "items": orderItems,
        "total_amount": totalAmount,
        "kegs_rented": kegsRented, // <--- ODESLÁNÍ DO DJANGA
        "kegs_returned": kegsReturned,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Chyba při odesílání prodeje: ${response.body}');
    }
  }

  Future<List<Product>> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: _headers(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        // Dekódování JSONu z UTF-8 (aby fungovala česká diakritika)
        List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
        return body.map((dynamic item) => Product.fromJson(item)).toList();
      }

      if (response.statusCode == 404) {
        final fallbackResponse = await http.get(
          Uri.parse(webProductsUrl),
          headers: _headers(),
        );
        if (fallbackResponse.statusCode == 200) {
          List<dynamic> body = json.decode(
            utf8.decode(fallbackResponse.bodyBytes),
          );
          return body.map((dynamic item) => Product.fromJson(item)).toList();
        }
      }

      throw Exception(
        'Chyba při načítání dat z API (${response.statusCode}): ${utf8.decode(response.bodyBytes)}',
      );
    } catch (e) {
      throw Exception('Nelze se připojit k serveru: $e');
    }
  }

  Future<void> refundOrder(
    List<Map<String, dynamic>> items,
    double totalAmount,
  ) async {
    final response = await http.post(
      Uri.parse(refundUrl),
      headers: _headers(requiresAuth: true),
      body: json.encode({"items": items, "total_amount": totalAmount}),
    );

    if (response.statusCode != 201) {
      throw Exception('Chyba při refundaci: ${response.body}');
    }
  }
  // lib/services/api_service.dart

  // Přidejte do třídy ApiService:

  Future<void> downloadDailyReport() async {
    final Uri url = Uri.parse(dailyPdfUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Nepodařilo se otevřít report na adrese $url');
    }
  }

  Future<void> downloadMonthlyReport() async {
    final Uri url = Uri.parse(monthlyPdfUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Nepodařilo se otevřít report na adrese $url');
    }
  }

  Future<void> submitWebReservation({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String customerName,
    required String customerEmail, // NOVÉ
    required String customerPhone,
    required String associationName,
    required String pickupDate,
  }) async {
    final response = await http.post(
      Uri.parse(createReservationUrl),
      headers: _headers(),
      body: json.encode({
        "items": items,
        "total_amount": totalAmount,
        "customer_name": customerName,
        "customer_email": customerEmail, // NOVÉ
        "customer_phone": customerPhone,
        "association_name": associationName,
        "pickup_date": pickupDate,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Chyba při odesílání rezervace: ${response.body}');
    }
  }

  // --- NOVÁ FUNKCE PRO PŘIHLÁŠENÍ ---
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse(loginUrl),
      headers: _headers(),
      body: json.encode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Neplatná odpověď serveru při přihlášení.');
      }

      final user = decoded['user'];
      final access = decoded['access'];

      if (user is! Map<String, dynamic> || access is! String) {
        throw Exception('V odpovědi přihlášení chybí uživatel nebo token.');
      }

      setAuthToken(access);

      return {
        'id': user['id'],
        'username': user['username'],
        'role': user['role'],
        'access': access,
        'refresh': decoded['refresh'],
      };
    } else if (response.statusCode == 401) {
      // Špatné heslo nebo jméno
      throw Exception('Nesprávné jméno nebo heslo!');
    } else {
      throw Exception('Chyba serveru při přihlašování.');
    }
  }

  // Funkce pro stažení statistik z dashboardu
  Future<Map<String, dynamic>> fetchDashboardStats() async {
    // Pokud nemáš adresu nahoře v proměnných, složíme ji takto:
    final url = '$baseUrl/api/reports/dashboard/';

    final response = await http.get(
      Uri.parse(url),
      headers: _headers(requiresAuth: true),
    );

    if (response.statusCode == 200) {
      // Dekódujeme JSON od Djanga
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception(
        'Nepodařilo se načíst statistiky: ${response.statusCode}',
      );
    }
  }

  // Funkce pro úpravu existujícího produktu
  Future<void> updateProduct(
    int productId,
    Map<String, dynamic> updatedData,
  ) async {
    // Předpokládám, že tvoje adresa v Djangu pro úpravu vypadá nějak takto.
    // Pokud ji máš jinak, uprav ji:
    final url = '$baseUrl/api/products/$productId/update/';

    final response = await http.put(
      // nebo http.patch podle toho, co máš v Djangu
      Uri.parse(url),
      headers: _headers(requiresAuth: true),
      body: json.encode(updatedData),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Nepodařilo se upravit produkt. Kód: ${response.statusCode}',
      );
    }
  }
}
