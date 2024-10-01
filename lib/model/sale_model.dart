class ModelSale {
  final String id;
  final DateTime date;
  final List<SaleItem> items;
  final double total;

  ModelSale(
      {required this.id,
      required this.date,
      required this.items,
      required this.total});

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
        'total': total,
      };

  factory ModelSale.fromJson(Map<String, dynamic> json) => ModelSale(
        id: json['id'],
        date: DateTime.parse(json['date']),
        items: (json['items'] as List)
            .map((item) => SaleItem.fromJson(item))
            .toList(),
        total: json['total'],
      );
}

class SaleItem {
  final String productId;
  final int quantity;
  final double price;

  SaleItem(
      {required this.productId, required this.quantity, required this.price});

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'quantity': quantity,
        'price': price,
      };

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
        productId: json['productId'],
        quantity: json['quantity'],
        price: json['price'],
      );
}
