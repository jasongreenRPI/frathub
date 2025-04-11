import 'package:flutter/material.dart';
import '../services/user_service.dart';


/// UserProfileScreen widget that displays and allows editing of user profile information.
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _obscureText = true;
  
  // Get access to our user service
  final _userService = UserService();
  
  // Text controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController; 
  late TextEditingController _dobController;
  late TextEditingController _affiliationController;
  late TextEditingController _positionController;
  
  @override
  void initState() {
    super.initState();
    
    // Get the current logged in user
    final user = _userService.currentUser;
    
    // Initialize controllers with user data
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _passwordController = TextEditingController(text: '••••••••••'); // Don't show actual password
    _dobController = TextEditingController(text: user?.dob ?? '');
    _affiliationController = TextEditingController(text: user?.affiliation ?? '');
    _positionController = TextEditingController(text: user?.position ?? '');
  }
  

  /// Dispose method to clean up controllers
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _affiliationController.dispose();
    _positionController.dispose();
    super.dispose();
  }


  // Build method to create the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B0082),
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: const Color(0xFF4B0082),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'User Profile',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // Name
              _buildInputLabel('Name'),
              _buildTextField(
                controller: _nameController,
              ),
              const SizedBox(height: 20),
              
              // Email (read-only)
              _buildInputLabel('Email'),
              _buildTextField(
                controller: _emailController,
                readOnly: true, // Email can't be changed
              ),
              const SizedBox(height: 20),
              
              // Password field (just for show, not editable)
              _buildInputLabel('Password'),
              _buildTextField(
                controller: _passwordController,
                isPassword: true,
                readOnly: true, // Password isn't actually editable here
              ),
              const SizedBox(height: 20),
              
              // Date of Birth
              _buildInputLabel('Date Of Birth'),
              _buildTextField(
                controller: _dobController,
                isDropdown: true,
                onTap: () => _showDatePicker(),
              ),
              const SizedBox(height: 20),
              
              // Affiliation Status
              _buildInputLabel('Affiliation Status'),
              _buildTextField(
                controller: _affiliationController,
              ),
              const SizedBox(height: 20),
              
              // Fraternity Position
              _buildInputLabel('Fraternity Position'),
              _buildTextField(
                controller: _positionController,
                isDropdown: true,
                onTap: () => _showPositionDropdown(),
              ),
              const SizedBox(height: 30),
              
              // Save Changes button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(const Color(0xFF240041)),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                    padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  onPressed: _saveProfile,
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper methods to build UI components
  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }
  

  // Helper method to build text fields
  Widget _buildTextField({
    required TextEditingController controller,
    bool isPassword = false,
    bool isDropdown = false,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      readOnly: readOnly || isDropdown,
      onTap: onTap,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        suffixIcon: isPassword && !readOnly
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : isDropdown
                ? const Icon(Icons.arrow_drop_down, color: Colors.grey)
                : null,
      ),
    );
  }
  

  // Show date picker dialog
  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1999, 2, 7),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4B0082),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }
  
  // Show position dropdown
  void _showPositionDropdown() {
    final positions = ['President', 'Vice President', 'Treasurer', 'Secretary', 'Member'];
    
    // Show bottom sheet with list of positions
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Select Position',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 0),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: positions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(positions[index]),
                    onTap: () {
                      setState(() {
                        _positionController.text = positions[index];
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  

  // Save profile changes
  void _saveProfile() {
    // Update user data in the service
    _userService.updateProfile(
      name: _nameController.text,
      dob: _dobController.text,
      affiliation: _affiliationController.text,
      position: _positionController.text,
    );
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}