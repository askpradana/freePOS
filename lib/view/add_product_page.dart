import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_application/controller/data_controller.dart';
import 'package:pos_application/model/product_model.dart';

class ProductSettingsPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  ProductSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: GetX<DataManager>(
          builder: (controller) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Product List',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: controller.products.length,
                  itemBuilder: (context, index) {
                    final product = controller.products[index];
                    return ListTile(
                      title: Text(product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          'Harga: Rp.${product.price.toStringAsFixed(0)} | Stock: ${product.stock}'),
                      onTap: () => _showUpdateProductForm(product),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showUpdateProductForm(ModelProduct product) {
    _nameController.text = product.name;
    _priceController.text = product.price.toString();
    _stockController.text = product.stock.toString();

    Get.dialog(
      AlertDialog(
        title: Text('Update ${product.name}'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a price' : null,
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter stock' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateProduct(product.id),
            child: const Text('Update Product'),
          ),
        ],
      ),
    );
  }

  void _updateProduct(String productId) {
    if (_formKey.currentState!.validate()) {
      final updatedProduct = ModelProduct(
        id: productId,
        name: _nameController.text,
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
      );
      Get.find<DataManager>().updateProduct(updatedProduct);
      Get.back();
      Get.snackbar('Success', 'Product updated successfully');
    }
  }
}
