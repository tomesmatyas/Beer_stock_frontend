import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/product.dart';
import '../services/api_service.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/cart_cubit.dart';
import '../screen/admin_dashboard.dart';
import '../screen/restock_screen.dart';
import '../widgets/pos_product_grid.dart';
import '../widgets/pos_cart_panel.dart';
import '../utils/pos_dialogs.dart';
import '../screen/scanner_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Product>> futureProducts;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _loadProducts() {
    setState(() {
      futureProducts = apiService.fetchProducts();
    });
  }

  Future<void> _handleScannedBarcode(String barcode) async {
    try {
      final products = await apiService.fetchProducts();
      Product? foundProduct;
      for (final product in products) {
        if (product.barcode.trim() == barcode.trim()) {
          foundProduct = product;
          break;
        }
      }

      if (!mounted) return;

      if (foundProduct != null) {
        context.read<CartCubit>().addProduct(foundProduct);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Přidáno: ${foundProduct.brand} ${foundProduct.volume}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        PosDialogs.showUnknownBarcodeDialog(
          context,
          barcode,
          apiService,
          _loadProducts,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chyba při načítání produktů: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🍺 Pokladna'),
        actions: [
          if (context.read<AuthCubit>().state.role == 'ADMIN')
            IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Colors.blueGrey),
              onPressed: () async {
                var res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScannerScreen(),
                  ),
                );
                if (res is String) _handleScannedBarcode(res);
              },
            ),
          if (context.read<AuthCubit>().state.role == 'ADMIN')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.amber),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminDashboard()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.local_shipping, color: Colors.blueGrey),
            onPressed: () async {
              final didRestock = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RestockScreen()),
              );
              if (didRestock == true) _loadProducts();
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.blueGrey),
            onPressed: () =>
                PosDialogs.showOrdersHistoryDialog(context, apiService),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download, color: Colors.blueGrey),
            onPressed: () => PosDialogs.showPendingOrdersDialog(
              context,
              apiService,
              futureProducts,
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProducts),
          const VerticalDivider(
            color: Colors.white24,
            indent: 10,
            endIndent: 10,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.blueGrey),
            onPressed: () => context.read<AuthCubit>().logout(),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: isSmallScreen
            ? PosProductGrid(futureProducts: futureProducts)
            : Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: PosProductGrid(futureProducts: futureProducts),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Colors.grey,
                  ),
                  Expanded(
                    flex: 4,
                    child: PosCartPanel(
                      apiService: apiService,
                      onSaleComplete: _loadProducts,
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: isSmallScreen
          ? BlocBuilder<CartCubit, CartState>(
              builder: (context, state) {
                int totalItems = state.items.fold(
                  0,
                  (sum, item) => sum + item.quantity,
                );
                return Badge(
                  label: Text('$totalItems'),
                  isLabelVisible: totalItems > 0,
                  child: FloatingActionButton(
                    backgroundColor: Colors.blue.shade700,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (ctx) => BlocProvider.value(
                          value: context.read<CartCubit>(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.9,
                            child: PosCartPanel(
                              apiService: apiService,
                              onSaleComplete: _loadProducts,
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Icon(Icons.shopping_cart, color: Colors.white),
                  ),
                );
              },
            )
          : null,
    );
  }
}
