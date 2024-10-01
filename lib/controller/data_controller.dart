import 'package:get_storage/get_storage.dart';
import 'package:pos_application/model/product_model.dart';
import 'package:pos_application/model/sale_model.dart';

class DataManager {
  final box = GetStorage();

  Future<void> saveProduct(ModelProduct product) async {
    List<dynamic> products = box.read('products') ?? [];
    products.add(product.toJson());
    await box.write('products', products);
  }

  List<ModelProduct> getProducts() {
    List<dynamic> productsJson = box.read('products') ?? [];
    return productsJson.map((json) => ModelProduct.fromJson(json)).toList();
  }

  ModelProduct? getProductById(String productId) {
    List<ModelProduct> products = getProducts();
    try {
      return products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProduct(ModelProduct updatedProduct) async {
    List<ModelProduct> products = getProducts();
    int index =
        products.indexWhere((product) => product.id == updatedProduct.id);
    if (index != -1) {
      products[index] = updatedProduct;
      await box.write('products', products.map((p) => p.toJson()).toList());
    } else {
      throw Exception('Product not found');
    }
  }

  Future<void> updateStock(String productId, int newStock) async {
    List<ModelProduct> products = getProducts();
    int index = products.indexWhere((product) => product.id == productId);
    if (index != -1) {
      products[index].stock = newStock;
      await box.write('products', products.map((p) => p.toJson()).toList());
    } else {
      throw Exception('Product not found');
    }
  }

  Future<void> saveSale(ModelSale sale) async {
    List<dynamic> sales = box.read('sales') ?? [];
    sales.add(sale.toJson());
    await box.write('sales', sales);
  }

  List<ModelSale> getSales() {
    List<dynamic> salesJson = box.read('sales') ?? [];
    return salesJson.map((json) => ModelSale.fromJson(json)).toList();
  }

  Future<void> clearAllData() async {
    await box.erase();
  }
}
