class ModelProduct {
  final String id;
  final String name;
  final double price;
  int stock;

  ModelProduct(
      {required this.id,
      required this.name,
      required this.price,
      required this.stock});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'stock': stock,
      };

  factory ModelProduct.fromJson(Map<String, dynamic> json) => ModelProduct(
        id: json['id'],
        name: json['name'],
        price: json['price'],
        stock: json['stock'],
      );
}
