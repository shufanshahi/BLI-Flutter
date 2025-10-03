import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student ID Card',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const StudentIDCard(),
    );
  }
}

class StudentIDCard extends StatefulWidget {
  const StudentIDCard({super.key});

  @override
  State<StudentIDCard> createState() => _StudentIDCardState();
}

class _StudentIDCardState extends State<StudentIDCard> {
  Color _headerFooterColor = const Color(0xFF2E4A3A);
  TextStyle _headerFooterTextStyle = const TextStyle();
  final Random _random = Random();
  
  // Edit mode and student data variables
  bool _isEditMode = true;
  final TextEditingController _studentIdController = TextEditingController(text: '210041210');
  final TextEditingController _studentNameController = TextEditingController(text: 'SHUFAN SHAHI');
  final TextEditingController _programController = TextEditingController(text: 'B.Sc. in CSE');
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  
  // List of colors for random selection
  final List<Color> _colors = [
    const Color(0xFF2E4A3A), // Original dark green
    Colors.blue[800]!,
    Colors.red[800]!,
    Colors.purple[800]!,
    Colors.indigo[800]!,
    Colors.teal[800]!,
    Colors.brown[800]!,
    Colors.orange[800]!,
  ];
  
  // List of Google Fonts for random selection
  final List<String> _fontFamilies = [
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Raleway',
    'PT Sans',
    'Lora',
    'Merriweather',
    'Playfair Display',
  ];
  
  void _changeBackgroundColor() {
    setState(() {
      _headerFooterColor = _colors[_random.nextInt(_colors.length)];
    });
  }
  
  void _changeFont() {
    setState(() {
      final fontFamily = _fontFamilies[_random.nextInt(_fontFamilies.length)];
      _headerFooterTextStyle = GoogleFonts.getFont(fontFamily);
    });
  }
  
  Future<void> _pickImage() async {
    try {
      if (kIsWeb || Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        // Use file_picker for desktop platforms
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        
        if (result != null && result.files.single.path != null) {
          setState(() {
            _selectedImage = File(result.files.single.path!);
          });
        }
      } else {
        // Use image_picker for mobile platforms
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          setState(() {
            _selectedImage = File(image.path);
          });
        }
      }
    } catch (e) {
      // Show error dialog if image selection fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _saveData() {
    setState(() {
      _isEditMode = false;
    });
  }
  
  void _editData() {
    setState(() {
      _isEditMode = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isEditMode) ...[
              // Edit mode - Show form
              _buildEditForm(),
            ] else ...[
              // View mode - Show card with buttons
              // Style buttons outside the main container
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _changeBackgroundColor,
                    icon: const Icon(Icons.color_lens),
                    label: const Text('Change Color'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _changeFont,
                    icon: const Icon(Icons.font_download),
                    label: const Text('Change Font'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _editData,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Main ID Card Container
              _buildIDCard(),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildEditForm() {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Student Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E4A3A),
            ),
          ),
          const SizedBox(height: 20),
          
          // Student Photo Section
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[400]!, width: 2),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Tap to add photo', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Select Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E4A3A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Student ID Field
          TextField(
            controller: _studentIdController,
            decoration: const InputDecoration(
              labelText: 'Student ID',
              prefixIcon: Icon(Icons.credit_card),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Student Name Field
          TextField(
            controller: _studentNameController,
            decoration: const InputDecoration(
              labelText: 'Student Name',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Program Field
          TextField(
            controller: _programController,
            decoration: const InputDecoration(
              labelText: 'Program',
              prefixIcon: Icon(Icons.school),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveData,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIDCard() {
    return Container(
      width: 320,
      height: 500,
      child: Column(
        children: [
          // Header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: _headerFooterColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // University logo/crest placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.green[700]!, width: 2),
                  ),
                  child: Icon(
                    Icons.school,
                    color: Colors.green[700],
                    size: 30,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ISLAMIC UNIVERSITY OF TECHNOLOGY',
                  style: _headerFooterTextStyle.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Main content section
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Student photo
                    Container(
                      width: 120,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: _selectedImage != null
                            ? Image.file(
                                _selectedImage!,
                                width: 116,
                                height: 136,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'assets/images/student_photo.jpg',
                                width: 116,
                                height: 136,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Student information
                    _buildInfoRow(Icons.credit_card, 'Student ID', _studentIdController.text),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.person, 'Student Name', _studentNameController.text),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.school, 'Program', _programController.text),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
          
          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _headerFooterColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              'A subsidiary organ of OIC',
              style: _headerFooterTextStyle.copyWith(
                color: Colors.white,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF2E4A3A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: _headerFooterTextStyle.copyWith(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: _headerFooterTextStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}