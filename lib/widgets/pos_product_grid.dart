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
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double maxTileWidth = screenWidth > 900 ? 180 : 140;

    return FutureBuilder<List<Product>>(
      future: widget.futureProducts,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final List<Product> allProducts = snapshot.data!;
        final List<String> categories =
            allProducts
                .map((p) => p.category?.displayName ?? 'Nezařazeno')
                .toSet()
                .toList()
              ..sort();

        if (selectedCategory == null) {
          if (categories.isEmpty) {
            return const Center(child: Text('Žádné dostupné kategorie.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (ctx, index) {
              final category = categories[index];
              return _buildCategoryCard(
                category,
                Icons.category,
                Colors.blueGrey.shade700,
                () => setState(() => selectedCategory = category),
              );
            },
          );
        }

        final List<Product> finalProducts = allProducts
            .where(
              (p) =>
                  (p.category?.displayName ?? 'Nezařazeno') == selectedCategory,
            )
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
              return _buildBackCard(
                () => setState(() => selectedCategory = null),
              );
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
    bool isOnOrder = product.isOnOrder;

    return Card(
      elevation: isOutOfStock ? 0 : 2,
      color: isOutOfStock
          ? Colors.grey.shade200
          : isOnOrder
          ? Colors.orange.shade50
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isOnOrder
            ? BorderSide(color: Colors.orange.shade300, width: 1.5)
            : isOutOfStock
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
              if (isOnOrder)
                Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NA OBJEDNÁNÍ',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
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
