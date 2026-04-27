import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

// PŘIDÁNO: 'with SingleTickerProviderStateMixin' pro správné fungování ovladače tabů
class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  final ApiService apiService = ApiService();
  late Future<List<Product>> futureProducts;
  late Future<Map<String, dynamic>> futureStats;

  // NOVÉ: Ruční ovladač pro taby
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    // Inicializace na 3 taby
    _tabController = TabController(length: 3, vsync: this);

    // Posluchač, který při přepnutí tabu obnoví obrazovku (aby se skrylo/ukázalo tlačítko)
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose(); // Úklid ovladače
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _loadData() {
    setState(() {
      futureProducts = apiService.fetchProducts();
      futureStats = apiService.fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        title: TabBar(
          controller: _tabController, // Napojení našeho ovladače
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Stats'),
            Tab(icon: Icon(Icons.inventory, size: 18), text: 'Sklad'),
            Tab(icon: Icon(Icons.picture_as_pdf, size: 18), text: 'PDF'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          const SizedBox(width: 8),
        ],
      ),

      // --- LOGIKA PRO PLUSKO UPROSTŘED ---
      // Tlačítko se ukáže jen pokud jsme na tabu "Sklad" (index 1)
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _showAddProductDialog,
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              elevation: 6,
              child: const Icon(Icons.add, size: 32),
            )
          : null,

      // Umístění tlačítka uprostřed dole
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      body: TabBarView(
        controller: _tabController, // Napojení našeho ovladače
        children: [
          _buildStatisticsTab(),
          _buildInventoryTab(),
          _buildReportsTab(context),
        ],
      ),
    );
  }

  // --- 1. STATISTIKY ---
  Widget _buildStatisticsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: futureStats,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Chyba: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else if (!snapshot.hasData) {
          return const Center(child: Text('Žádná data pro statistiky.'));
        }

        final data = snapshot.data!;
        final double totalRevenue = data['total_revenue_today'] ?? 0.0;
        final double vat12 = data['vat_12_today'] ?? 0.0;
        final double vat21 = data['vat_21_today'] ?? 0.0;
        final List chartData = data['chart_data'] ?? [];

        double maxRevenue = 1.0;
        for (var day in chartData) {
          if ((day['revenue'] as num).toDouble() > maxRevenue) {
            maxRevenue = (day['revenue'] as num).toDouble();
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Dnešní tržba',
                      '$totalRevenue Kč',
                      Colors.green,
                      Icons.attach_money,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'DPH 21% (Pivo)',
                      '$vat21 Kč',
                      Colors.orange,
                      Icons.local_drink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'DPH 12% (Nealko)',
                      '$vat12 Kč',
                      Colors.blue,
                      Icons.fastfood,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Tržby za posledních 7 dní',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: chartData.map<Widget>((dayData) {
                    final double dayRev = (dayData['revenue'] as num)
                        .toDouble();
                    final double percentage = dayRev / maxRevenue;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Tooltip(
                          message: '$dayRev Kč',
                          child: Container(
                            width: 30,
                            height: 140 * percentage,
                            decoration: BoxDecoration(
                              color: percentage > 0
                                  ? Colors.amber.shade600
                                  : Colors.grey.shade300,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dayData['date'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // --- 2. SPRÁVA SKLADU ---
  Widget _buildInventoryTab() {
    return FutureBuilder<List<Product>>(
      future: futureProducts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Chyba: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Žádné produkty v databázi.'));
        }

        List<Product> products = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            Product product = products[index];
            bool isLowStock = product.currentStock < 5;
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isLowStock
                      ? Colors.red.shade100
                      : Colors.blue.shade100,
                  child: Icon(
                    Icons.sports_bar,
                    color: isLowStock
                        ? Colors.red.shade800
                        : Colors.blue.shade800,
                  ),
                ),
                title: Text(
                  '${product.brand} (${product.volume})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Sazba DPH: ${product.vatRate} %'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${product.price} Kč',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Skladem: ${product.currentStock} ks',
                          style: TextStyle(
                            color: isLowStock ? Colors.red : Colors.green,
                            fontWeight: isLowStock
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueGrey),
                      onPressed: () => _showEditProductDialog(context, product),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 3. REPORTY ---
  Widget _buildReportsTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: GridView.count(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        children: [
          _buildAdminCard(
            context,
            title: 'Denní uzávěrka (PDF)',
            icon: Icons.picture_as_pdf,
            color: Colors.redAccent,
            onTap: () async {
              try {
                await apiService.downloadDailyReport();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Denní uzávěrka stažena.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Chyba: $e')));
              }
            },
          ),
          _buildAdminCard(
            context,
            title: 'Měsíční uzávěrka (PDF)',
            icon: Icons.date_range,
            color: Colors.blueAccent,
            onTap: () async {
              try {
                await apiService.downloadMonthlyReport();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Měsíční uzávěrka stažena.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Chyba: $e')));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOG PRO PŘIDÁNÍ ---
  void _showAddProductDialog() {
    final TextEditingController brandCtrl = TextEditingController();
    final TextEditingController volumeCtrl = TextEditingController();
    final TextEditingController priceCtrl = TextEditingController();
    final TextEditingController stockCtrl = TextEditingController(text: '0');
    int selectedVat = 21;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            'Přidat nový sud',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: brandCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Značka',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: volumeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Objem',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cena (Kč)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Skladem (ks)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<int>(
                  value: selectedVat,
                  decoration: const InputDecoration(
                    labelText: 'Sazba DPH',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 12, child: Text('12 % (Nealko)')),
                    DropdownMenuItem(value: 21, child: Text('21 % (Pivo)')),
                  ],
                  onChanged: (value) {
                    if (value != null) selectedVat = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ZRUŠIT', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                if (brandCtrl.text.isEmpty ||
                    volumeCtrl.text.isEmpty ||
                    priceCtrl.text.isEmpty)
                  return;
                Navigator.pop(ctx);
                try {
                  await apiService.createProduct({
                    'brand': brandCtrl.text,
                    'volume': volumeCtrl.text,
                    'price': double.parse(priceCtrl.text),
                    'current_stock': int.tryParse(stockCtrl.text) ?? 0,
                    'vat_rate': selectedVat,
                  });
                  _loadData();
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Produkt přidán!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Chyba: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                }
              },
              child: const Text('ULOŽIT'),
            ),
          ],
        );
      },
    );
  }

  // --- DIALOG PRO ÚPRAVU ---
  void _showEditProductDialog(BuildContext context, Product product) {
    final TextEditingController brandCtrl = TextEditingController(
      text: product.brand,
    );
    final TextEditingController volumeCtrl = TextEditingController(
      text: product.volume,
    );
    final TextEditingController priceCtrl = TextEditingController(
      text: product.price.toString(),
    );
    final TextEditingController stockCtrl = TextEditingController(
      text: product.currentStock.toString(),
    );
    int selectedVat = product.vatRate;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Upravit produkt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: brandCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Značka',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: volumeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Objem',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cena (Kč)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Skladem (ks)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<int>(
                  value: selectedVat,
                  decoration: const InputDecoration(
                    labelText: 'Sazba DPH',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 12, child: Text('12 % (Nealko)')),
                    DropdownMenuItem(value: 21, child: Text('21 % (Pivo)')),
                  ],
                  onChanged: (value) {
                    if (value != null) selectedVat = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ZRUŠIT', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await apiService.updateProduct(product.id, {
                    'brand': brandCtrl.text,
                    'volume': volumeCtrl.text,
                    'price': priceCtrl.text,
                    'current_stock': int.tryParse(stockCtrl.text) ?? 0,
                    'vat_rate': selectedVat,
                  });
                  _loadData();
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Upraveno!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Chyba: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                }
              },
              child: const Text('ULOŽIT'),
            ),
          ],
        );
      },
    );
  }
}
