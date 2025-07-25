// import 'package:flutter/foundation.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/user.dart';
//
// class AuthService extends ChangeNotifier {
//   User? _currentUser;
//   bool _isAuthenticated = false;
//   bool _isLoading = false;
//
//   User? get currentUser => _currentUser;
//   bool get isAuthenticated => _isAuthenticated;
//   bool get isLoading => _isLoading;
//
//   // Initialize service and check for saved user
//   Future<void> initialize() async {
//     _isLoading = true;
//     notifyListeners();
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userJson = prefs.getString('current_user');
//
//       if (userJson != null) {
//         // In a real app, you would validate the token here
//         _isAuthenticated = true;
//         // Parse user from JSON if needed
//       }
//     } catch (e) {
//       debugPrint('Error initializing auth service: $e');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   // Login user
//   Future<void> login(String email, String password) async {
//     _isLoading = true;
//     notifyListeners();
//
//     try {
//       // Simulate API call
//       await Future.delayed(const Duration(seconds: 2));
//
//       // In a real app, you would make an HTTP request here
//       if (email.isNotEmpty && password.length >= 6) {
//         _currentUser = User(
//           name: 'Utilisateur Test',
//           email: email,
//           avatarUrl: null,
//           isPremium: false,
//         );
//
//         _isAuthenticated = true;
//
//         // Save user to preferences
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString('current_user', _currentUser!.toJson().toString());
//         await prefs.setBool('is_authenticated', true);
//
//       } else {
//         throw Exception('Email ou mot de passe invalide');
//       }
//     } catch (e) {
//       rethrow;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   // Register user
//   Future<void> register(String name, String email, String password) async {
//     _isLoading = true;
//     notifyListeners();
//
//     try {
//       // Simulate API call
//       await Future.delayed(const Duration(seconds: 2));
//
//       // In a real app, you would make an HTTP request here
//       if (name.isNotEmpty && email.isNotEmpty && password.length >= 6) {
//         _currentUser = User(
//           name: name,
//           email: email,
//           avatarUrl: null,
//           isPremium: false,
//         );
//
//         _isAuthenticated = true;
//
//         // Save user to preferences
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString('current_user', _currentUser!.toJson().toString());
//         await prefs.setBool('is_authenticated', true);
//
//       } else {
//         throw Exception('Informations invalides');
//       }
//     } catch (e) {
//       rethrow;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   // Logout user
//   Future<void> logout() async {
//     _isLoading = true;
//     notifyListeners();
//
//     try {
//       // Clear preferences
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.remove('current_user');
//       await prefs.setBool('is_authenticated', false);
//
//       _currentUser = null;
//       _isAuthenticated = false;
//
//     } catch (e) {
//       debugPrint('Error during logout: $e');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   // Update user profile
//   Future<void> updateProfile({
//     String? name,
//     String? avatarUrl,
//     Map<String, dynamic>? preferences,
//   }) async {
//     if (_currentUser == null) return;
//
//     _isLoading = true;
//     notifyListeners();
//
//     try {
//       _currentUser = _currentUser!.copyWith(
//         name: name,
//         avatarUrl: avatarUrl,
//         preferences: preferences,
//       );
//
//       // Save updated user
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('current_user', _currentUser!.toJson().toString());
//
//     } catch (e) {
//       debugPrint('Error updating profile: $e');
//       rethrow;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   // Check if email is available
//   Future<bool> isEmailAvailable(String email) async {
//     // Simulate API call
//     await Future.delayed(const Duration(milliseconds: 500));
//
//     // In a real app, you would check with your backend
//     return !email.contains('taken');
//   }
//
//   // Reset password
//   Future<void> resetPassword(String email) async {
//     _isLoading = true;
//     notifyListeners();
//
//     try {
//       // Simulate API call
//       await Future.delayed(const Duration(seconds: