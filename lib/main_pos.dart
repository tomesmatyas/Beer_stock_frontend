import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'models/product.dart';
import 'services/api_service.dart';
import 'cubits/cart_cubit.dart'; // Náš nový Cubit
import 'restock_screen.dart';
import 'cubits/auth_cubit.dart';
import 'login_screen.dart';
import 'admin_dashboard.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit()),
        BlocProvider(create: (context) => CartCubit()),
      ],
      child: const PosApp(),
    ),
  );
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokladna',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state.isAuthenticated) {
            return const PosScreen();
          } else {
            return LoginScreen();
          }
        },
      ),
    );
  }
}

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Product>> futureProducts;

  int? selectedVat;
  String? selectedBrand;

  @override
  void initState() {
    super.initState();
    futureProducts = apiService.fetchProducts();
    //Skryje horní systémovou lištu (i tu dolní s tlačítky)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    //VYNUCENÍ ORIENTACE NA ŠÍŘKU (vlevo i vpravo)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // PŘI ODCHODU Z POKLADNY (např. odhlášení) vrátíme možnost rotace
    // Aby login screen mohl být zase na výšku i na šířku
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _handleScannedBarcode(String barcode) async {
    try {
      // Získáme aktuální seznam všech produktů ze skladu
      List<Product> allProducts = await futureProducts;

      // Zkusíme najít produkt podle čárového kódu
      // (Předpokládá, že jsi do modelu Product přidal atribut 'barcode')
      Product? foundProduct = allProducts
          .where((p) => p.barcode == barcode)
          .firstOrNull;

      if (foundProduct != null) {
        // Produkt nalezen -> Přidáme ho rovnou do košíku!
        if (context.mounted) {
          context.read<CartCubit>().addProduct(foundProduct);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Přidáno: ${foundProduct.brand}'),
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Produkt NENALEZEN -> Zeptáme se, jestli ho chce vytvořit
        if (context.mounted) {
          _showUnknownBarcodeDialog(barcode);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chyba při hledání produktu')),
        );
      }
    }
  }

  void _showUnknownBarcodeDialog(String barcode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neznámý čárový kód'),
        content: Text(
          'Kód $barcode není v databázi. Chcete přidat nový produkt?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ZRUŠIT', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Tady zavoláme funkci pro vytvoření nového produktu
              _createNewProductWithBarcode(barcode);
            },
            child: const Text('PŘIDAT DO DATABÁZE'),
          ),
        ],
      ),
    );
  }

  void _createNewProductWithBarcode(String barcode) {
    // 1. OKAMŽITĚ PŘEPNEME NA VÝŠKU
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    final TextEditingController brandCtrl = TextEditingController();
    final TextEditingController volumeCtrl = TextEditingController();
    final TextEditingController priceCtrl = TextEditingController();
    final TextEditingController stockCtrl = TextEditingController(text: '0');
    final _formKey = GlobalKey<FormState>();

    int selectedVat = 21;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // Použijeme PopScope (náhrada za WillPopScope), aby se orientace vrátila
        // i když uživatel použije hardwarové tlačítko "Zpět"
        return PopScope(
          canPop: false, // Zakážeme náhodné vyskočení
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            // Zde bychom mohli řešit návrat, ale v AlertDialogu to vyřešíme v tlačítkách
          },
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_box, color: Colors.blue),
                SizedBox(width: 10),
                Text('Nový produkt'),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey.shade200,
                      child: Text(
                        'EAN: $barcode',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: brandCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Značka',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Povinné' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: volumeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Objem',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Povinné' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cena (Kč)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Povinné' : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: selectedVat,
                      decoration: const InputDecoration(
                        labelText: 'Sazba DPH',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 12,
                          child: Text('12 % (Nealko / Jídlo)'),
                        ),
                        DropdownMenuItem(
                          value: 21,
                          child: Text('21 % (Pivo / Alkohol)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          selectedVat = value; // Uloží nově vybranou hodnotu
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Skladem (ks)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // 2. VRÁTÍME NA ŠÍŘKU PŘI ZRUŠENÍ
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.landscapeLeft,
                    DeviceOrientation.landscapeRight,
                  ]);
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'ZRUŠIT',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // 3. VRÁTÍME NA ŠÍŘKU PŘI ULOŽENÍ
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.landscapeLeft,
                      DeviceOrientation.landscapeRight,
                    ]);

                    Navigator.pop(ctx);

                    Map<String, dynamic> newProductData = {
                      'brand': brandCtrl.text,
                      'volume': volumeCtrl.text,
                      'price': priceCtrl.text,
                      'current_stock': int.tryParse(stockCtrl.text) ?? 0,
                      'barcode': barcode,
                      'vat_rate': selectedVat,
                    };

                    try {
                      await apiService.createProduct(newProductData);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Uloženo!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        setState(() {
                          futureProducts = apiService.fetchProducts();
                        });
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Chyba: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('ULOŽIT'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Pomocná funkce pro vykreslení obalu v košíku
  Widget _buildDepositItem(
    BuildContext context,
    String title,
    int qty,
    double price,
    VoidCallback onClear,
  ) {
    return ListTile(
      tileColor: Colors.amber.shade50,
      leading: const Icon(Icons.inventory_2, color: Colors.amber),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('$qty ks x ${price.abs()} Kč'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${(qty * price).toStringAsFixed(2)} Kč',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: price < 0 ? Colors.red : Colors.green,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }

  void _showDepositSheet(BuildContext context) {
    // Kontroler pro políčko, do kterého zadáváš libovolnou částku
    final TextEditingController customPriceCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return BlocProvider.value(
          value: context.read<CartCubit>(),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'OBALY',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Základní obaly
                  _buildSimpleRow(
                    context,
                    'SUDY (1000 Kč)',
                    () => context.read<CartCubit>().addKeg(false),
                    () => context.read<CartCubit>().addKeg(true),
                  ),
                  _buildSimpleRow(
                    context,
                    'BEDNY (100 Kč)',
                    () => context.read<CartCubit>().addCrate(false),
                    () => context.read<CartCubit>().addCrate(true),
                  ),
                  _buildSimpleRow(
                    context,
                    'LAHVE (3 Kč)',
                    () => context.read<CartCubit>().addBottle(false),
                    () => context.read<CartCubit>().addBottle(true),
                  ),

                  const Divider(height: 30),

                  // Rychlé volby pro plné bedny (tlačítka pro 160 a 172)
                  _buildSimpleRow(
                    context,
                    'BEDNA (160 Kč)',
                    () => context.read<CartCubit>().addFullCrate(20, false),
                    () => context.read<CartCubit>().addFullCrate(20, true),
                  ),
                  _buildSimpleRow(
                    context,
                    'BEDNA (172 Kč)',
                    () => context.read<CartCubit>().addFullCrate(24, false),
                    () => context.read<CartCubit>().addFullCrate(24, true),
                  ),

                  const Divider(height: 30),

                  // ZCELA NOVÉ: Políčko pro zadání libovolné částky
                  const Text(
                    'SPECIÁLNÍ OBAL (Kč/ks)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customPriceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Zadej částku',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                          size: 45,
                        ),
                        tooltip: 'Vrátit speciální',
                        onPressed: () {
                          double? val = double.tryParse(customPriceCtrl.text);
                          if (val != null && val > 0)
                            context.read<CartCubit>().addCustom(val, false);
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: Colors.green,
                          size: 45,
                        ),
                        tooltip: 'Půjčit speciální',
                        onPressed: () {
                          double? val = double.tryParse(customPriceCtrl.text);
                          if (val != null && val > 0)
                            context.read<CartCubit>().addCustom(val, true);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('ZAVŘÍT'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimpleRow(
    BuildContext context,
    String label,
    VoidCallback onMinus,
    VoidCallback onPlus,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.red, size: 35),
            onPressed: onMinus,
          ),
          const SizedBox(width: 15),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.green, size: 35),
            onPressed: onPlus,
          ),
        ],
      ),
    );
  }

  Widget _buildDepRow(
    BuildContext context,
    String label,
    int rent,
    int ret,
    Function(int) onR,
    Function(int) onRet,
  ) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => onR(-1),
        ),
        Text('$rent'),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => onR(1),
        ),
        const SizedBox(width: 10),
        const Text('|'),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => onRet(-1),
        ),
        Text('$ret'),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => onRet(1),
        ),
      ],
    );
  }

  // 1. Funkce pro simulaci tisku (vyskočí okno s náhledem účtenky)
  void _printOrder(dynamic order) {
    // 1. Výpočet DPH z položek
    double vat21Base = 0, vat21Tax = 0, vat21Total = 0;
    double vat12Base = 0, vat12Tax = 0, vat12Total = 0;

    for (var item in order['items']) {
      double price = double.tryParse(item['price'].toString()) ?? 0;
      int qty = item['quantity'] as int;
      double lineTotal = price * qty;

      // Zkusíme načíst sazbu DPH z dat. Pokud tam chybí, počítáme s 21%.
      int vatRate = item['vat_rate'] ?? 21;

      if (vatRate == 21) {
        vat21Total += lineTotal;
        vat21Base += lineTotal / 1.21;
        vat21Tax += lineTotal - (lineTotal / 1.21);
      } else if (vatRate == 12) {
        vat12Total += lineTotal;
        vat12Base += lineTotal / 1.12;
        vat12Tax += lineTotal - (lineTotal / 1.12);
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ), // Ostré rohy jako papír
        child: Container(
          width: 350, // Fixní šířka, aby to vypadalo jako účtenka
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: SingleChildScrollView(
            // Kdyby byla účtenka moc dlouhá
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HLAVIČKA ÚČTENKY
                const Text(
                  'DOKLAD O PRODEJI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Účtenka č.: ${order['receipt_number'] ?? order['id']}',
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  'Datum: ${order['created_at']}',
                  style: const TextStyle(fontSize: 13),
                ),

                const Divider(
                  color: Colors.black87,
                  thickness: 1.5,
                  height: 25,
                ),

                // SEZNAM POLOŽEK
                ...(order['items'] as List).map((i) {
                  double p = double.tryParse(i['price'].toString()) ?? 0;
                  int q = i['quantity'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${q}x ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(child: Text('${i['brand']}')),
                        Text('${(p * q).toStringAsFixed(2)} Kč'),
                      ],
                    ),
                  );
                }),

                const Divider(
                  color: Colors.black87,
                  thickness: 1.5,
                  height: 25,
                ),

                // CELKOVÁ ČÁSTKA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CELKEM',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${order['total_amount']} Kč',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // REKAPITULACE DPH (Zobrazí se jen ty sazby, které byly na účtence)
                const Text(
                  'Rekapitulace DPH',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 5),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Sazba',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Základ',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'DPH',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Celkem',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                if (vat21Total > 0)
                  _buildVatRow('21 %', vat21Base, vat21Tax, vat21Total),
                if (vat12Total > 0)
                  _buildVatRow('12 %', vat12Base, vat12Tax, vat12Total),

                const SizedBox(height: 30),

                // TLAČÍTKO PRO ZAVŘENÍ
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueGrey,
                      side: const BorderSide(color: Colors.blueGrey),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('ZAVŘÍT NÁHLED'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Pomocný widget pro vykreslení řádku v tabulce DPH
  Widget _buildVatRow(String label, double base, double tax, double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              base.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              tax.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              total.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Dialog se seznamem všech účtenek
  void _showOrdersHistoryDialog(BuildContext context) {
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
                      onPressed: () => _printOrder(order),
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

  // OPRAVA 1: Funkce přesunuta SEM, kde zná apiService a futureProducts!
  void _showPendingOrdersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            'Čekající rezervace',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: SizedBox(
            width: double.maxFinite,
            height:
                400, // Zaručí, že u mnoha položek začne fungovat scrollování
            child: FutureBuilder<List<dynamic>>(
              future: apiService.fetchPendingOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Chyba: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Žádné čekající rezervace.'));
                }

                final orders = snapshot.data!;
                // PŘIDÁNO: Scrollbar a změna na ListView.separated pro lepší vzhled
                return Scrollbar(
                  thumbVisibility: true, // Zobrazí posuvník vždy
                  child: ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (context, index) =>
                        const Divider(), // Oddělovací čára
                    itemBuilder: (context, index) {
                      final order = orders[index];

                      // 1. Zpracování a hezké formátování data
                      String niceDate = "Nezadáno";
                      if (order['pickup_date'] != null) {
                        try {
                          DateTime d = DateTime.parse(order['pickup_date']);
                          niceDate =
                              "${d.day}. ${d.month}."; // Vypíše např. "1. 5."
                        } catch (e) {
                          niceDate = order['pickup_date'];
                        }
                      }

                      // 2. Sestavení sudů do jednoho textu pro podnadpis
                      List<dynamic> items = order['items'] ?? [];
                      String itemsSummary = items
                          .map(
                            (i) =>
                                "${i['quantity']}x ${i['brand']} ${i['volume']}",
                          )
                          .join(', ');

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        leading: const CircleAvatar(
                          backgroundColor: Colors.amber,
                          child: Icon(Icons.person, color: Colors.black87),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                order['customer'] ?? 'Neznámý',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'Vyzvednutí: $niceDate',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            itemsSummary.isNotEmpty
                                ? itemsSummary
                                : 'Žádné sudy',
                            maxLines:
                                1, // Zaručí, že to bude vždy jen na 1 řádek
                            overflow: TextOverflow
                                .ellipsis, // Tečky, pokud je text moc dlouhý
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${double.parse(order['total_amount'].toString()).toStringAsFixed(0)} Kč',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 30,
                              ),
                              onPressed: () async {
                                // --- TVOJE PŮVODNÍ LOGIKA PRO NAČTENÍ DO KOŠÍKU ---
                                List<Product> allProducts =
                                    await futureProducts;
                                List<CartItem> itemsToLoad = [];

                                for (var item in order['items']) {
                                  Product? p = allProducts
                                      .where(
                                        (prod) =>
                                            prod.id.toString() ==
                                            item['product_id'].toString(),
                                      )
                                      .firstOrNull;
                                  if (p != null) {
                                    itemsToLoad.add(
                                      CartItem(
                                        product: p,
                                        quantity: item['quantity'],
                                      ),
                                    );
                                  }
                                }

                                if (context.mounted) {
                                  context.read<CartCubit>().loadReservation(
                                    order['id'],
                                    itemsToLoad,
                                  );
                                  Navigator.of(context).pop(); // Zavřeme dialog
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ZAVŘÍT', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Zjistíme šířku displeje. Pokud je menší než 800, bereme to jako mobil.
    bool isSmallScreen = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🍺 Pokladna'),
        actions: [
          // Zachováme všechna tvá funkční tlačítka v AppBaru
          if (context.read<AuthCubit>().state.role == 'ADMIN')
            IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Colors.blueGrey),
              tooltip: 'Skenovat čárový kód',
              onPressed: () async {
                var res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SimpleBarcodeScannerPage(),
                  ),
                );
                if (res is String && res != '-1') {
                  _handleScannedBarcode(res);
                }
              },
            ),
          if (context.read<AuthCubit>().state.role == 'ADMIN')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.amber),
              tooltip: 'Admin menu',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminDashboard()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.local_shipping, color: Colors.blueGrey),
            tooltip: 'Příjem zboží (Naskladnění)',
            onPressed: () async {
              final didRestock = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RestockScreen()),
              );
              if (didRestock == true) {
                setState(() {
                  futureProducts = apiService.fetchProducts();
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.blueGrey),
            tooltip: 'Historie účtenek',
            onPressed: () => _showOrdersHistoryDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download, color: Colors.blueGrey),
            tooltip: 'Čekající rezervace',
            onPressed: () => _showPendingOrdersDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                futureProducts = apiService.fetchProducts();
              });
            },
          ),
          const VerticalDivider(
            color: Colors.white24,
            indent: 10,
            endIndent: 10,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.blueGrey),
            tooltip: 'Odhlásit se',
            onPressed: () {
              context.read<AuthCubit>().logout();
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: isSmallScreen
            // A) MOBILNÍ ROZLOŽENÍ: Jen produkty přes celou šířku
            ? buildProductGrid()
            // B) TABLETOVÉ ROZLOŽENÍ: Produkty a košík vedle sebe
            : Row(
                children: [
                  Expanded(flex: 5, child: buildProductGrid()),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Colors.grey,
                  ),
                  Expanded(flex: 4, child: buildCartPanel()),
                ],
              ),
      ),
      // 2. Plovoucí tlačítko košíku - zobrazí se pouze na mobilu
      floatingActionButton: isSmallScreen
          ? BlocBuilder<CartCubit, CartState>(
              builder: (context, state) {
                // Spočítáme celkový počet kusů v košíku pro ikonku (Badge)
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
                      // Otevře košík v panelu vysunutém zespodu
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (ctx) => BlocProvider.value(
                          value: context.read<CartCubit>(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.9,
                            child: buildCartPanel(),
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

  Widget buildProductGrid() {
    // Zjistíme dostupnou šířku pro Grid
    double screenWidth = MediaQuery.of(context).size.width;

    // Dynamické nastavení šířky dlaždice:
    // Na velkém tabletu (landscape) chceme dlaždice cca 180px široké,
    // na mobilu klidně 140px, aby se vešly aspoň dvě vedle sebe.
    double maxTileWidth = screenWidth > 900 ? 180 : 140;

    return FutureBuilder<List<Product>>(
      future: futureProducts,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        List<Product> allProducts = snapshot.data!;

        // 1. ÚROVEŇ: HLAVNÍ ROZCESTNÍK (PIVO vs NEALKO)
        // Tady necháme dlaždice větší, jsou jen dvě.
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
                () {
                  setState(() => selectedVat = 21);
                },
              ),
              _buildCategoryCard(
                'NEALKO / JÍDLO\n(12%)',
                Icons.fastfood,
                Colors.green.shade700,
                () {
                  setState(() => selectedVat = 12);
                },
              ),
            ],
          );
        }

        // Filtrujeme produkty podle DPH
        List<Product> filteredByVat = allProducts
            .where((p) => p.vatRate == selectedVat)
            .toList();
        List<String> brands = filteredByVat
            .map((p) => p.brand)
            .toSet()
            .toList();

        // 2. ÚROVEŇ: VÝBĚR ZNAČKY
        if (selectedBrand == null) {
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxTileWidth,
              childAspectRatio: 1.3, // Kompaktnější tvar
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
                () {
                  setState(() => selectedBrand = brand);
                },
                compact: true,
              );
            },
          );
        }

        // 3. ÚROVEŇ: KONKRÉTNÍ POLOŽKY
        List<Product> finalProducts = filteredByVat
            .where((p) => p.brand == selectedBrand)
            .toList();

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxTileWidth,
            childAspectRatio: 1.1, // Téměř čtverec pro víc informací
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: finalProducts.length + 1,
          itemBuilder: (ctx, index) {
            if (index == 0)
              return _buildBackCard(() => setState(() => selectedBrand = null));
            final product = finalProducts[index - 1];
            return _buildProductCard(product);
          },
        );
      },
    );
  }

  // --- KOMPAKTNÍ POMOCNÉ WIDGETY ---

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
                overflow: TextOverflow.ellipsis,
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
    bool isOutOfStock = product.currentStock <= 0; // Kontrola, zda je vyprodáno
    bool isLowStock = product.currentStock > 0 && product.currentStock < 5;

    return Card(
      // Pokud je vyprodáno, kartička bude šedá a bez stínu
      elevation: isOutOfStock ? 0 : 2,
      color: isOutOfStock ? Colors.grey.shade200 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isOutOfStock
            ? BorderSide(color: Colors.grey.shade300)
            : BorderSide.none,
      ),
      child: InkWell(
        // KOUZLO: Pokud je vyprodáno, onTap je 'null' (tlačítko nereaguje)
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
                  color: isOutOfStock
                      ? Colors.grey.shade600
                      : Colors.black, // Šedý text
                  decoration: isOutOfStock
                      ? TextDecoration.lineThrough
                      : null, // Přeškrtnutí názvu
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
                '${product.price} Kc',
                style: TextStyle(
                  color: isOutOfStock ? Colors.grey.shade500 : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              // Zvýrazněný text "VYPRODÁNO"
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

  Widget buildCartPanel() {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final sign = state.isRefundMode ? "-" : "";

        return Column(
          children: [
            // HLAVIČKA KOŠÍKU S PŘEPÍNAČEM
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: state.isRefundMode
                  ? Colors.red.shade100
                  : Colors.blue.shade50,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    state.isRefundMode ? '🔴 REŽIM VRATKY' : 'Aktuální účtenka',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: state.isRefundMode
                          ? Colors.red.shade900
                          : Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      const Text('Vratka'),
                      Switch(
                        value: state.isRefundMode,
                        activeColor: Colors.red,
                        onChanged: state.loadedOrderId != null
                            ? null
                            : (val) {
                                context.read<CartCubit>().toggleRefundMode();
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // VÝPIS POLOŽEK ZBOŽÍ
            Expanded(
              child:
                  (state.items.isEmpty &&
                      state.kegsRented == 0 &&
                      state.kegsReturned == 0 &&
                      state.cratesRented == 0 &&
                      state.cratesReturned == 0 &&
                      state.bottlesRented == 0 &&
                      state.bottlesReturned == 0 &&
                      state.customRented.isEmpty &&
                      state.customReturned.isEmpty)
                  ? Center(
                      child: Text(
                        state.isRefundMode
                            ? 'Vyberte sudy k vrácení'
                            : 'Účtenka je prázdná',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView(
                      children: [
                        // 1. VÝPIS PIVA
                        ...state.items.map(
                          (item) => ListTile(
                            title: Text(
                              '${item.product.brand} ${item.product.volume}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${state.isRefundMode ? "-" : ""}${item.quantity}x ${item.product.price} Kč',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${state.isRefundMode ? "-" : ""}${item.totalPrice.toStringAsFixed(2)} Kč',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: state.isRefundMode
                                        ? Colors.red
                                        : Colors.black,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => context
                                      .read<CartCubit>()
                                      .removeProduct(item.product),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 2. VÝPIS OBALŮ (Každý má svou vlastní funkci na smazání!)
                        if (state.kegsRented > 0)
                          _buildDepositItem(
                            context,
                            'Půjčený sud',
                            state.kegsRented,
                            1000.0,
                            () => context.read<CartCubit>().clearKegsRented(),
                          ),
                        if (state.kegsReturned > 0)
                          _buildDepositItem(
                            context,
                            'Vrácený sud',
                            state.kegsReturned,
                            -1000.0,
                            () => context.read<CartCubit>().clearKegsReturned(),
                          ),

                        if (state.cratesRented > 0)
                          _buildDepositItem(
                            context,
                            'Půjčená bedna',
                            state.cratesRented,
                            100.0,
                            () => context.read<CartCubit>().clearCratesRented(),
                          ),
                        if (state.cratesReturned > 0)
                          _buildDepositItem(
                            context,
                            'Vrácená bedna',
                            state.cratesReturned,
                            -100.0,
                            () =>
                                context.read<CartCubit>().clearCratesReturned(),
                          ),

                        if (state.bottlesRented > 0)
                          _buildDepositItem(
                            context,
                            'Půjčená lahev',
                            state.bottlesRented,
                            3.0,
                            () =>
                                context.read<CartCubit>().clearBottlesRented(),
                          ),
                        if (state.bottlesReturned > 0)
                          _buildDepositItem(
                            context,
                            'Vrácená lahev',
                            state.bottlesReturned,
                            -3.0,
                            () => context
                                .read<CartCubit>()
                                .clearBottlesReturned(),
                          ),

                        // 3. VÝPIS SPECIÁLNÍCH OBALŮ
                        ...state.customRented.entries.map(
                          (e) => _buildDepositItem(
                            context,
                            'Půjčené spec. (${e.key} Kč)',
                            e.value,
                            e.key,
                            () => context.read<CartCubit>().removeCustomRented(
                              e.key,
                            ),
                          ),
                        ),
                        ...state.customReturned.entries.map(
                          (e) => _buildDepositItem(
                            context,
                            'Vrácené spec. (${e.key} Kč)',
                            e.value,
                            -e.key,
                            () => context
                                .read<CartCubit>()
                                .removeCustomReturned(e.key),
                          ),
                        ),
                      ],
                    ),
            ),

            // PATIČKA: OBALY, CELKOVÁ CENA A TLAČÍTKA
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                children: [
                  // --- TADY JE TO NOVÉ TLAČÍTKO MÍSTO STARÝCH OVLADAČŮ ---
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton.icon(
                      onPressed: () => _showDepositSheet(context),
                      icon: const Icon(Icons.inventory_2),
                      label: Text(
                        'OBALY (Sudy: ${state.kegsRented + state.kegsReturned}, Bedny: ${state.cratesRented + state.cratesReturned})',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        foregroundColor: Colors.blueGrey,
                      ),
                    ),
                  ),

                  // ------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        state.isRefundMode || state.finalTotalAmount < 0
                            ? 'Celkem vracet:'
                            : 'Celkem k úhradě:',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${state.finalTotalAmount.toStringAsFixed(2)} Kč',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: state.finalTotalAmount < 0
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          onPressed: () =>
                              context.read<CartCubit>().clearCart(),
                          child: FittedBox(
                            // <--- Přidáno
                            fit: BoxFit.scaleDown,
                            child: Text(
                              state.loadedOrderId != null
                                  ? 'ODLOŽIT'
                                  : 'VYMAZAT',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            backgroundColor:
                                state.isRefundMode || state.finalTotalAmount < 0
                                ? Colors.red
                                : Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed:
                              (state.items.isEmpty &&
                                  state.kegsRented == 0 &&
                                  state.kegsReturned == 0 &&
                                  state.cratesRented == 0 &&
                                  state.cratesReturned == 0 &&
                                  state.bottlesRented == 0 &&
                                  state.bottlesReturned == 0 &&
                                  state.customRented.isEmpty &&
                                  state.customReturned.isEmpty)
                              ? null
                              : () async {
                                  final authState = context
                                      .read<AuthCubit>()
                                      .state;
                                  final userId = authState.userId ?? 1;

                                  try {
                                    if (state.isRefundMode) {
                                      // 🔴 SCÉNÁŘ: VRATKA ZBOŽÍ
                                      final refundItems = state.items
                                          .map(
                                            (i) => {
                                              "product_id": i.product.id,
                                              "quantity": i.quantity,
                                            },
                                          )
                                          .toList();

                                      await apiService.refundOrder(
                                        refundItems,
                                        state.finalTotalAmount,
                                      );

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Vratka úspěšná!'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } else if (state.loadedOrderId != null) {
                                      // 🔵 SCÉNÁŘ: REZERVACE
                                      await apiService.fulfillOrder(
                                        state.loadedOrderId!,
                                        state.items,
                                        state.finalTotalAmount,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Rezervace vyřízena!',
                                            ),
                                          ),
                                        );
                                      }
                                    } else {
                                      // 🟢 SCÉNÁŘ: BĚŽNÝ PRODEJ Z ULICE
                                      await apiService.createOrder(
                                        state.items,
                                        state.finalTotalAmount,
                                        state.kegsRented,
                                        state.kegsReturned,
                                        userId,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Prodej úspěšně dokončen!',
                                            ),
                                          ),
                                        );
                                      }
                                    }

                                    // Úklid po úspěchu
                                    if (context.mounted) {
                                      context.read<CartCubit>().clearCart();
                                      setState(() {
                                        futureProducts = apiService
                                            .fetchProducts();
                                      });
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Chyba: $e')),
                                      );
                                    }
                                  }
                                },
                          child: FittedBox(
                            // <--- Přidáno
                            fit: BoxFit.scaleDown,
                            child: Text(
                              state.isRefundMode || state.finalTotalAmount < 0
                                  ? 'PROVÉST VRATKU'
                                  : 'DOKONČIT PRODEJ',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
