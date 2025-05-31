import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_buyer.dart';
import 'orders.dart';
import 'notif.dart';
import 'editname.dart';
import 'editusername.dart';
import 'editphoneno.dart';
import 'editpassword.dart';
import 'editsex.dart';
import 'editbirthdate.dart';
import 'editaddress.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'login.dart'; 

class AccountScreen extends StatefulWidget {
  final int userId;

  const AccountScreen({super.key, required this.userId});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int _currentIndex = 3;

  // Variables to hold user data
  String name = '';
  String username = '';
  String email = '';
  String password = '';
  String phoneNumber = '';
  String gender = '';
  String birthday = '';
  String address = '';
  String? profileImageBase64;

  final ImagePicker _picker = ImagePicker();
  File? _selectedImageFile;
  bool _imageChanged = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    const String apiUrl = 'http://192.168.1.2:5000/api/get_buyer_account'; 

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.userId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = data['data'];

        setState(() {
          name = user['name'] ?? '';
          username = user['username'] ?? '';
          email = user['email'] ?? '';
          password = user['password'] ?? '';
          phoneNumber = user['phonenumber'] ?? '';
          gender = user['gender'] ?? '';
          
         
          if (user['birthday'] != null && user['birthday'].toString().isNotEmpty) {
            try {
              String birthdayStr = user['birthday'].toString();
              
              if (birthdayStr.contains(',') && birthdayStr.contains('GMT')) {
             
                List<String> parts = birthdayStr.split(' ');
                if (parts.length >= 4) {
                  int day = int.parse(parts[1].replaceAll(',', ''));
                  String month = parts[2];
                  int year = int.parse(parts[3]);
                  
                  
                  birthday = '$day $month $year';
                } else {
                  birthday = birthdayStr; 
                }
              } else {
               
                DateTime birthdayDate = DateTime.parse(birthdayStr);
                
              
                List<String> monthNames = [
                  'January', 'February', 'March', 'April', 'May', 'June',
                  'July', 'August', 'September', 'October', 'November', 'December'
                ];
                
                
                String monthName = monthNames[birthdayDate.month - 1];
                birthday = '${birthdayDate.day} $monthName ${birthdayDate.year}';
              }
            } catch (e) {
              print('Error formatting date: $e');
              birthday = user['birthday'].toString(); 
            }
          } else {
            birthday = '';
          }
          
          address = user['address'] ?? '';
          profileImageBase64 = user['profile'];
        });
      } else {
        print('Failed to load user data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }


  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedImage != null) {
        setState(() {
          _selectedImageFile = File(pickedImage.path);
          _imageChanged = true;
        });
      }
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  Future<void> _updateProfileImage() async {
    if (!_imageChanged || _selectedImageFile == null) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      // Convert image to base64
      List<int> imageBytes = await _selectedImageFile!.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      
      const String apiUrl = 'http://192.168.1.19:5000/api/update_profile_image';
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'profile_image': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // Update the local state with the new image
          setState(() {
            profileImageBase64 = base64Image;
            _imageChanged = false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile image updated successfully'),
                backgroundColor: Color.fromARGB(180, 86, 87, 86)
              ),
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile image: ${data['message']}'),
              backgroundColor: Color.fromARGB(180, 86, 87, 86)
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect to server'),
            backgroundColor: Color.fromARGB(180, 86, 87, 86)
          ),
        );
      }
    } catch (e) {
      print('Error updating profile image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile image: $e'),
          backgroundColor: Color.fromARGB(180, 86, 87, 86)
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  // Add this method to show the logout confirmation dialog
  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Logout Confirmation',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 88, 88, 88),
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 13,
              color: Color.fromARGB(255, 88, 88, 88),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _performLogout();
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Color.fromARGB(255, 215, 4, 4),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performLogout() async {
    
    // Navigate to login screen and remove all previous routes
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false, // This removes all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 241, 241),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 245, 214, 37),
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontSize: 17, color: Color.fromARGB(255, 88, 88, 88)),
        ),
        actions: [
          _isUpdating 
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey,
                  ),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.check),
                onPressed: _imageChanged ? _updateProfileImage : null,
              ),
        ],
    
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50, // Increased size for better visibility
                          backgroundImage: _selectedImageFile != null
                              ? FileImage(_selectedImageFile!) as ImageProvider
                              : (profileImageBase64 != null
                                  ? MemoryImage(base64Decode(profileImageBase64!))
                                  : const AssetImage('lib/assets/images/defaultprofile.jpeg') as ImageProvider),
                        ),
                    
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: GestureDetector(
                           
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 2.0,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.edit, size: 14, color: Color.fromARGB(255, 95, 95, 95)),
                       
                            ),
                          ), 
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _buildAccountField(
                      'Name', 
                      name, 
                      Icons.edit, 
                      () async {
                        final updatedName = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditNameScreen(
                              currentName: name, 
                              userId: widget.userId,
                            ),
                          ),
                        );
                        if (updatedName != null && updatedName is String) {
                          setState(() {
                            name = updatedName;
                          });
                        }
                      },
                    ),

                    _buildAccountField(
                      'Username', 
                      username, 
                      Icons.edit, 
                      () async {
                        final updatedUsername = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditUsernameScreen(
                              currentUsername: username, 
                              userId: widget.userId,
                            ),
                          ),
                        );
                        if (updatedUsername != null && updatedUsername is String) {
                          setState(() {
                            username = updatedUsername;
                          });
                        }
                      },
                    ),

                    _buildAccountField('Phone Number', phoneNumber, Icons.edit, () async {
                      final updatedPhoneNumber = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPhoneNumberScreen(currentPhoneNumber: phoneNumber, userId: widget.userId),
                        ),
                      );
                      if (updatedPhoneNumber != null && updatedPhoneNumber is String) {
                        setState(() {
                          phoneNumber = updatedPhoneNumber;
                        });
                      }
                    }),

                    _buildAccountField('Password', '********', Icons.edit, () async {
                      final updatedPassword = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPasswordScreen(userId: widget.userId),
                        ),
                      );
                      if (updatedPassword != null && updatedPassword is String) {
                        setState(() {
                          
                        });
                      }
                    }),

                    _buildNonEditableField('Verified Email', email, Icons.lock),
         
                    _buildAccountField('Sex', gender, Icons.edit, () async {
                      final updatedGender = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditSexScreen(
                            currentGender: gender,
                            userId: widget.userId,
                          ),
                        ),
                      );
                      if (updatedGender != null && updatedGender is String) {
                        setState(() {
                          gender = updatedGender;
                        });
                      }
                    }),

                    _buildAccountField('Birthdate', birthday, Icons.edit, () async {
                      final updatedBirthdate = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditBirthdateScreen(
                            currentBirthdate: birthday,
                            userId: widget.userId,
                          ),
                        ),
                      );
                      if (updatedBirthdate != null && updatedBirthdate is String) {
                        setState(() {
                          birthday = updatedBirthdate;
                        });
                      }
                    }),

                    _buildAccountField('Address', address, Icons.edit, () async {
                      final updatedAddress = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditAddressScreen(
                            currentAddress: address,
                            userId: widget.userId,
                          ),
                        ),
                      );
                      if (updatedAddress != null && updatedAddress is String) {
                        setState(() {
                          address = updatedAddress;
                        });
                      }
                    }),

                  ],
                ),
              ),
            ),
          ),
         
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color.fromARGB(255, 156, 155, 155), width: 0.7), 
                backgroundColor: Colors.transparent,
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                _showLogoutConfirmationDialog();
              },
              icon: const Icon(Icons.logout, color: Color.fromARGB(255, 80, 79, 79)),
              label: const Text('Logout', style: TextStyle( color: Color.fromARGB(255, 80, 79, 79))),
            ),
          ),

        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeBuyerScreen(userId: widget.userId)),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => OrdersScreen(userId: widget.userId)),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => NotificationBuyerScreen(userId: widget.userId)),
              );
              break;
            case 3:
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
      ),
    );
  }

  Widget _buildAccountField(String label, String value, IconData icon, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 4.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ),
                Expanded(
                  flex: 5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w300,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios, size: 11, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 0.3),
      ],
    );
  }


  // New method for non-editable fields (specifically for email)
  Widget _buildNonEditableField(String label, String value, IconData icon) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 4.0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ),
              Expanded(
                flex: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(icon, size: 11, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 0.3),
      ],
    );
  }
}
