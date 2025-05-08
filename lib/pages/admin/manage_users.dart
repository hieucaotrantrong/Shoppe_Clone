import 'package:flutter/material.dart';
import 'package:food_app/services/api_service.dart';

class ManageUsers extends StatefulWidget {
  const ManageUsers({Key? key}) : super(key: key);

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final users = await ApiService.getAllUsers();

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching users: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải danh sách người dùng')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý người dùng'),
        backgroundColor: Color(0xFFff5722),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildUserList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddUserDialog();
        },
        backgroundColor: Color(0xFFff5722),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildUserList() {
    if (_users.isEmpty) {
      return Center(child: Text('Không có người dùng nào'));
    }

    return ListView.builder(
      itemCount: _users.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          elevation: 3,
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Color(0xFFff5722),
              child: Text(
                user['name']?.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              user['name'] ?? 'Không có tên',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(user['email'] ?? 'Không có email'),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        user['role'] == 'admin' ? Colors.purple : Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    user['role'] == 'admin' ? 'Admin' : 'Người dùng',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    _showEditUserDialog(user);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _showDeleteConfirmation(user);
                  },
                ),
              ],
            ),
            onTap: () {
              _showUserDetails(user);
            },
          ),
        );
      },
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Chi tiết người dùng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID', user['id'].toString()),
              _buildDetailRow('Tên', user['name'] ?? 'Không có tên'),
              _buildDetailRow('Email', user['email'] ?? 'Không có email'),
              _buildDetailRow(
                  'Vai trò', user['role'] == 'admin' ? 'Admin' : 'Người dùng'),
              _buildDetailRow(
                  'Ngày tạo', user['created_at'] ?? 'Không có thông tin'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'user';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            return AlertDialog(
              title: Text('Thêm người dùng mới'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Tên *'),
                    ),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(labelText: 'Email *'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(labelText: 'Mật khẩu *'),
                      obscureText: true,
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(labelText: 'Vai trò'),
                      items: [
                        DropdownMenuItem(
                          value: 'user',
                          child: Text('Người dùng'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Admin'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value!;
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
                    if (nameController.text.isEmpty ||
                        emailController.text.isEmpty ||
                        passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                            content: Text('Vui lòng nhập đầy đủ thông tin')),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      final result = await ApiService.createUser(
                        nameController.text,
                        emailController.text,
                        passwordController.text,
                        selectedRole,
                      );

                      if (result != null && result['status'] == 'success') {
                        _fetchUsers();
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Thêm người dùng thành công')),
                        );
                      } else {
                        this.setState(() {
                          _isLoading = false;
                        });
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Thêm người dùng thất bại')),
                        );
                      }
                    } catch (e) {
                      this.setState(() {
                        _isLoading = false;
                      });
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
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

  void _showEditUserDialog(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name']);
    final emailController = TextEditingController(text: user['email']);
    final passwordController = TextEditingController();
    String selectedRole = user['role'] ?? 'user';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            return AlertDialog(
              title: Text('Chỉnh sửa người dùng'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Tên *'),
                    ),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(labelText: 'Email *'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu mới (để trống nếu không thay đổi)',
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(labelText: 'Vai trò'),
                      items: [
                        DropdownMenuItem(
                          value: 'user',
                          child: Text('Người dùng'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Admin'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value!;
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
                    if (nameController.text.isEmpty ||
                        emailController.text.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Vui lòng nhập tên và email')),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      final result = await ApiService.updateUser(
                        user['id'].toString(),
                        nameController.text,
                        emailController.text,
                        passwordController.text.isNotEmpty
                            ? passwordController.text
                            : null,
                        selectedRole,
                      );

                      if (result != null && result['status'] == 'success') {
                        _fetchUsers();
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                              content: Text('Cập nhật người dùng thành công')),
                        );
                      } else {
                        this.setState(() {
                          _isLoading = false;
                        });
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                              content: Text('Cập nhật người dùng thất bại')),
                        );
                      }
                    } catch (e) {
                      this.setState(() {
                        _isLoading = false;
                      });
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
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

  void _showDeleteConfirmation(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text(
              'Bạn có chắc chắn muốn xóa người dùng "${user['name']}" không?'),
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

                try {
                  final result =
                      await ApiService.deleteUser(user['id'].toString());

                  if (result != null && result['status'] == 'success') {
                    _fetchUsers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Xóa người dùng thành công')),
                    );
                  } else {
                    setState(() {
                      _isLoading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Xóa người dùng thất bại')),
                    );
                  }
                } catch (e) {
                  setState(() {
                    _isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
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
