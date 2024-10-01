import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_application/controller/data_controller.dart';
import 'package:pos_application/model/product_model.dart';
import 'package:pos_application/model/sale_model.dart';
import 'package:uuid/uuid.dart';

class SupermarketApp extends StatefulWidget {
  const SupermarketApp({super.key});

  @override
  State<SupermarketApp> createState() => _SupermarketAppState();
}

class _SupermarketAppState extends State<SupermarketApp>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DataManager _dataManager = DataManager();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS AUD.'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_cart), text: 'Transaction'),
            Tab(icon: Icon(Icons.add_box), text: 'Input Stock'),
            Tab(icon: Icon(Icons.settings), text: 'Product Settings'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Sales Report'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TransactionPage(dataManager: _dataManager),
          InputStockPage(dataManager: _dataManager),
          ProductSettingsPage(dataManager: _dataManager),
          SalesReportPage(dataManager: _dataManager),
        ],
      ),
    );
  }
}

class TransactionPage extends StatefulWidget {
  final DataManager dataManager;

  const TransactionPage({super.key, required this.dataManager});

  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  List<ModelProduct> _products = [];
  List<SaleItem> _currentSale = [];
  Map<String, int> _tempStockChanges = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      _products = widget.dataManager.getProducts();
      _tempStockChanges = {};
    });
  }

  int _getAvailableStock(ModelProduct product) {
    return product.stock - (_tempStockChanges[product.id] ?? 0);
  }

  void _addToSale(ModelProduct product) {
    int availableStock = _getAvailableStock(product);
    if (availableStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product out of stock')),
      );
      return;
    }

    setState(() {
      int existingIndex =
          _currentSale.indexWhere((item) => item.productId == product.id);
      if (existingIndex != -1) {
        _currentSale[existingIndex].quantity += 1;
      } else {
        _currentSale.add(SaleItem(
          productId: product.id,
          quantity: 1,
          price: product.price,
        ));
      }
      _tempStockChanges[product.id] = (_tempStockChanges[product.id] ?? 0) + 1;
    });
  }

  void _removeFromSale(int index) {
    final item = _currentSale[index];
    setState(() {
      if (item.quantity > 1) {
        item.quantity -= 1;
      } else {
        _currentSale.removeAt(index);
      }
      _tempStockChanges[item.productId] =
          (_tempStockChanges[item.productId] ?? 1) - 1;
      if (_tempStockChanges[item.productId] == 0) {
        _tempStockChanges.remove(item.productId);
      }
    });
  }

  void _completeSale() {
    if (_currentSale.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    final sale = ModelSale(
      id: const Uuid().v4(),
      date: DateTime.now(),
      items: _currentSale,
      total: _currentSale.fold(
          0, (total, item) => total + (item.price * item.quantity)),
    );

    widget.dataManager.saveSale(sale);

    for (var item in _currentSale) {
      final product = _products.firstWhere((p) => p.id == item.productId);
      widget.dataManager
          .updateStock(item.productId, product.stock - item.quantity);
    }

    setState(() {
      _currentSale = [];
      _tempStockChanges = {};
    });

    _loadProducts();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction completed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Available Products',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
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
                      'Price: \$${product.price.toStringAsFixed(0)} | Available Stock: $availableStock'),
                  onTap: availableStock > 0 ? () => _addToSale(product) : null,
                );
              },
            ),
            _currentSale.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text('Checkout Items',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: _currentSale.length,
                        itemBuilder: (context, index) {
                          final item = _currentSale[index];
                          final product = _products
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
                              title: Text(
                                product.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  'Quantity: ${item.quantity} | Price: \$${(item.price * item.quantity).toStringAsFixed(0)}'),
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
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}

class InputStockPage extends StatefulWidget {
  final DataManager dataManager;

  const InputStockPage({super.key, required this.dataManager});

  @override
  _InputStockPageState createState() => _InputStockPageState();
}

class _InputStockPageState extends State<InputStockPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  void _addProduct() {
    if (_formKey.currentState!.validate()) {
      final newProduct = ModelProduct(
        id: const Uuid().v4(),
        name: _nameController.text,
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
      );
      widget.dataManager.saveProduct(newProduct);
      _nameController.clear();
      _priceController.clear();
      _stockController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
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
                decoration: const InputDecoration(labelText: 'Price'),
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
                  onPressed: _addProduct, child: const Text('Add Product')),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductSettingsPage extends StatefulWidget {
  final DataManager dataManager;

  const ProductSettingsPage({super.key, required this.dataManager});

  @override
  _ProductSettingsPageState createState() => _ProductSettingsPageState();
}

class _ProductSettingsPageState extends State<ProductSettingsPage> {
  List<ModelProduct> _products = [];
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      _products = widget.dataManager.getProducts();
    });
  }

  void _showUpdateProductForm(ModelProduct product) {
    _nameController.text = product.name;
    _priceController.text = product.price.toString();
    _stockController.text = product.stock.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                decoration: const InputDecoration(labelText: 'Price'),
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
            onPressed: () => Navigator.pop(context),
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
      widget.dataManager.updateProduct(updatedProduct);
      _loadProducts();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Product List',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return ListTile(
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                      'Price: \$${product.price.toStringAsFixed(0)} | Stock: ${product.stock}'),
                  onTap: () => _showUpdateProductForm(product),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SalesReportPage extends StatefulWidget {
  final DataManager dataManager;

  const SalesReportPage({super.key, required this.dataManager});

  @override
  _SalesReportPageState createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  List<ModelSale> _sales = [];

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  void _loadSales() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    setState(() {
      _sales = widget.dataManager
          .getSales()
          .where((sale) => sale.date.isAfter(startOfMonth))
          .toList();
    });
  }

  void _showSaleDetails(ModelSale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sale Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sale ID: ${sale.id}'),
              Text(
                  'Sale Date: ${DateFormat('yyyy-MM-dd HH:mm').format(sale.date)}'),
              Text('Total: \$${sale.total.toStringAsFixed(0)}'),
              const SizedBox(height: 10),
              const Text('Items:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...sale.items.map((item) {
                final product =
                    widget.dataManager.getProductById(item.productId);
                return ListTile(
                  title: Text(product?.name ?? 'Unknown Product'),
                  subtitle: Text(
                      'Quantity: ${item.quantity} | Price: \$${item.price.toStringAsFixed(0)}'),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSales = _sales.fold(0.0, (total, sale) => total + sale.total);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Sales Report for ${DateFormat('MMMM yyyy').format(DateTime.now())}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Total Sales: \$${totalSales.toStringAsFixed(0)}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _sales.length,
              itemBuilder: (context, index) {
                final sale = _sales[index];
                return ListTile(
                  title: Text('Sale ID: ${sale.id}'),
                  subtitle: Text(
                      'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(sale.date)} | Total: \$${sale.total.toStringAsFixed(0)}'),
                  onTap: () => _showSaleDetails(sale),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
