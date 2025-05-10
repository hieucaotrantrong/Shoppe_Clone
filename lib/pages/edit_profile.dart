import 'dart:io';
import 'package:flutter/material.dart';
import 'package:food_app/services/shared_pref.dart';
import 'package:food_app/services/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? userId, profileImage;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      userId = await SharedPreferenceHelper().getUserId();
      String? name = await SharedPreferenceHelper().getUserName();
      String? email = await SharedPreferenceHelper().getUserEmail();
      profileImage = await SharedPreferenceHelper().getUserProfile();

      setState(() {
        _nameController.text = name ?? '';
        _emailController.text = email ?? '';
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading user data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      // Hiển thị dialog để chọn nguồn ảnh
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Chọn ảnh từ"),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  GestureDetector(
                    child: Text("Thư viện ảnh"),
                    onTap: () {
                      Navigator.of(context).pop();
                      _getImage(ImageSource.gallery);
                    },
                  ),
                  Padding(padding: EdgeInsets.all(8.0)),
                  GestureDetector(
                    child: Text("Máy ảnh"),
                    onTap: () {
                      Navigator.of(context).pop();
                      _getImage(ImageSource.camera);
                    },
                  ),
                  Padding(padding: EdgeInsets.all(8.0)),
                  GestureDetector(
                    child: Text("Chọn file từ máy tính"),
                    onTap: () {
                      Navigator.of(context).pop();
                      _getFileFromComputer();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error getting image: $e");
      Fluttertoast.showToast(
        msg: "Lỗi khi chọn ảnh: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _getFileFromComputer() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      
      if (result != null) {
        setState(() {
          _imageFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      print("Error getting file from computer: $e");
      Fluttertoast.showToast(
        msg: "Lỗi khi chọn file: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? newProfileImageUrl;
      
      // Upload ảnh mới nếu người dùng đã chọn ảnh
      if (_imageFile != null) {
        newProfileImageUrl = await ApiService.uploadProfileImage(userId!, _imageFile!);
        if (newProfileImageUrl == null) {
          // Hiển thị thông báo lỗi nếu upload ảnh thất bại
          Fluttertoast.showToast(
            msg: "Không thể tải lên ảnh đại diện",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      }

      // Cập nhật thông tin người dùng
      final result = await ApiService.updateUserProfile(
        userId!,
        _nameController.text,
        _emailController.text,
        _passwordController.text.isEmpty ? null : _passwordController.text,
        profileImage: newProfileImageUrl,
      );

      setState(() {
        _isLoading = false;
      });

      if (result != null && result['status'] == 'success') {
        // Cập nhật thông tin người dùng trong SharedPreferences
        await SharedPreferenceHelper().saveUserData(
          userId!,
          _nameController.text,
          _emailController.text,
          await SharedPreferenceHelper().getUserRole() ?? 'user',
        );

        // Cập nhật URL ảnh đại diện nếu có
        if (newProfileImageUrl != null) {
          await SharedPreferenceHelper().saveUserProfile(newProfileImageUrl);
        }

        Fluttertoast.showToast(
          msg: "Cập nhật thông tin thành công",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );

        Navigator.pop(context);
      } else {
        Fluttertoast.showToast(
          msg: "Cập nhật thông tin thất bại",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      Fluttertoast.showToast(
        msg: "Đã xảy ra lỗi: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
        backgroundColor: Color(0xFFff5722),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (profileImage != null && profileImage!.isNotEmpty
                              ? NetworkImage(profileImage!)
                              : null),
                      child: (profileImage == null || profileImage!.isEmpty) && _imageFile == null
                          ? Icon(Icons.person, size: 60, color: Colors.grey[700])
                          : null,
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: _pickImage,
                      child: Text("Change Profile Picture"),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Name",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: "New Password (leave blank to keep current)",
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFff5722),
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text("Save Changes"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}







