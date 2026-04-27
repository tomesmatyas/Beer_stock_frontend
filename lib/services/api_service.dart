import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/product.dart';
import '../cubits/cart_cubit.dart';
import 'dart:developer' as developer;

import 'package:url_launcher/url_launcher.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      // Pokud běžíš na emulátoru, Android vrací 'google_sdk' nebo 'sdk_gphone'
      // To je trochu složitější na detekci, tak můžeme použít jednoduchý trik:
      // Pokud chceš mít obě zařízení naráz, můžeš použít IP hotspotu pro OBĚ,
      // pokud je PC a emulátor ve stejné virtuální síti.

      // NEJJEDNODUŠŠÍ CESTA:
      // Pro emulátor: http://10.0.2.2:8000
      // Pro mobil: http://192.168.137.1:8000

      return 'http://10.0.2.2:8000'; // Zkus nejdřív tuhle pro mobil
    }
    return 'http://localhost:8000';
  }
}

class ApiService {
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
  static String get allProductsUrl => '$baseUrl/api/products/all/';
  static String get restockUrl => '$baseUrl/api/products/restock/';

  // Reporty
  static String get dailyPdfUrl => '$baseUrl/api/reports/daily-pdf/';
  static String get monthlyPdfUrl => '$baseUrl/api/reports/monthly-pdf/';
  static String get createProductUrl => '$baseUrl/api/products/create/';
  // Stáhne úplně všechny produkty
  Future<List<dynamic>> fetchAllProducts() async {
    final response = await http.get(
      Uri.parse(allProductsUrl),
      headers: {
        "Content-Type": "application/json",
        // <--- TOTO PŘIDEJ
      },
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
      headers: {"Content-Type": "application/json"},
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
      headers: {
        "Content-Type": "application/json",
        // <--- TOTO PŘIDEJ
      },

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
      headers: {
        "Content-Type": "application/json",
        // <--- TOTO PŘIDEJ
      },
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
      headers: {
        "Content-Type": "application/json",
        // <--- TOTO PŘIDEJ
      },
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
      headers: {
        "Content-Type": "application/json",
        // <--- TOTO PŘIDEJ
      },
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
      headers: {
        "Content-Type": "application/json",
        // <--- TOTO PŘIDEJ
      },
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
    int userId,
  ) async {
    // Převedeme naše sudy z košíku do formátu pro Django
    final List<Map<String, dynamic>> orderItems = items
        .map(
          (item) => {"product_id": item.product.id, "quantity": item.quantity},
        )
        .toList();

    final response = await http.post(
      Uri.parse(orderUrl),
      headers: {
        "Content-Type": "application/json",
        // <--- TOTO PŘIDEJ
      },
      body: json.encode({
        "items": orderItems,
        "total_amount": totalAmount,
        "kegs_rented": kegsRented, // <--- ODESLÁNÍ DO DJANGA
        "kegs_returned": kegsReturned,
        "user_id": userId,
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
        headers: {
          "Content-Type": "application/json",
          // <--- TOTO PŘIDEJ
        },
      );

      if (response.statusCode == 200) {
        // Dekódování JSONu z UTF-8 (aby fungovala česká diakritika)
        List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
        return body.map((dynamic item) => Product.fromJson(item)).toList();
      } else {
        throw Exception('Chyba při načítání dat z API');
      }
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
      headers: {
        "Content-Type": "application/json",
        // <--- TOTO PŘIDEJ
      },
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
      headers: {"Content-Type": "application/json"},
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
      headers: {"Content-Type": "application/json"},
      body: json.encode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      // Heslo je správně, vracíme data uživatele (včetně role)
      return json.decode(utf8.decode(response.bodyBytes));
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
      headers: {"Content-Type": "application/json"},
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
      headers: {"Content-Type": "application/json"},
      body: json.encode(updatedData),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Nepodařilo se upravit produkt. Kód: ${response.statusCode}',
      );
    }
  }
}
