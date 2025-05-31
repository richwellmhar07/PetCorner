import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditAddressScreen extends StatefulWidget {
  final String currentAddress;
  final int userId;

  const EditAddressScreen({
    super.key, 
    required this.currentAddress, 
    required this.userId
  });

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final TextEditingController _houseStreetController = TextEditingController();

  // Location data holders
  String? _selectedProvince;
  String? _selectedMunicipality;
  String? _selectedBarangay;
  
  // IDs for API calls
  String? _selectedProvinceCode;
  String? _selectedMunicipalityCode;
  
  // Lists for dropdown menus
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _municipalities = [];
  List<Map<String, dynamic>> _barangays = [];
  
  // Loading states
  bool _isLoading = true;
  bool _isMunicipalitiesLoading = false;
  bool _isBarangaysLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProvinces();
    _parseCurrentAddress();
  }

  void _parseCurrentAddress() {
    // If there's a current address, try to parse it
    // This is a simple implementation - you may need to enhance it based on your address format
    if (widget.currentAddress.isNotEmpty) {
      final addressParts = widget.currentAddress.split(',');
      if (addressParts.isNotEmpty) {
        _houseStreetController.text = addressParts[0].trim();
      }
    }
  }

  @override
  void dispose() {
    _houseStreetController.dispose();
    super.dispose();
  }

  // Fetch provinces directly
  Future<void> _fetchProvinces() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/provinces/'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _provinces = data.map((province) => {
            'name': province['name'],
            'code': province['code'],
          }).toList();
          _provinces.sort((a, b) => a['name'].compareTo(b['name']));
          _isLoading = false;
        });
      } else {
        _showErrorSnackBar('Failed to load provinces');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch municipalities by province code
  Future<void> _fetchMunicipalities(String provinceCode) async {
    setState(() {
      _isMunicipalitiesLoading = true;
      _municipalities = [];
      _barangays = [];
      _selectedMunicipality = null;
      _selectedBarangay = null;
    });

    try {
      final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/provinces/$provinceCode/municipalities/'));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          _municipalities = data.map((municipality) => {
            'name': municipality['name'],
            'code': municipality['code'],
          }).toList();
          
          // Also fetch cities in the province to add to municipalities list
          _fetchCities(provinceCode);
        });
      } else {
        _showErrorSnackBar('Failed to load municipalities');
        setState(() {
          _isMunicipalitiesLoading = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
      setState(() {
        _isMunicipalitiesLoading = false;
      });
    }
  }

  // Fetch cities by province code and add to municipalities
  Future<void> _fetchCities(String provinceCode) async {
    try {
      final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/provinces/$provinceCode/cities/'));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          final cities = data.map((city) => {
            'name': city['name'],
            'code': city['code'],
          }).toList();
          
          // Combine municipalities and cities
          _municipalities.addAll(cities);
          _municipalities.sort((a, b) => a['name'].compareTo(b['name']));
          _isMunicipalitiesLoading = false;
        });
      } else {
        setState(() {
          _municipalities.sort((a, b) => a['name'].compareTo(b['name']));
          _isMunicipalitiesLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _municipalities.sort((a, b) => a['name'].compareTo(b['name']));
        _isMunicipalitiesLoading = false;
      });
    }
  }

  // Fetch barangays by municipality code
  Future<void> _fetchBarangays(String municipalityCode) async {
    setState(() {
      _isBarangaysLoading = true;
      _barangays = [];
      _selectedBarangay = null;
    });

    try {
      final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/municipalities/$municipalityCode/barangays/'));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          _barangays = data.map((barangay) => {
            'name': barangay['name'],
            'code': barangay['code'],
          }).toList();
          _barangays.sort((a, b) => a['name'].compareTo(b['name']));
          _isBarangaysLoading = false;
        });
      } else {
        // Try fetching barangays for a city instead
        _fetchCityBarangays(municipalityCode);
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
      setState(() {
        _isBarangaysLoading = false;
      });
    }
  }

  // Fetch barangays by city code (for cities)
  Future<void> _fetchCityBarangays(String cityCode) async {
    try {
      final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/cities/$cityCode/barangays/'));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          _barangays = data.map((barangay) => {
            'name': barangay['name'],
            'code': barangay['code'],
          }).toList();
          _barangays.sort((a, b) => a['name'].compareTo(b['name']));
          _isBarangaysLoading = false;
        });
      } else {
        _showErrorSnackBar('Failed to load barangays');
        setState(() {
          _isBarangaysLoading = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
      setState(() {
        _isBarangaysLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color.fromARGB(180, 86, 87, 86),
      ),
    );
  }

  // Function to update address in the backend
  Future<void> _updateAddress() async {
    if (_selectedProvince == null) {
      _showErrorSnackBar('Please select a province');
      return;
    }
    
    if (_selectedMunicipality == null) {
      _showErrorSnackBar('Please select a municipality/city');
      return;
    }
    
    if (_selectedBarangay == null) {
      _showErrorSnackBar('Please select a barangay');
      return;
    }

    if (_houseStreetController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter house number/street');
      return;
    }

    // Concatenate address components
    final String fullAddress = '${_houseStreetController.text.trim()}, '
        '$_selectedBarangay, '
        '$_selectedMunicipality, '
        '$_selectedProvince';

    const String apiUrl = 'http://192.168.1.19:5000/api/update_address';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'address': fullAddress,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          Navigator.pop(context, fullAddress);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address updated successfully!'),
              backgroundColor: Color.fromARGB(180, 86, 87, 86)
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update address: ${data['message'] ?? 'Unknown error'}'),
              backgroundColor: Color.fromARGB(180, 86, 87, 86)
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update address'),
            backgroundColor: Color.fromARGB(180, 86, 87, 86)
          ),
        );
      }
    } catch (e) {
      print('Error updating address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Color.fromARGB(180, 86, 87, 86)
        ),
      );
    }
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
          'Edit Address',
          style: TextStyle(
            fontSize: 17,
            color: Color.fromARGB(255, 88, 88, 88),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _updateAddress,
          ),
        ],
      ),

      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'House No./Street',
                style: TextStyle(fontSize: 14, color: Color.fromARGB(255, 88, 88, 88)),
              ),
              TextField(
                controller: _houseStreetController,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  hintText: 'Enter house number and street name',
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 79, 78, 78),
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 88, 88, 88),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              
              // Province selection
              const Text(
                'Province',
                style: TextStyle(fontSize: 14, color: Color.fromARGB(255, 88, 88, 88)),
              ),
              DropdownButtonFormField<String>(
                value: _selectedProvince,
                hint: const Text('Select Province'),
                isExpanded: true,
                items: _provinces.map((province) {
                  return DropdownMenuItem<String>(
                    value: province['name'],
                    child: Text(province['name'], overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedProvince = value;
                      _selectedProvinceCode = _provinces.firstWhere(
                        (province) => province['name'] == value)['code'];
                    });
                    _fetchMunicipalities(_selectedProvinceCode!);
                  }
                },
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 79, 78, 78),
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 88, 88, 88),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              
              // Municipality/City selection
              const Text(
                'Municipality/City',
                style: TextStyle(fontSize: 14, color: Color.fromARGB(255, 88, 88, 88)),
              ),
              _isMunicipalitiesLoading
                ? const Center(child: LinearProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _selectedMunicipality,
                    hint: const Text('Select Municipality/City'),
                    isExpanded: true,
                    items: _municipalities.map((municipality) {
                      return DropdownMenuItem<String>(
                        value: municipality['name'],
                        child: Text(municipality['name'], overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: _municipalities.isEmpty
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _selectedMunicipality = value;
                                _selectedMunicipalityCode = _municipalities.firstWhere(
                                  (municipality) => municipality['name'] == value)['code'];
                              });
                              _fetchBarangays(_selectedMunicipalityCode!);
                            }
                          },
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 79, 78, 78),
                          width: 0.5,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 88, 88, 88),
                          width: 0.8,
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 25),
              
              // Barangay selection
              const Text(
                'Barangay',
                style: TextStyle(fontSize: 14, color: Color.fromARGB(255, 88, 88, 88)),
              ),
              _isBarangaysLoading
                ? const Center(child: LinearProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _selectedBarangay,
                    hint: const Text('Select Barangay'),
                    isExpanded: true,
                    items: _barangays.map((barangay) {
                      return DropdownMenuItem<String>(
                        value: barangay['name'],
                        child: Text(barangay['name'], overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: _barangays.isEmpty
                        ? null 
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _selectedBarangay = value;
                              });
                            }
                          },
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 79, 78, 78),
                          width: 0.5,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 88, 88, 88),
                          width: 0.8,
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 30),
              
              // Display full address preview
              if (_selectedBarangay != null)
                Card(
                  color: Colors.white,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Address Preview',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 88, 88, 88),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_houseStreetController.text}\n'
                          '$_selectedBarangay\n'
                          '$_selectedMunicipality, $_selectedProvince',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color.fromARGB(255, 88, 88, 88),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
    );
  }
}