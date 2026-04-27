import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../../models/product.dart';
import '../../services/api_service.dart';

class RestockScreen extends StatefulWidget {
  const RestockScreen({Key? key}) : super(key: key);

  @override
  State<RestockScreen> createState() => _RestockScreenState();
}

class _RestockScreenState extends State<RestockScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Product>> futureProducts;

  // Pamet pro naklikane polozky (ID produktu : Pocet ks)
  Map<int, int> quantitiesToRestock = {};

  // Stav navigace v menu
  int? selectedVat;
  String? selectedBrand;

  @override
  void initState() {
    super.initState();
    futureProducts = apiService.fetchProducts();

    // Povolime rotaci pro tento konkretni displej
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // Odeslani dat na server
  Future<void> _submitRestock() async {
    final itemsToSubmit = quantitiesToRestock.entries
        .where((e) => e.value > 0)
        .map((e) => {"product_id": e.key, "quantity": e.value})
        .toList();

    if (itemsToSubmit.isEmpty) return;

    try {
      await apiService.restockProducts(itemsToSubmit);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zbozi uspesne naskladneno!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalItems = quantitiesToRestock.values.fold(
      0,
      (sum, qty) => sum + qty,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Prijem zbozi (Naskladneni)'),
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
      ),
      // SafeArea hlida vyrezy a zaoblene rohy displeje
      body: SafeArea(
        child: Column(
          children: [
            // HLAVNI PLOCHA S DYNAMICKYM GRIDEM
            Expanded(child: _buildDynamicGrid()),

            // SPODNI LIŠTA S POTVRZENIM
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'CELKEM K PRIJMU',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '$totalItems ks',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: totalItems > 0
                              ? Colors.green.shade700
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      backgroundColor: totalItems > 0
                          ? Colors.green
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      'POTVRDIT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: totalItems > 0 ? _submitRestock : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicGrid() {
    double screenWidth = MediaQuery.of(context).size.width;
    // Vypocet sirky dlazdice: na mobilu mensi, na tabletu vetsi
    double maxTileWidth = screenWidth > 700 ? 180 : 150;

    return FutureBuilder<List<Product>>(
      future: futureProducts,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        List<Product> allProducts = snapshot.data!;

        List<Widget> gridItems = [];

        // --- 1. NAVIGACNI KARTY (Menu) ---
        if (selectedVat == null) {
          gridItems.add(
            _buildCategoryCard(
              'PIVO (21%)',
              Icons.sports_bar,
              Colors.orange.shade800,
              () => setState(() => selectedVat = 21),
            ),
          );
          gridItems.add(
            _buildCategoryCard(
              'NEALKO (12%)',
              Icons.fastfood,
              Colors.green.shade700,
              () => setState(() => selectedVat = 12),
            ),
          );
        } else if (selectedBrand == null) {
          gridItems.add(
            _buildBackCard(() => setState(() => selectedVat = null)),
          );

          List<Product> filteredByVat = allProducts
              .where((p) => p.vatRate == selectedVat)
              .toList();
          List<String> brands = filteredByVat
              .map((p) => p.brand)
              .toSet()
              .toList();

          for (String brand in brands) {
            bool hasActive = filteredByVat
                .where((p) => p.brand == brand)
                .any((p) => (quantitiesToRestock[p.id] ?? 0) > 0);
            gridItems.add(
              _buildCategoryCard(
                brand,
                Icons.label_outline,
                hasActive ? Colors.green.shade600 : Colors.blueGrey.shade700,
                () => setState(() => selectedBrand = brand),
              ),
            );
          }
        } else {
          gridItems.add(
            _buildBackCard(() => setState(() => selectedBrand = null)),
          );
          List<Product> brandProducts = allProducts
              .where(
                (p) => p.vatRate == selectedVat && p.brand == selectedBrand,
              )
              .toList();
          for (Product p in brandProducts) {
            gridItems.add(_buildRestockItemCard(p));
          }
        }

        // --- 2. PRISPENDLENE KARTY (Polozky s qty > 0) ---
        // Ukazeme je na konci plochy, pokud zrovna nejsme v jejich materske slozce
        List<Product> pinned = allProducts.where((p) {
          int qty = quantitiesToRestock[p.id] ?? 0;
          if (qty == 0) return false;
          // Pokud je produkt uz zobrazen v ramci navigace, neduplikujeme ho
          if (selectedBrand != null &&
              p.brand == selectedBrand &&
              p.vatRate == selectedVat)
            return false;
          return true;
        }).toList();

        for (Product p in pinned) {
          gridItems.add(_buildRestockItemCard(p, isPinned: true));
        }

        // --- 3. SAMOTNY GRID ---
        return GridView.extent(
          padding: const EdgeInsets.all(16), // Okraje cele plochy
          maxCrossAxisExtent: maxTileWidth,
          childAspectRatio: 0.75, // Pomer sirka/vyska dlazdice
          crossAxisSpacing: 12, // Mezera mezi sloupci
          mainAxisSpacing: 12, // Mezera mezi radky
          children: gridItems,
        );
      },
    );
  }

  // --- KOMPONENTY KARET ---

  Widget _buildCategoryCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      color: color,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard(VoidCallback onTap) {
    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.undo, size: 35, color: Colors.white),
            Text(
              'ZPET',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestockItemCard(Product product, {bool isPinned = false}) {
    int qty = quantitiesToRestock[product.id] ?? 0;
    bool isActive = qty > 0;

    return Card(
      color: isActive ? Colors.green.shade50 : Colors.white,
      elevation: isActive ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: isActive ? Colors.green : Colors.grey.shade300,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              product.brand,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            Text(
              product.volume,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            if (isPinned)
              const Icon(Icons.push_pin, size: 12, color: Colors.green),

            const Spacer(),
            Text(
              '+$qty',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.green.shade800 : Colors.grey.shade400,
              ),
            ),
            const Spacer(),

            // RADA 1: +1 / -1
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionBtn(
                  '-',
                  Colors.red,
                  () => _changeQty(product.id, -1),
                ),
                _buildActionBtn(
                  '+',
                  Colors.green,
                  () => _changeQty(product.id, 1),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // RADA 2: +6 / -6
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionBtn(
                  '-6',
                  Colors.red,
                  () => _changeQty(product.id, -6),
                  isBulk: true,
                ),
                _buildActionBtn(
                  '+6',
                  Colors.green,
                  () => _changeQty(product.id, 6),
                  isBulk: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _changeQty(int id, int diff) {
    setState(() {
      int current = quantitiesToRestock[id] ?? 0;
      quantitiesToRestock[id] = max(0, current + diff);
    });
  }

  Widget _buildActionBtn(
    String label,
    Color color,
    VoidCallback onTap, {
    bool isBulk = false,
  }) {
    return SizedBox(
      width: isBulk ? 50 : 45,
      height: 32,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isBulk ? color : Colors.white,
          foregroundColor: isBulk ? Colors.white : color,
          side: isBulk
              ? BorderSide.none
              : BorderSide(color: color.withOpacity(0.5)),
          padding: EdgeInsets.zero,
          elevation: isBulk ? 2 : 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
