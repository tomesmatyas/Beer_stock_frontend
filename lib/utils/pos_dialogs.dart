import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../cubits/cart_cubit.dart';

class PosDialogs {
  static void showUnknownBarcodeDialog(
    BuildContext context,
    String barcode,
    ApiService apiService,
    VoidCallback onSuccess,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neznámý kód'),
        content: Text(
          'Kód $barcode není v databázi. Chcete přidat nový produkt?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ZRUŠIT'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _createNewProductWithBarcode(
                context,
                barcode,
                apiService,
                onSuccess,
              );
            },
            child: const Text('PŘIDAT'),
          ),
        ],
      ),
    );
  }

  static void _createNewProductWithBarcode(
    BuildContext context,
    String barcode,
    ApiService apiService,
    VoidCallback onSuccess,
  ) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    final brandCtrl = TextEditingController();
    final volumeCtrl = TextEditingController();
    final flavorCtrl = TextEditingController();
    final strengthCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '1');
    final stockCtrl = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();
    int selectedVat = 21;
    ProductCategory? selectedCategory;
    final futureCategories = apiService.fetchCategories();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setState) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Text('Nový produkt'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EAN: $barcode',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextFormField(
                      controller: brandCtrl,
                      decoration: const InputDecoration(labelText: 'Značka'),
                      validator: (v) => v!.isEmpty ? 'Povinné' : null,
                    ),
                    TextFormField(
                      controller: volumeCtrl,
                      decoration: const InputDecoration(labelText: 'Objem'),
                    ),
                    TextFormField(
                      controller: flavorCtrl,
                      decoration: const InputDecoration(labelText: 'Příchuť'),
                    ),
                    TextFormField(
                      controller: strengthCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Síla piva (např. 11°, 12°)',
                      ),
                    ),
                    TextFormField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(labelText: 'Cena'),
                      keyboardType: TextInputType.number,
                    ),
                    FutureBuilder<List<ProductCategory>>(
                      future: futureCategories,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Nelze načíst kategorie: ${snapshot.error}',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          );
                        }

                        final categories = snapshot.data ?? [];
                        if (categories.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('Žádné kategorie nebyly nalezeny.'),
                          );
                        }

                        // Flatten all categories and their ancestors into one selectable list
                        final Map<String, ProductCategory> unique = {};
                        void addChain(ProductCategory c) {
                          ProductCategory? cur = c;
                          // collect chain from this node up to root
                          final List<ProductCategory> chain = [];
                          while (cur != null) {
                            chain.add(cur);
                            cur = cur.parent;
                          }
                          // add nodes from root -> leaf to keep consistent ordering
                          for (var node in chain.reversed) {
                            final key = node.id != 0
                                ? 'id:${node.id}'
                                : 'name:${node.name}';
                            unique.putIfAbsent(key, () => node);
                          }
                        }

                        for (var c in categories) {
                          addChain(c);
                        }

                        final flat = unique.values.toList()
                          ..sort(
                            (a, b) => a.displayName.compareTo(b.displayName),
                          );

                        selectedCategory ??= flat.first;

                        return DropdownButtonFormField<ProductCategory>(
                          value: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Kategorie',
                          ),
                          items: flat
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() {
                            selectedCategory = value;
                          }),
                          validator: (value) =>
                              value == null ? 'Vyberte kategorii' : null,
                        );
                      },
                    ),
                    DropdownButtonFormField<int>(
                      value: selectedVat,
                      items: const [
                        DropdownMenuItem(
                          value: 12,
                          child: Text('12% (Nealko)'),
                        ),
                        DropdownMenuItem(value: 21, child: Text('21% (Pivo)')),
                      ],
                      onChanged: (v) => setState(() => selectedVat = v!),
                    ),
                    TextFormField(
                      controller: stockCtrl,
                      decoration: const InputDecoration(labelText: 'Skladem'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.landscapeLeft,
                    DeviceOrientation.landscapeRight,
                  ]);
                  Navigator.pop(ctx);
                },
                child: const Text('ZRUŠIT'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    await apiService.createProduct({
                      'brand': brandCtrl.text,
                      'volume': volumeCtrl.text,
                      'flavor': flavorCtrl.text,
                      'beer_strength': strengthCtrl.text,
                      'price': priceCtrl.text,
                      'current_stock': int.tryParse(stockCtrl.text) ?? 1,
                      'barcode': barcode,
                      'vat_rate': selectedVat,
                      'category': selectedCategory?.id,
                    });
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.landscapeLeft,
                      DeviceOrientation.landscapeRight,
                    ]);
                    Navigator.pop(ctx);
                    onSuccess();
                  }
                },
                child: const Text('ULOŽIT'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showOrdersHistoryDialog(
    BuildContext context,
    ApiService apiService,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Historie prodejů'),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: FutureBuilder<List<dynamic>>(
            future: apiService.fetchOrderHistory(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final orders = snapshot.data!;
              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return ListTile(
                    title: Text(
                      'Účtenka č. ${order['receipt_number']} - ${order['total_amount']} Kč',
                    ),
                    subtitle: Text(order['created_at']),
                    trailing: IconButton(
                      icon: const Icon(Icons.print),
                      onPressed: () => printOrder(context, order),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  static void printOrder(BuildContext context, dynamic order) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'DOKLAD O PRODEJI',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Divider(),
              Text(
                'Celkem: ${order['total_amount']} Kč',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ZAVŘÍT'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showPendingOrdersDialog(
    BuildContext context,
    ApiService apiService,
    Future<List<Product>> futureProducts,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Čekající rezervace'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<dynamic>>(
            future: apiService.fetchPendingOrders(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final orders = snapshot.data!;
              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return ListTile(
                    title: Text(order['customer'] ?? 'Neznámý'),
                    subtitle: Text('${order['total_amount']} Kč'),
                    trailing: IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () async {
                        List<Product> allProducts = await futureProducts;
                        List<CartItem> itemsToLoad = [];
                        for (var item in order['items']) {
                          Product? p = allProducts
                              .where(
                                (prod) =>
                                    prod.id.toString() ==
                                    item['product_id'].toString(),
                              )
                              .firstOrNull;
                          if (p != null)
                            itemsToLoad.add(
                              CartItem(product: p, quantity: item['quantity']),
                            );
                        }
                        if (context.mounted) {
                          context.read<CartCubit>().loadReservation(
                            order['id'],
                            itemsToLoad,
                          );
                          Navigator.pop(ctx);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
