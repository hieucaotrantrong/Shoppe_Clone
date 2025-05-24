import 'package:flutter/material.dart';
import 'package:food_app/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ManageWalletTopUps extends StatefulWidget {
  const ManageWalletTopUps({Key? key}) : super(key: key);

  @override
  State<ManageWalletTopUps> createState() => _ManageWalletTopUpsState();
}

class _ManageWalletTopUpsState extends State<ManageWalletTopUps> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _topUps = [];
  String _filter = 'pending'; // 'pending', 'completed', 'all'

  @override
  void initState() {
    super.initState();
    _loadTopUpRequests();
  }

  Future<void> _loadTopUpRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final requests = await ApiService.getWalletTopUpRequests(_filter);
      
      setState(() {
        _topUps = requests;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading top-up requests: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải yêu cầu nạp tiền: $e')),
      );
    }
  }

  Future<void> _approveTopUp(String requestId) async {
    try {
      final result = await ApiService.approveWalletTopUp(requestId);
      
      if (result != null && result['status'] == 'success') {
        Fluttertoast.showToast(
          msg: "Đã xác nhận nạp tiền thành công",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        
        // Tải lại danh sách yêu cầu
        _loadTopUpRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xác nhận yêu cầu nạp tiền')),
        );
      }
    } catch (e) {
      print('Error approving top-up: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _rejectTopUp(String requestId) async {
    try {
      final result = await ApiService.rejectWalletTopUp(requestId);
      
      if (result != null && result['status'] == 'success') {
        Fluttertoast.showToast(
          msg: "Đã từ chối yêu cầu nạp tiền",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        
        // Tải lại danh sách yêu cầu
        _loadTopUpRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể từ chối yêu cầu nạp tiền')),
        );
      }
    } catch (e) {
      print('Error rejecting top-up: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý nạp tiền'),
        backgroundColor: Color(0xFFff5722),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter options
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterChip('Đang chờ', 'pending'),
                _buildFilterChip('Đã xác nhận', 'completed'),
                _buildFilterChip('Tất cả', 'all'),
              ],
            ),
          ),
          
          // List of top-up requests
          Expanded(
            child: _buildTopUpList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Color(0xFFff5722).withOpacity(0.2),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filter = value;
          });
          _loadTopUpRequests();
        }
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Đang chờ';
        break;
      case 'completed':
        color = Colors.green;
        label = 'Đã xác nhận';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Đã từ chối';
        break;
      default:
        color = Colors.grey;
        label = 'Không xác định';
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTopUpList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_topUps.isEmpty) {
      return Center(
        child: Text('Không có yêu cầu nạp tiền nào'),
      );
    }

    return ListView.builder(
      itemCount: _topUps.length,
      itemBuilder: (context, index) {
        final topUp = _topUps[index];
        
        // Chuyển đổi amount từ String sang double nếu cần
        double amount;
        if (topUp['amount'] is String) {
          amount = double.parse(topUp['amount']);
        } else {
          amount = topUp['amount']?.toDouble() ?? 0.0;
        }
        
        final status = topUp['status'];
        final userName = topUp['user_name'] ?? 'Người dùng';
        final createdAt = topUp['created_at'] != null
            ? DateTime.parse(topUp['created_at'])
            : DateTime.now();
        
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    _buildStatusChip(status),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Số tiền: ${_formatCurrency(amount)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ngày tạo: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 16),
                if (status == 'pending')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => _rejectTopUp(topUp['id'].toString()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Text('Từ chối'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _approveTopUp(topUp['id'].toString()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Text('Xác nhận'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Phương thức định dạng tiền tệ
  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
        .format(amount);
  }
}



