import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pos_application/controller/data_controller.dart';
import 'package:pos_application/model/sale_model.dart';

class SalesReportPage extends StatelessWidget {
  const SalesReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: GetX<DataManager>(
          builder: (controller) {
            final now = DateTime.now();
            final startOfMonth = DateTime(now.year, now.month, 1);
            final sales = controller.sales
                .where((sale) => sale.date.isAfter(startOfMonth))
                .toList();
            sales.sort(
                (a, b) => b.date.compareTo(a.date)); // Sort by newest on top
            final totalSales =
                sales.fold(0.0, (total, sale) => total + sale.total);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales Report for ${DateFormat('MMMM yyyy').format(DateTime.now())}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total Sales: Rp.${totalSales.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text('Sale ID: ${sale.id}'),
                        subtitle: Text(
                            'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(sale.date)} | Total: Rp.${sale.total.toStringAsFixed(0)}'),
                        onTap: () => _showSaleDetails(sale),
                      ),
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

  void _showSaleDetails(ModelSale sale) {
    Get.dialog(
      AlertDialog(
        title: const Text('Sale Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sale ID: ${sale.id}'),
              Text(
                  'Sale Date: ${DateFormat('yyyy-MM-dd HH:mm').format(sale.date)}'),
              Text('Total: Rp.${sale.total.toStringAsFixed(0)}'),
              const SizedBox(height: 10),
              const Text('Items:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...sale.items.map((item) {
                final product =
                    Get.find<DataManager>().getProductById(item.productId);
                return ListTile(
                  title: Text(product?.name ?? 'Unknown Product'),
                  subtitle: Text(
                      'Jumlah: ${item.quantity} | Harga: Rp.${item.price.toStringAsFixed(0)}'),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
