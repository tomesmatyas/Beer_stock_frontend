class ProductCategory {
  final int id;
  final String name;
  final String slug;
  final ProductCategory? parent;

  ProductCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.parent,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['title'] ?? 'Nezařazeno',
      slug: json['slug'] ?? '',
      parent: json['parent'] is Map<String, dynamic>
          ? ProductCategory.fromJson(json['parent'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      if (parent != null) 'parent': parent!.toJson(),
    };
  }

  String get displayName {
    // Build full ancestor chain: Root > ... > This
    List<String> parts = [name];
    ProductCategory? p = parent;
    while (p != null) {
      if (p.name.isNotEmpty) parts.insert(0, p.name);
      p = p.parent;
    }
    return parts.join(' > ');
  }
}

class Product {
  final int id;
  final String brand;
  final String volume;
  final String price; // Django DecimalField se v JSONu posílá jako String
  final int currentStock;
  final String barcode;
  final int vatRate;
  final ProductCategory? category;
  final bool isOnOrder;

  Product({
    required this.id,
    required this.brand,
    required this.volume,
    required this.price,
    required this.currentStock,
    required this.barcode,
    required this.vatRate,
    this.category,
    this.isOnOrder = false,
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
      category: _parseCategory(json['category']),
      isOnOrder: json['is_on_order'] ?? false,
    );
  }

  static ProductCategory? _parseCategory(dynamic json) {
    if (json == null) return null;
    if (json is Map<String, dynamic>) {
      return ProductCategory.fromJson(json);
    }
    if (json is String) {
      return ProductCategory(id: 0, name: json, slug: '');
    }
    if (json is int) {
      return ProductCategory(id: json, name: 'Nezařazeno', slug: '');
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'volume': volume,
      'price': price,
      'current_stock': currentStock,
      'barcode': barcode,
      'vat_rate': vatRate,
      if (category != null) 'category': category!.id,
      'is_on_order': isOnOrder,
    };
  }
}
