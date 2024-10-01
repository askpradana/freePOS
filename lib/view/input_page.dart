import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_application/controller/data_controller.dart';
import 'package:pos_application/model/product_model.dart';
import 'package:uuid/uuid.dart';

class InputStockPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  InputStockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add New Product',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
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
                decoration: const InputDecoration(labelText: 'Initial Stock'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter initial stock' : null,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addProduct,
                child: const Text('Add Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addProduct() {
    if (_formKey.currentState!.validate()) {
      final newProduct = ModelProduct(
        id: const Uuid().v4(),
        name: _nameController.text,
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
      );
      Get.find<DataManager>().saveProduct(newProduct);
      _nameController.clear();
      _priceController.clear();
      _stockController.clear();
      Get.snackbar('Success', 'Product added successfully');
    }
  }
}
