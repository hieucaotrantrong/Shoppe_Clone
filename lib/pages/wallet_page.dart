import 'package:flutter/material.dart';
import 'package:food_app/services/api_service.dart';
import 'package:food_app/services/shared_pref.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({Key? key}) : super(key: key);

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  bool _isLoading = true;
  double _balance = 0;
  List<Map<String, dynamic>> _transactions = [];
  final TextEditingController _amountController = TextEditingController();
  String _selectedPaymentMethod = 'bank';
  String? _userId;

  // Các mức tiền nạp nhanh
  final List<int> _quickAmounts = [100000, 200000, 500000];

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await SharedPreferenceHelper().getUserId();
      if (userId != null) {
        _userId = userId;

        // Lấy số dư ví
        final walletData = await ApiService.getWalletBalance(userId);

        // Lấy lịch sử giao dịch
        final transactions = await ApiService.getWalletTransactions(userId);

        setState(() {
          // Chuyển đổi balance từ String sang double
          if (walletData['balance'] is String) {
            _balance = double.parse(walletData['balance']);
          } else {
            _balance = walletData['balance']?.toDouble() ?? 0.0;
          }

          _transactions = List<Map<String, dynamic>>.from(transactions);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading wallet data: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải dữ liệu ví: $e')),
      );
    }
  }

  void _showTopUpDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nạp tiền',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                Text(
                  'Nhập số tiền (đ)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),

                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: 'đ ',
                    border: OutlineInputBorder(),
                    hintText: '0',
                  ),
                ),
                SizedBox(height: 8),

                Text(
                  'Số dư Ví hiện tại: đ${NumberFormat('#,###').format(_balance)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),

                // Các mức tiền nạp nhanh
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _quickAmounts
                      .map((amount) => InkWell(
                            onTap: () {
                              _amountController.text = amount.toString();
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.28,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${NumberFormat('#,###').format(amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                SizedBox(height: 24),

                // Phương thức thanh toán
                Text(
                  'Phương thức thanh toán',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),

                // Chọn phương thức thanh toán
                InkWell(
                  onTap: () {
                    _showPaymentMethodDialog(setState);
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _selectedPaymentMethod == 'bank'
                            ? Icon(Icons.account_balance, color: Colors.green)
                            : Icon(Icons.payment, color: Colors.blue),
                        SizedBox(width: 12),
                        Text(
                          _selectedPaymentMethod == 'bank'
                              ? 'Chuyển khoản ngân hàng'
                              : 'VNPay',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Thông tin thanh toán
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Nạp tiền'),
                          Text(
                            'đ${_amountController.text.isEmpty ? "0" : NumberFormat('#,###').format(int.tryParse(_amountController.text) ?? 0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tổng thanh toán'),
                          Text(
                            'đ${_amountController.text.isEmpty ? "0" : NumberFormat('#,###').format(int.tryParse(_amountController.text) ?? 0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Điều khoản
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nhấn "Nạp tiền ngay", bạn đã đồng ý tuân theo Điều khoản sử dụng và Chính sách bảo mật của ứng dụng',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Nút nạp tiền
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _processTopUp();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFff5722),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Nạp tiền ngay'),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          );
        });
      },
    );
  }

  void _showPaymentMethodDialog(StateSetter updateState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Chọn phương thức thanh toán'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.account_balance, color: Colors.green),
                title: Text('Chuyển khoản ngân hàng'),
                onTap: () {
                  updateState(() {
                    _selectedPaymentMethod = 'bank';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.payment, color: Colors.blue),
                title: Text('VNPay'),
                onTap: () {
                  updateState(() {
                    _selectedPaymentMethod = 'vnpay';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processTopUp() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập số tiền cần nạp')),
      );
      return;
    }

    final amount = int.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Số tiền không hợp lệ')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedPaymentMethod == 'bank') {
        _showBankTransferInfo(amount);
      } else {
        // Xử lý thanh toán VNPay
        _showVNPayInfo(amount);
      }
    } catch (e) {
      print('Error processing top-up: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xử lý nạp tiền: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showBankTransferInfo(int amount) {
    // Tạo yêu cầu nạp tiền
    _createTopUpRequest(amount, 'bank').then((success) {
      if (success) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Thông tin chuyển khoản'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ngân hàng: Vietcombank'),
                  SizedBox(height: 8),
                  Text('Số tài khoản: 1021966858'),
                  SizedBox(height: 8),
                  Text('Chủ tài khoản: CAO TRAN TRONG HIEU'),
                  SizedBox(height: 8),
                  Text('Số tiền: ${NumberFormat('#,###').format(amount)} VND'),
                  SizedBox(height: 8),
                  Text('Nội dung: NAP$_userId'),
                  SizedBox(height: 16),
                  Text(
                    'Lưu ý: Vui lòng chuyển khoản đúng số tiền và nội dung để hệ thống có thể xác nhận giao dịch của bạn.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadWalletData(); // Tải lại dữ liệu ví
                  },
                  child: Text('Đã hiểu'),
                ),
              ],
            );
          },
        );
      }
    });
  }

  void _showVNPayInfo(int amount) {
    // Tạo yêu cầu nạp tiền
    _createTopUpRequest(amount, 'vnpay').then((success) {
      if (success) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Thanh toán qua VNPay'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Số tiền: ${NumberFormat('#,###').format(amount)} VND'),
                  SizedBox(height: 16),
                  Text(
                    'Yêu cầu nạp tiền của bạn đã được tạo. Vui lòng chờ admin xác nhận.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Lưu ý: Trong tình huống thực tế, bạn sẽ được chuyển đến cổng thanh toán VNPay để hoàn tất giao dịch.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadWalletData(); // Tải lại dữ liệu ví
                  },
                  child: Text('Đã hiểu'),
                ),
              ],
            );
          },
        );
      }
    });
  }

  Future<bool> _createTopUpRequest(int amount, String method) async {
    try {
      print('Creating top-up request with amount: $amount, method: $method');

      final result = await ApiService.createWalletTopUp(
        _userId!,
        amount.toDouble(),
        method,
      );

      print('Top-up request result: $result');

      if (result != null && result['status'] == 'success') {
        Fluttertoast.showToast(
          msg: "Yêu cầu nạp tiền đã được tạo thành công",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tạo yêu cầu nạp tiền')),
        );
        return false;
      }
    } catch (e) {
      print('Error creating top-up request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ví của tôi'),
        backgroundColor: Color(0xFFff5722),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWalletData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thẻ số dư
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Color(0xFFff5722),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Số dư ví',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'đ${NumberFormat('#,###').format(_balance)}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _showTopUpDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Color(0xFFff5722),
                                ),
                                child: Text('Nạp tiền'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Lịch sử giao dịch
                      Text(
                        'Lịch sử giao dịch',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),

                      _buildTransactionList(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTransactionList() {
    if (_transactions.isEmpty) {
      return Center(
        child: Text('Chưa có giao dịch nào'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];

        // Chuyển đổi amount từ String sang double nếu cần
        double amount;
        if (transaction['amount'] is String) {
          amount = double.parse(transaction['amount']);
        } else {
          amount = transaction['amount']?.toDouble() ?? 0.0;
        }

        final isTopUp = transaction['type'] == 'top_up';
        final status = transaction['status'];

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isTopUp ? Colors.green : Colors.red,
              child: Icon(
                isTopUp ? Icons.add : Icons.remove,
                color: Colors.white,
              ),
            ),
            title: Text(
              isTopUp ? 'Nạp tiền' : 'Thanh toán',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Trạng thái: ${_getStatusText(status)}',
            ),
            trailing: Text(
              '${isTopUp ? '+' : '-'} ${_formatCurrency(amount)}',
              style: TextStyle(
                color: isTopUp ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
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

  // Phương thức lấy text trạng thái
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Đang xử lý';
      case 'completed':
        return 'Hoàn thành';
      case 'rejected':
        return 'Từ chối';
      default:
        return 'Không xác định';
    }
  }
}
