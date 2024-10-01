import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pos_application/model/product_model.dart';
import 'package:pos_application/model/sale_model.dart';

class DataManager extends GetxController {
  final box = GetStorage();
  final products = <ModelProduct>[].obs;
  final sales = <ModelSale>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    loadSales();
  }

  void loadProducts() {
    List<dynamic> productsJson = box.read('products') ?? [];
    products.assignAll(
      productsJson.map((json) => ModelProduct.fromJson(json)).toList(),
    );
  }

  void loadSales() {
    List<dynamic> salesJson = box.read('sales') ?? [];
    sales.assignAll(
      salesJson.map((json) => ModelSale.fromJson(json)).toList(),
    );
  }

  Future<void> saveProduct(ModelProduct product) async {
    products.add(product);
    await box.write('products', products.map((p) => p.toJson()).toList());
  }

  ModelProduct? getProductById(String productId) {
    try {
      return products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProduct(ModelProduct updatedProduct) async {
    int index =
        products.indexWhere((product) => product.id == updatedProduct.id);
    if (index != -1) {
      products[index] = updatedProduct;
      await box.write('products', products.map((p) => p.toJson()).toList());
    }
  }

  Future<void> updateStock(String productId, int newStock) async {
    int index = products.indexWhere((product) => product.id == productId);
    if (index != -1) {
      products[index].stock = newStock;
      await box.write('products', products.map((p) => p.toJson()).toList());
    }
  }

  Future<void> saveSale(ModelSale sale) async {
    sales.add(sale);
    await box.write('sales', sales.map((s) => s.toJson()).toList());
  }

  Future<void> clearAllData() async {
    await box.erase();
    products.clear();
    sales.clear();
  }

  Future<void> deleteProduct(String productId) async {
    products.removeWhere((product) => product.id == productId);
    await box.write('products', products.map((p) => p.toJson()).toList());
  }
}
