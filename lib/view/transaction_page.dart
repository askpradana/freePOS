import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_application/controller/data_controller.dart';
import 'package:pos_application/model/product_model.dart';
import 'package:pos_application/model/sale_model.dart';
import 'package:uuid/uuid.dart';

class TransactionPage extends StatelessWidget {
  final DataManager dataManager = Get.put(DataManager());
  final currentSale = <SaleItem>[].obs;
  final tempStockChanges = <String, int>{}.obs;

  TransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: transactionBody(),
    );
  }

  Widget transactionBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Products',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Obx(() {
            return ListView.builder(
              shrinkWrap: true,
              itemCount: dataManager.products.length,
              itemBuilder: (context, index) {
                final product = dataManager.products[index];
                return Obx(() {
                  final availableStock = _getAvailableStock(product);
                  return ListTile(
                    title: Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: availableStock > 0 ? Colors.black : Colors.grey,
                      ),
                    ),
                    subtitle: Text(
                        'Harga: Rp.${product.price.toStringAsFixed(0)} | Stok: $availableStock'),
                    onTap:
                        availableStock > 0 ? () => _addToSale(product) : null,
                  );
                });
              },
            );
          }),
          const SizedBox(height: 20),
          Obx(() {
            return currentSale.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Checkout Items',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: currentSale.length,
                        itemBuilder: (context, index) {
                          final item = currentSale[index];
                          final product = dataManager.products
                              .firstWhere((p) => p.id == item.productId);
                          return Dismissible(
                            key: Key(item.productId),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              _removeFromSale(index);
                            },
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20.0),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: ListTile(
                              title: Text(product.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  'Jumlah: ${item.quantity} | Harga: Rp.${(item.price * item.quantity).toStringAsFixed(0)}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _removeFromSale(index),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _completeSale,
                        child: const Text('Complete transactions'),
                      ),
                    ],
                  )
                : const Text('No items in the cart');
          }),
        ],
      ),
    );
  }

  int _getAvailableStock(ModelProduct product) {
    return product.stock - (tempStockChanges[product.id] ?? 0);
  }

  void _addToSale(ModelProduct product) {
    final availableStock = _getAvailableStock(product);
    if (availableStock <= 0) {
      Get.snackbar('Error', 'Product out of stock');
      return;
    }

    tempStockChanges[product.id] = (tempStockChanges[product.id] ?? 0) + 1;
    tempStockChanges.refresh();

    int existingIndex =
        currentSale.indexWhere((item) => item.productId == product.id);
    if (existingIndex != -1) {
      currentSale[existingIndex].quantity += 1;
      currentSale.refresh();
    } else {
      currentSale.add(
          SaleItem(productId: product.id, quantity: 1, price: product.price));
    }
  }

  void _removeFromSale(int index) {
    final item = currentSale[index];
    if (item.quantity > 1) {
      currentSale[index].quantity -= 1;
    } else {
      currentSale.removeAt(index);
    }

    currentSale.refresh();
    tempStockChanges[item.productId] =
        (tempStockChanges[item.productId] ?? 1) - 1;
    if (tempStockChanges[item.productId] == 0) {
      tempStockChanges.remove(item.productId);
    }
    tempStockChanges.refresh();
  }

  void _completeSale() {
    if (currentSale.isEmpty) {
      Get.snackbar('Error', 'Cart is empty');
      return;
    }

    final sale = ModelSale(
      id: const Uuid().v4(),
      date: DateTime.now(),
      items: List<SaleItem>.from(currentSale),
      total: currentSale.fold(
          0, (total, item) => total + (item.price * item.quantity)),
    );

    dataManager.saveSale(sale);

    for (var item in currentSale) {
      final product =
          dataManager.products.firstWhere((p) => p.id == item.productId);
      dataManager.updateStock(item.productId, product.stock - item.quantity);
    }

    currentSale.clear();
    tempStockChanges.clear();
    Get.snackbar('Success', 'Transaction completed');
  }
}
