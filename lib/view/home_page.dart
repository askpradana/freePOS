import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_application/controller/tab_controller.dart';
import 'package:pos_application/view/add_product_page.dart';
import 'package:pos_application/view/input_page.dart';
import 'package:pos_application/view/report_page.dart';
import 'package:pos_application/view/transaction_page.dart';

class SupermarketApp extends StatelessWidget {
  const SupermarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KASIR'),
        bottom: TabBar(
          controller: Get.put(TabControllerX()).tabController,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_cart), text: 'Transaction'),
            Tab(icon: Icon(Icons.add_box), text: 'Input Stock'),
            Tab(icon: Icon(Icons.settings), text: 'Product Settings'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Sales Report'),
          ],
        ),
      ),
      body: TabBarView(
        controller: Get.put(TabControllerX()).tabController,
        children: [
          TransactionPage(),
          InputStockPage(),
          ProductSettingsPage(),
          const SalesReportPage(),
        ],
      ),
    );
  }
}
