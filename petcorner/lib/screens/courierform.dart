import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;
import 'login.dart';
        

class CourierForm extends StatefulWidget {
  final String username;
  final String password;
  final String email;

  const CourierForm({
    super.key, 
    required this.username, 
    required this.password, 
    required this.email
  });

  @override
  State<CourierForm> createState() => _CourierFormState();
}

class _CourierFormState extends State<CourierForm> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _licenseImage;
  File? _selfieWithLicense;
  bool _isLoading = false;

  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _email;
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _middleName = TextEditingController();
  final _postalCode = TextEditingController();
  final _dob = TextEditingController();
  final _plateNumber = TextEditingController();

  String _sex = 'Male';

  // Address data
  List<dynamic> _provinces = [];
  List<dynamic> _municipalities = [];
  List<dynamic> _barangays = [];
  
  String? selectedProvince;
  String? selectedMunicipality;
  String? selectedBarangay;
  String? _selectedProvinceCode;
  String? _selectedMunicipalityCode;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with passed values
    _username = TextEditingController(text: widget.username);
    _password = TextEditingController(text: widget.password);
    _email = TextEditingController(text: widget.email);
    
    // Fetch provinces on init
    _fetchProvinces();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _email.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _middleName.dispose();
    _postalCode.dispose();
    _dob.dispose();
    _plateNumber.dispose();
    super.dispose();
  }

  // Submit courier information ..........................................................................................................
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Validate that images are selected
      if (_licenseImage == null) {
        _showErrorSnackBar('Please upload a photo of your license');
        return;
      }
      
      if (_selfieWithLicense == null) {
        _showErrorSnackBar('Please upload a selfie holding your license');
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      try {

        // Function to compress image
        Future<File> compressImage(File file) async {
          final dir = await path_provider.getTemporaryDirectory();
          final targetPath = p.join(dir.absolute.path, "${DateTime.now().millisecondsSinceEpoch}.jpg");
          
          var result = await FlutterImageCompress.compressAndGetFile(
            file.absolute.path,
            targetPath,
            quality: 70,     // Adjust quality (0-100)
            format: CompressFormat.jpeg,
          );
          
          return File(result!.path);
        }
        
        // Compress images
        File compressedLicense = await compressImage(_licenseImage!);
        File compressedSelfie = await compressImage(_selfieWithLicense!);
        
        // Create multipart request
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://192.168.1.19:5000/api/courier_application'),
        );
        
        // Add text fields
        request.fields['username'] = _username.text;
        request.fields['password'] = _password.text;
        request.fields['email'] = _email.text;
        request.fields['first_name'] = _firstName.text;
        request.fields['last_name'] = _lastName.text;
        request.fields['middle_name'] = _middleName.text;
        request.fields['province'] = selectedProvince ?? '';
        request.fields['municipality'] = selectedMunicipality ?? '';
        request.fields['barangay'] = selectedBarangay ?? '';
        request.fields['postal_code'] = _postalCode.text;
        request.fields['date_of_birth'] = _dob.text;
        request.fields['sex'] = _sex;
        request.fields['plate_number'] = _plateNumber.text;
        
        // Add compressed license image file
        request.files.add(
          await http.MultipartFile.fromPath(
            'license_image',
            compressedLicense.path,
          ),
        );
        
        // Add compressed selfie image file
        request.files.add(
          await http.MultipartFile.fromPath(
            'selfie_image',
            compressedSelfie.path,
          ),
        );
        
        // Send the request
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        
        setState(() {
          _isLoading = false;
        });
        
        // Parse response
        final responseData = json.decode(response.body);
        
        if (response.statusCode == 201) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application submitted successfully! Wait for the approval notification sent to your email.'),
              backgroundColor: Color.fromARGB(180, 86, 87, 86),
            ),
          );

          // Navigate back or to a confirmation screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false, 
          );
        } else {
          // Show error message
          _showErrorSnackBar(responseData['error'] ?? 'Failed to submit application');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Network error: ${e.toString()}');
      }
    }
  }

  // API Methods for Address ............................................................................................................
  Future<void> _fetchProvinces() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://psgc.gitlab.io/api/provinces/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _provinces = data;
          _isLoading = false;
        });
      } else {
        _showErrorSnackBar('Failed to load provinces');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Network error: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMunicipalities(String provinceCode) async {
    setState(() {
      _isLoading = true;
      _municipalities = [];
      selectedMunicipality = null;
      _barangays = [];
      selectedBarangay = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://psgc.gitlab.io/api/provinces/$provinceCode/municipalities/'),
      );

      // Also fetch cities as they're separate in the API
      final citiesResponse = await http.get(
        Uri.parse('https://psgc.gitlab.io/api/provinces/$provinceCode/cities/'),
      );

      if (response.statusCode == 200 && citiesResponse.statusCode == 200) {
        final municipalitiesData = json.decode(response.body);
        final citiesData = json.decode(citiesResponse.body);
        
        // Combine both municipalities and cities
        final combinedData = [...municipalitiesData, ...citiesData];
        
        setState(() {
          _municipalities = combinedData;
          _isLoading = false;
        });
      } else {
        _showErrorSnackBar('Failed to load municipalities/cities');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Network error: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBarangays(String municipalityCode) async {
    setState(() {
      _isLoading = true;
      _barangays = [];
      selectedBarangay = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://psgc.gitlab.io/api/municipalities/$municipalityCode/barangays/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _barangays = data;
          _isLoading = false;
        });
      } else {
        // Try city endpoint if municipality endpoint fails
        final cityResponse = await http.get(
          Uri.parse('https://psgc.gitlab.io/api/cities/$municipalityCode/barangays/'),
        );
        
        if (cityResponse.statusCode == 200) {
          final data = json.decode(cityResponse.body);
          setState(() {
            _barangays = data;
            _isLoading = false;
          });
        } else {
          _showErrorSnackBar('Failed to load barangays');
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Network error: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color.fromARGB(180, 86, 87, 86),
      ),
    );
  }

  Future<void> _pickLicenseImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _licenseImage = File(picked.path);
      });
    }
  }

  Future<void> _pickSelfieWithLicense() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selfieWithLicense = File(picked.path);
      });
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      readOnly: readOnly,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const UnderlineInputBorder(),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.amber, width: 2),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        suffixIcon: suffixIcon,
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Required field' : null,
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dob.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 245, 214, 37), 
        title: const Text(
          "Courier Registration",
          style: TextStyle(
            fontSize: 18.0, 
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      body: _isLoading ? 
        const Center(child: CircularProgressIndicator(color: Colors.amber)) :
        SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: _buildTextField(_username, "Username", readOnly: true),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6.0),
                      child: _buildTextField(_password, "Password", obscure: true, readOnly: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildTextField(_email, "Email", type: TextInputType.emailAddress, readOnly: true),
              const SizedBox(height: 12),
              _buildTextField(_firstName, "First Name"),
              const SizedBox(height: 12),
              _buildTextField(_lastName, "Last Name"),
              const SizedBox(height: 12),
              _buildTextField(_middleName, "Middle Name"),
              const SizedBox(height: 12),

              // Province Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Province",
                  border: UnderlineInputBorder(),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber, width: 2),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
                hint: const Text('Select Province'),
                value: selectedProvince,
                items: _provinces.map<DropdownMenuItem<String>>((province) {
                  return DropdownMenuItem<String>(
                    value: province['name'] as String,
                    child: Text(province['name']),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    // Find the province code
                    final selectedProvData = _provinces.firstWhere(
                      (province) => province['name'] == val,
                      orElse: () => null,
                    );
                    
                    if (selectedProvData != null) {
                      setState(() {
                        selectedProvince = val;
                        _selectedProvinceCode = selectedProvData['code'];
                        selectedMunicipality = null;
                        selectedBarangay = null;
                      });
                      
                      // Fetch municipalities for this province
                      _fetchMunicipalities(_selectedProvinceCode!);
                    }
                  }
                },
                validator: (val) => val == null ? 'Required field' : null,
              ),
              const SizedBox(height: 12),

              // Municipality Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Municipality/City",
                  border: UnderlineInputBorder(),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber, width: 2),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
                hint: const Text('Select Municipality/City'),
                value: selectedMunicipality,
                items: _municipalities.map<DropdownMenuItem<String>>((municipality) {
                  return DropdownMenuItem<String>(
                    value: municipality['name'] as String,
                    child: Text(municipality['name']),
                  );
                }).toList(),
                onChanged: selectedProvince == null ? null : (val) {
                  if (val != null) {
                    // Find the municipality code
                    final selectedMuniData = _municipalities.firstWhere(
                      (municipality) => municipality['name'] == val,
                      orElse: () => null,
                    );
                    
                    if (selectedMuniData != null) {
                      setState(() {
                        selectedMunicipality = val;
                        _selectedMunicipalityCode = selectedMuniData['code'];
                        selectedBarangay = null;
                      });
                      
                      // Fetch barangays for this municipality
                      _fetchBarangays(_selectedMunicipalityCode!);
                    }
                  }
                },
                validator: (val) => val == null ? 'Required field' : null,
              ),
              const SizedBox(height: 12),

              // Barangay Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Barangay",
                  border: UnderlineInputBorder(),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber, width: 2),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
                hint: const Text('Select Barangay'),
                value: selectedBarangay,
                items: _barangays.map<DropdownMenuItem<String>>((barangay) {
                  return DropdownMenuItem<String>(
                    value: barangay['name'] as String,
                    child: Text(barangay['name']),
                  );
                }).toList(),
                onChanged: selectedMunicipality == null ? null : (val) {
                  if (val != null) {
                    setState(() {
                      selectedBarangay = val;
                    });
                  }
                },
                validator: (val) => val == null ? 'Required field' : null,
              ),
              const SizedBox(height: 12),

              _buildTextField(_postalCode, "Postal Code", type: TextInputType.number),
              const SizedBox(height: 12),

              // Date of Birth picker
              GestureDetector(
                onTap: _selectDate,
                child: AbsorbPointer(
                  child: _buildTextField(
                    _dob,
                    "Date of Birth",
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                ),
              ),

              // Sex selection
              Row(
                children: [
                  const Text("Sex:", style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Radio(
                          value: 'Male',
                          groupValue: _sex,
                          onChanged: (val) => setState(() => _sex = val!),
                        ),
                        const Text("Male"),
                        Radio(
                          value: 'Female',
                          groupValue: _sex,
                          onChanged: (val) => setState(() => _sex = val!),
                        ),
                        const Text("Female"),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              _buildTextField(_plateNumber, "Plate Number"),
              const SizedBox(height: 20),

              // License Image
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Upload photo of your license", style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickLicenseImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        // Remove the Border.all() to eliminate black border
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: _licenseImage != null
                        ? ClipRRect(
                            // This clips the image with the same border radius
                            borderRadius: BorderRadius.circular(5),
                            child: Image.file(_licenseImage!, fit: BoxFit.cover),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[600]),
                                const SizedBox(height: 8),
                                Text("Tap to upload", style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Image holding License 
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Upload selfie holding your license", style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickSelfieWithLicense,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        //border: Border.all(),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: _selfieWithLicense != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Image.file(_selfieWithLicense!, fit: BoxFit.cover)
                          )
                        : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[600]),
                              const SizedBox(height: 8),
                              Text("Tap to upload", style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 245, 214, 37),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Submit", style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}