class Product {
  final int id;
  final String brand;
  final String volume;
  final String price; // Django DecimalField se v JSONu posílá jako String
  final int currentStock;
  final String barcode;
  final int vatRate;

  Product({
    required this.id,
    required this.brand,
    required this.volume,
    required this.price,
    required this.currentStock,
    required this.barcode,
    required this.vatRate,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      brand: json['brand'] ?? 'Neznámá značka',
      volume: json['volume'] ?? '',
      price: json['price']?.toString() ?? '0.00',
      currentStock: json['current_stock'] ?? 0,
      barcode: json['barcode'] ?? '',
      vatRate: json['vat_rate'] ?? 21,
    );
  }
}
