import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../grama_niladhari/grama_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class EditCampaignScreen extends StatefulWidget {
  final String campaignId;
  
  const EditCampaignScreen({
    super.key, 
    required this.campaignId,
  });

  @override
  State<EditCampaignScreen> createState() => _EditCampaignScreenState();
}

class _EditCampaignScreenState extends State<EditCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _foodInNeedController = TextEditingController();
  String? _selectedUrgency;
  String? _selectedDistrict;
  File? _imageFile;
  String? _currentImageUrl;
  bool _isLoading = false;
  bool _isLoadingData = true;
  
  final ImagePicker _picker = ImagePicker();

  final List<String> _urgencyLevels = ['High', 'Medium', 'Low'];
  final List<String> _districts = [
    'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo',
    'Galle', 'Gampaha', 'Hambantota', 'Jaffna', 'Kalutara',
    'Kandy', 'Kegalle', 'Kilinochchi', 'Kurunegala', 'Mannar',
    'Matale', 'Matara', 'Monaragala', 'Mullaitivu', 'Nuwara Eliya',
    'Polonnaruwa', 'Puttalam', 'Ratnapura', 'Trincomalee', 'Vavuniya'
  ];
  
  @override
  void initState() {
    super.initState();
    _loadCampaignData();
  }
  
  Future<void> _loadCampaignData() async {
    setState(() {
      _isLoadingData = true;
    });
    
    try {
      // Load campaign data from Firestore
      final campaignDoc = await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(widget.campaignId)
          .get();
          
      if (!campaignDoc.exists) {
        throw Exception('Campaign not found');
      }
      
      final data = campaignDoc.data()!;
      
      // Set form values
      _titleController.text = data['title'] ?? '';
      _locationController.text = data['location'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _foodInNeedController.text = data['foodInNeed'] ?? '';
      _selectedUrgency = data['urgency'];
      _selectedDistrict = data['district'];
      _currentImageUrl = data['imageUrl'];
      
    } catch (e) {
      debugPrint('Error loading campaign data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load campaign: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _currentImageUrl; // Return existing URL if no new image
    
    try {
      // Create a unique filename
      final fileName = const Uuid().v4() + path.extension(_imageFile!.path);
      
      // Reference to storage root
      final storageRef = FirebaseStorage.instance.ref();
      
      // Reference to image file
      final campaignImageRef = storageRef.child('campaign_images/$fileName');
      
      // Upload the file
      await campaignImageRef.putFile(_imageFile!);
      
      // Get download URL
      final downloadUrl = await campaignImageRef.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return _currentImageUrl; // Return existing URL if upload fails
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Upload image and get URL
        final imageUrl = await _uploadImage();
        
        // Create updated campaign data
        final updatedData = {
          'title': _titleController.text,
          'urgency': _selectedUrgency,
          'district': _selectedDistrict,
          'location': _locationController.text,
          'description': _descriptionController.text,
          'foodInNeed': _foodInNeedController.text,
          'imageUrl': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        // Update Firestore document
        await FirebaseFirestore.instance
            .collection('campaigns')
            .doc(widget.campaignId)
            .update(updatedData);
        
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Campaign updated successfully!'),
              backgroundColor: Color(0xFF4D9164),
            ),
          );
          
          // Navigate back to the grama niladhari home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const GramaHomeScreen(),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error updating campaign: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update campaign: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF4D9164),
          title: const Text('Edit Donation'),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4D9164),
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4D9164),
        title: const Text('Edit Donation'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Donation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter a post title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Urgency dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Urgency status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  hint: const Text('Select Urgency status'),
                  value: _selectedUrgency,
                  items: _urgencyLevels.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedUrgency = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an urgency level';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // District dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'District',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  hint: const Text('Select District'),
                  value: _selectedDistrict,
                  items: _districts.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedDistrict = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a district';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Location field
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    hintText: 'Type Location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Type Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Food in need field
                TextFormField(
                  controller: _foodInNeedController,
                  decoration: InputDecoration(
                    labelText: 'Food in need',
                    hintText: 'Type Food in need',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter food items needed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Image picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _imageFile!,
                              width: double.infinity,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                        : _currentImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _currentImageUrl!,
                                  width: double.infinity,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add, size: 24),
                                    SizedBox(height: 4),
                                    Text('Add an Image'),
                                  ],
                                ),
                              ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Update button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4D9164),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Update',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _foodInNeedController.dispose();
    super.dispose();
  }
} 