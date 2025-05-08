import 'package:flutter/material.dart';
import 'package:food_app/services/api_service.dart';

class ManageProducts extends StatefulWidget {
  @override
  _ManageProductsState createState() => _ManageProductsState();
}

class _ManageProductsState extends State<ManageProducts> {
  bool _isLoading = true;
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final products = await ApiService.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        _isLoading = false;
        _products = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quản lý sản phẩm"),
        backgroundColor: Color(0xFFff5722),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildResponsiveProductList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddProductDialog();
        },
        backgroundColor: Color(0xFFff5722),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildResponsiveProductList() {
    // Lấy kích thước màn hình
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Xác định số cột dựa trên kích thước màn hình
    int crossAxisCount;
    if (screenWidth < 600) {
      crossAxisCount = 1; // Điện thoại
    } else if (screenWidth < 900) {
      crossAxisCount = 2; // Tablet
    } else {
      crossAxisCount = 3; // Desktop
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _products.isEmpty
          ? Center(child: Text("Không có sản phẩm nào"))
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return _buildProductCard(product);
              },
            ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showEditProductDialog(product);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hình ảnh sản phẩm
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: product['image_path'] != null && product['image_path'].isNotEmpty
                        ? Image.network(
                            product['image_path'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                              );
                            },
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: Icon(Icons.fastfood, color: Colors.grey[600]),
                          ),
                  ),
                  SizedBox(width: 12),
                  // Thông tin sản phẩm
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] ?? 'Không có tên',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${_formatPrice(product['price'])} VNĐ',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Danh mục: ${product['category'] ?? 'Khác'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Spacer(),
              // Các nút hành động
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      _showEditProductDialog(product);
                    },
                    tooltip: 'Chỉnh sửa',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                  SizedBox(width: 16),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _showDeleteConfirmation(product);
                    },
                    tooltip: 'Xóa',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    
    // Chuyển đổi giá thành số
    double numPrice;
    if (price is String) {
      numPrice = double.tryParse(price) ?? 0;
    } else {
      numPrice = price.toDouble();
    }
    
    // Định dạng số với dấu phân cách hàng nghìn
    return numPrice.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    final imagePathController = TextEditingController();
    String selectedCategory = 'Other';

    showDialog(
      context: context,
      builder: (dialogContext) { // Sử dụng dialogContext thay vì context
        return StatefulBuilder(
          builder: (builderContext, setState) { // Sử dụng builderContext
            return AlertDialog(
              title: Text('Thêm sản phẩm mới'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Tên sản phẩm *'),
                    ),
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(labelText: 'Giá (VNĐ) *'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: 'Mô tả'),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: imagePathController,
                      decoration: InputDecoration(labelText: 'Đường dẫn hình ảnh'),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(labelText: 'Danh mục'),
                      items: [
                        'Clothing',
                        'Shoes',
                        'Accessories',
                        'Electronics',
                        'Sports',
                        'Beauty',
                        'Other',
                      ].map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text('Hủy'),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || priceController.text.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Vui lòng nhập tên và giá sản phẩm')),
                      );
                      return;
                    }

                    final productData = {
                      'name': nameController.text,
                      'price': double.tryParse(priceController.text) ?? 0,
                      'description': descriptionController.text,
                      'image_path': imagePathController.text,
                      'category': selectedCategory,
                    };

                    Navigator.pop(dialogContext);
                    
                    // Lưu context chính để sử dụng sau khi API call hoàn thành
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    
                    this.setState(() {
                      _isLoading = true;
                    });

                    final result = await ApiService.createProduct(productData);
                    
                    if (result != null && result['status'] == 'success') {
                      _fetchProducts();
                      // Sử dụng scaffoldMessenger đã lưu trước đó
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Thêm sản phẩm thành công')),
                      );
                    } else {
                      this.setState(() {
                        _isLoading = false;
                      });
                      // Sử dụng scaffoldMessenger đã lưu trước đó
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Thêm sản phẩm thất bại')),
                      );
                    }
                  },
                  child: Text('Thêm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditProductDialog(dynamic product) {
    final nameController = TextEditingController(text: product['name']);
    final priceController = TextEditingController(text: product['price'].toString());
    final descriptionController = TextEditingController(text: product['description'] ?? '');
    final imagePathController = TextEditingController(text: product['image_path'] ?? '');
    String selectedCategory = product['category'] ?? 'Other';

    showDialog(
      context: context,
      builder: (dialogContext) { // Sử dụng dialogContext thay vì context
        return StatefulBuilder(
          builder: (builderContext, setState) { // Sử dụng builderContext
            return AlertDialog(
              title: Text('Chỉnh sửa sản phẩm'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Tên sản phẩm *'),
                    ),
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(labelText: 'Giá (VNĐ) *'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: 'Mô tả'),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: imagePathController,
                      decoration: InputDecoration(labelText: 'Đường dẫn hình ảnh'),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(labelText: 'Danh mục'),
                      items: [
                        'Clothing',
                        'Shoes',
                        'Accessories',
                        'Electronics',
                        'Sports',
                        'Beauty',
                        'Other',
                      ].map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text('Hủy'),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || priceController.text.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Vui lòng nhập tên và giá sản phẩm')),
                      );
                      return;
                    }

                    final productData = {
                      'name': nameController.text,
                      'price': double.tryParse(priceController.text) ?? 0,
                      'description': descriptionController.text,
                      'image_path': imagePathController.text,
                      'category': selectedCategory,
                    };

                    Navigator.pop(dialogContext);
                    
                    // Lưu context chính để sử dụng sau khi API call hoàn thành
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    
                    this.setState(() {
                      _isLoading = true;
                    });

                    final result = await ApiService.updateProduct(
                      product['id'].toString(), // Chuyển đổi thành String
                      productData,
                    );
                    
                    if (result != null && result['status'] == 'success') {
                      _fetchProducts();
                      // Sử dụng scaffoldMessenger đã lưu trước đó
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Cập nhật sản phẩm thành công')),
                      );
                    } else {
                      this.setState(() {
                        _isLoading = false;
                      });
                      // Sử dụng scaffoldMessenger đã lưu trước đó
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Cập nhật sản phẩm thất bại')),
                      );
                    }
                  },
                  child: Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(dynamic product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa sản phẩm "${product['name']}" không?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                setState(() {
                  _isLoading = true;
                });

                final result = await ApiService.deleteProduct(
                  product['id'].toString(), // Chuyển đổi thành String
                );
                
                if (result != null && result['status'] == 'success') {
                  _fetchProducts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Xóa sản phẩm thành công')),
                  );
                } else {
                  setState(() {
                    _isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Xóa sản phẩm thất bại')),
                  );
                }
              },
              child: Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}









