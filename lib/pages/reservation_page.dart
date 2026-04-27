import 'package:flutter/material.dart';
// Uprav si import podle tvé cesty v projektu (např. 'package:beer_stock/services/api_service.dart')
import '../services/api_service.dart';

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
  final TextEditingController emailController = TextEditingController();
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
        selectedPickupDate = date;
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
        customerEmail: emailController.text,
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
          // LEVÁ STRANA: SUDY
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
                                            if (cart.containsKey(prod.id)) {
                                              cart[prod.id]!['qty'] += 1;
                                            } else {
                                              cart[prod.id] = {
                                                'product': prod,
                                                'qty': 1,
                                              };
                                            }
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

          // PRAVÁ STRANA: KOŠÍK
          Expanded(
            flex: 1,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
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
                                      if (q > 1) {
                                        cart[entry.key]!['qty'] = q - 1;
                                      } else {
                                        cart.remove(entry.key);
                                      }
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
                                  onPressed: () => setState(
                                    () => cart[entry.key]!['qty'] = q + 1,
                                  ),
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
                          const SizedBox(width: 15),
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
                      const SizedBox(height: 15),
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
                          const SizedBox(width: 15),
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
