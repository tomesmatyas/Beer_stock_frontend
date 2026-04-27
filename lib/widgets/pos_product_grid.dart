import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/product.dart';
import '../cubits/cart_cubit.dart';

class PosProductGrid extends StatefulWidget {
  final Future<List<Product>> futureProducts;

  const PosProductGrid({super.key, required this.futureProducts});

  @override
  State<PosProductGrid> createState() => _PosProductGridState();
}

class _PosProductGridState extends State<PosProductGrid> {
  int? selectedVat;
  String? selectedBrand;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double maxTileWidth = screenWidth > 900 ? 180 : 140;

    return FutureBuilder<List<Product>>(
      future: widget.futureProducts,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        List<Product> allProducts = snapshot.data!;

        if (selectedVat == null) {
          return GridView(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            children: [
              _buildCategoryCard(
                'PIVO\n(21%)',
                Icons.sports_bar,
                Colors.orange.shade800,
                () => setState(() => selectedVat = 21),
              ),
              _buildCategoryCard(
                'NEALKO / JÍDLO\n(12%)',
                Icons.fastfood,
                Colors.green.shade700,
                () => setState(() => selectedVat = 12),
              ),
            ],
          );
        }

        List<Product> filteredByVat = allProducts
            .where((p) => p.vatRate == selectedVat)
            .toList();
        List<String> brands = filteredByVat
            .map((p) => p.brand)
            .toSet()
            .toList();

        if (selectedBrand == null) {
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxTileWidth,
              childAspectRatio: 1.3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: brands.length + 1,
            itemBuilder: (ctx, index) {
              if (index == 0)
                return _buildBackCard(() => setState(() => selectedVat = null));
              String brand = brands[index - 1];
              return _buildCategoryCard(
                brand,
                Icons.label_outline,
                Colors.blueGrey.shade700,
                () => setState(() => selectedBrand = brand),
                compact: true,
              );
            },
          );
        }

        List<Product> finalProducts = filteredByVat
            .where((p) => p.brand == selectedBrand)
            .toList();

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxTileWidth,
            childAspectRatio: 1.1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: finalProducts.length + 1,
          itemBuilder: (ctx, index) {
            if (index == 0)
              return _buildBackCard(() => setState(() => selectedBrand = null));
            return _buildProductCard(finalProducts[index - 1]);
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool compact = false,
  }) {
    return Card(
      color: color,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: compact ? 24 : 32, color: Colors.white),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: compact ? 13 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackCard(VoidCallback onTap) {
    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.undo, size: 24, color: Colors.white),
            Text(
              'ZPĚT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    bool isOutOfStock = product.currentStock <= 0;
    bool isLowStock = product.currentStock > 0 && product.currentStock < 5;

    return Card(
      elevation: isOutOfStock ? 0 : 2,
      color: isOutOfStock ? Colors.grey.shade200 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isOutOfStock
            ? BorderSide(color: Colors.grey.shade300)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isOutOfStock
            ? null
            : () => context.read<CartCubit>().addProduct(product),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                product.brand,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isOutOfStock ? Colors.grey.shade600 : Colors.black,
                  decoration: isOutOfStock ? TextDecoration.lineThrough : null,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
              Text(
                product.volume,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const Divider(height: 8),
              Text(
                '${product.price} Kč',
                style: TextStyle(
                  color: isOutOfStock ? Colors.grey.shade500 : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                isOutOfStock ? 'VYPRODÁNO' : 'Sklad: ${product.currentStock}',
                style: TextStyle(
                  fontSize: 10,
                  color: isOutOfStock
                      ? Colors.red.shade400
                      : (isLowStock ? Colors.red : Colors.orange.shade800),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
