import 'package:flutter/material.dart';
import 'package:beer_stock/services/api_service.dart';
import 'dart:async';

void main() {
  runApp(const ZazemiWebApp());
}

// --- GLOBÁLNÍ DATA ---
List<Map<String, String>> newsPosts = [
  {
    "title": "Otevíráme novou sezónu!",
    "date": "28. 04. 2026",
    "content":
        "Vítejte na našem novém webu. Sudy jsou plné, chlaďáky běží. Udělejte si rezervaci ještě dnes!",
  },
];

class ZazemiWebApp extends StatelessWidget {
  const ZazemiWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pivní Sklad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WebLayout(child: HomePage()),
        '/kontakt': (context) => const WebLayout(child: ContactPage()),
        '/rezervace': (context) => const WebLayout(child: ReservationPage()),
        '/login': (context) => const WebLayout(child: AdminLoginPage()),
        '/admin-editor': (context) => const WebLayout(child: AdminEditorPage()),
      },
    );
  }
}

// --- HLAVNÍ OBAL STRÁNKY S MENU ---
class WebLayout extends StatelessWidget {
  final Widget child;
  const WebLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        toolbarHeight: 80,
        title: InkWell(
          onTap: () => Navigator.pushReplacementNamed(context, '/'),
          child: const Row(
            children: [
              Text('🍺 ', style: TextStyle(fontSize: 30)),
              Text(
                'PIVNÍ SKLAD',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            child: const Text(
              'DOMŮ & NOVINKY',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/kontakt'),
            child: const Text(
              'KONTAKT',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(width: 20),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 20.0,
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                elevation: 5,
                padding: const EdgeInsets.symmetric(horizontal: 30),
              ),
              onPressed: () => Navigator.pushNamed(context, '/rezervace'),
              child: const Text(
                'REZERVOVAT SUDY',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.grey),
            tooltip: 'Pro správce',
            onPressed: () => Navigator.pushNamed(context, '/login'),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: child,
    );
  }
}

// --- 1. ÚVODNÍ STRÁNKA (Karusel + Novinky) ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(
            height: 400,
            width: double.infinity,
            child: ImageCarousel(),
          ),
          const SizedBox(height: 40),
          const Text(
            'AKTUALITY A NOVINKY',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: newsPosts.length,
              itemBuilder: (context, index) {
                final post = newsPosts[newsPosts.length - 1 - index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['title']!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          post['date']!,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const Divider(height: 30, thickness: 1),
                        Text(
                          post['content']!,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

// --- KOMPONENTA: ROTUJÍCÍ KARUSEL ---
class ImageCarousel extends StatefulWidget {
  const ImageCarousel({super.key});

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<String> images = [
    'https://images.unsplash.com/photo-1600788886242-5c96aabe3757?q=80&w=1200&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1575037614876-c385806ac5b0?q=80&w=1200&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1505075936528-912a76f2df79?q=80&w=1200&auto=format&fit=crop',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < images.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemBuilder: (context, index) {
            return Image.network(
              images[index],
              fit: BoxFit.cover,
              width: double.infinity,
            );
          },
        ),
        Container(color: Colors.black.withOpacity(0.4)),
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'NEJLEPŠÍ PIVNÍ SKLAD V OKOLÍ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Sudy připravené k okamžité rezervaci.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- 2. KONTAKT ---
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Kontakt a Otevírací doba',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text('📍 Adresa: Lično 123', style: TextStyle(fontSize: 20)),
          Text('📞 Telefon: +420 123 456 789', style: TextStyle(fontSize: 20)),
          SizedBox(height: 40),
          Text(
            'Otevřeno pátky a soboty dle domluvy.',
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

// --- 3. REZERVAČNÍ STRÁNKA (Pivo + Kalendář + Email + Košík) ---
class ReservationPage extends StatefulWidget {
  const ReservationPage({super.key});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  final ApiService apiService = ApiService();
  Map<String, List<dynamic>> groupedProducts = {};
  bool isLoading = true;

  Map<int, Map<String, dynamic>> cart = {};

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController(); // NOVÉ
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController assocController = TextEditingController();
  DateTime? selectedPickupDate;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await apiService.fetchProducts();
      final beers = products.where((p) => p.vatRate == 21).toList();

      Map<String, List<dynamic>> grouped = {};
      for (var p in beers) {
        if (!grouped.containsKey(p.brand)) grouped[p.brand] = [];
        grouped[p.brand]!.add(p);
      }

      setState(() {
        groupedProducts = grouped;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Chyba: $e')));
      }
    }
  }

  double get cartTotal {
    double total = 0;
    cart.forEach((id, data) {
      total +=
          double.parse(data['product'].price.toString()) * (data['qty'] as int);
    });
    return total;
  }

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _getNextFriday(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.amber),
        ),
        child: child!,
      ),
      selectableDayPredicate: (DateTime val) =>
          val.weekday == 5 || val.weekday == 6,
    );

    if (date != null && context.mounted) {
      setState(() {
        selectedPickupDate = date; // Uložíme pouze datum, čas už neřešíme
      });
    }
  }

  DateTime _getNextFriday() {
    DateTime now = DateTime.now();
    int daysUntilFriday = (5 - now.weekday) % 7;
    if (daysUntilFriday < 0) daysUntilFriday += 7;
    return now.add(Duration(days: daysUntilFriday));
  }

  void _submitReservation() async {
    if (cart.isEmpty ||
        nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        selectedPickupDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vyberte sudy, jméno, e-mail a datum vyzvednutí!'),
        ),
      );
      return;
    }

    List<Map<String, dynamic>> itemsForDjango = [];
    cart.forEach((id, data) {
      itemsForDjango.add({"product_id": id, "quantity": data['qty']});
    });

    try {
      await apiService.submitWebReservation(
        items: itemsForDjango,
        totalAmount: cartTotal,
        customerName: nameController.text,
        customerEmail: emailController.text, // NOVÉ
        customerPhone: phoneController.text,
        associationName: assocController.text,
        pickupDate: selectedPickupDate!.toIso8601String(),
      );

      setState(() {
        cart.clear();
        nameController.clear();
        emailController.clear();
        phoneController.clear();
        assocController.clear();
        selectedPickupDate = null;
      });

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('🎉 Rezervace odeslána!'),
            content: const Text(
              'Potvrzení ti právě letí do e-mailu. Budeme se těšit!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ZAVŘÍT'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- LEVÁ STRANA: SUDY ---
          Expanded(
            flex: 2,
            child: groupedProducts.isEmpty
                ? const Center(child: Text("Žádná piva nebyla nalezena."))
                : ListView.builder(
                    itemCount: groupedProducts.keys.length,
                    itemBuilder: (context, index) {
                      String categoryBrand = groupedProducts.keys.elementAt(
                        index,
                      );
                      List<dynamic> categoryProducts =
                          groupedProducts[categoryBrand]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 20.0,
                              bottom: 10.0,
                            ),
                            child: Text(
                              categoryBrand,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 250,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                  childAspectRatio: 0.85,
                                ),
                            itemCount: categoryProducts.length,
                            itemBuilder: (context, idx) {
                              final prod = categoryProducts[idx];
                              return Card(
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.sports_bar,
                                        size: 50,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        '${prod.volume}',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${prod.price} Kč',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.add),
                                        label: const Text('Přidat'),
                                        onPressed: () {
                                          setState(() {
                                            if (cart.containsKey(prod.id))
                                              cart[prod.id]!['qty'] += 1;
                                            else
                                              cart[prod.id] = {
                                                'product': prod,
                                                'qty': 1,
                                              };
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          const Divider(thickness: 1, color: Colors.grey),
                        ],
                      );
                    },
                  ),
          ),
          const SizedBox(width: 32),

          // --- PRAVÁ STRANA: KOŠÍK ---
          Expanded(
            flex: 1,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                // --- TADY JE TA ZMĚNA: Přidán SingleChildScrollView ---
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Váš košík',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(thickness: 2),

                      if (cart.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Zatím jste nevybrali žádné sudy.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ...cart.entries.map((entry) {
                          final p = entry.value['product'];
                          final q = entry.value['qty'];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${p.brand} ${p.volume}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (q > 1)
                                        cart[entry.key]!['qty'] = q - 1;
                                      else
                                        cart.remove(entry.key);
                                    });
                                  },
                                ),
                                Text(
                                  '$q ks',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () => cart[entry.key]!['qty'] = q + 1,
                                    );
                                  },
                                ),
                              ],
                            ),
                            trailing: Text(
                              '${(double.parse(p.price.toString()) * q).toStringAsFixed(2)} Kč',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }),

                      const Divider(thickness: 2),
                      Text(
                        'CELKEM: ${cartTotal.toStringAsFixed(2)} Kč',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 30),

                      const Text(
                        'Údaje a vyzvednutí',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      InkWell(
                        onTap: _pickDateTime,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  selectedPickupDate == null
                                      ? 'Který den si sudy vyzvednete? *'
                                      : 'Vyzvednutí: ${selectedPickupDate!.day}. ${selectedPickupDate!.month}. ${selectedPickupDate!.year}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: selectedPickupDate != null
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Jméno a Příjmení *',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15), // Mezera mezi políčky
                          Expanded(
                            child: TextField(
                              controller: emailController,
                              decoration: const InputDecoration(
                                labelText: 'E-mail pro potvrzení *',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15), // Mezera mezi řádky
                      // --- DRUHÝ ŘÁDEK: Telefon a Spolek vedle sebe ---
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Telefon',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15), // Mezera mezi políčky
                          Expanded(
                            child: TextField(
                              controller: assocController,
                              decoration: const InputDecoration(
                                labelText: 'Spolek / SDH (volitelné)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                        ),
                        onPressed: _submitReservation,
                        child: const Text(
                          'ODESLAT REZERVACI',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 4. ADMIN LOGIN ---
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final ApiService apiService = ApiService();
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  void _login() async {
    try {
      final response = await apiService.login(userCtrl.text, passCtrl.text);
      if (response != null && response['role'] == 'ADMIN') {
        if (context.mounted)
          Navigator.pushReplacementNamed(context, '/admin-editor');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Přístup odepřen. Nemáte roli ADMIN.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Chyba spojení: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.admin_panel_settings,
              size: 60,
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 20),
            const Text(
              'Přihlášení správce',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(
                labelText: 'Jméno',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Heslo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: _login,
              child: const Text('PŘIHLÁSIT SE'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 5. ADMIN EDITOR PŘÍSPĚVKŮ ---
class AdminEditorPage extends StatefulWidget {
  const AdminEditorPage({super.key});

  @override
  State<AdminEditorPage> createState() => _AdminEditorPageState();
}

class _AdminEditorPageState extends State<AdminEditorPage> {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController contentCtrl = TextEditingController();

  void _savePost() {
    if (titleCtrl.text.isEmpty || contentCtrl.text.isEmpty) return;

    setState(() {
      newsPosts.add({
        "title": titleCtrl.text,
        "date": "Dnes",
        "content": contentCtrl.text,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Příspěvek zveřejněn!'),
        backgroundColor: Colors.green,
      ),
    );
    titleCtrl.clear();
    contentCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(32),
        child: Card(
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Napsat nový příspěvek na web',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      label: Text('ADMIN REŽIM'),
                      backgroundColor: Colors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Nadpis příspěvku',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: contentCtrl,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText:
                        'Text příspěvku (aktuality, slevy, otevírací doba...)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/'),
                      child: const Text('Zpět na web'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 20,
                        ),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.publish),
                      label: const Text(
                        'ZVEŘEJNIT NA WEBU',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _savePost,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
