import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  authenticating,
}

class AuthService extends ChangeNotifier {
  AuthStatus _status = AuthStatus.uninitialized;
  User? _currentUser;
  String? _token;
  Timer? _tokenRefreshTimer;

  // Simulation d'une base de données locale
  final Map<String, Map<String, dynamic>> _usersDatabase = {
    'user@example.com': {
      'id': '1',
      'name': 'John Doe',
      'email': 'user@example.com',
      'password': 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', // secret123
      'profilePicture': null,
      'createdAt': '2024-01-15T10:30:00Z',
      'lastLoginAt': null,
      'isEmailVerified': true,
      'totalChats': 15,
      'totalMessages': 456,
      'totalTimeSpent': 24,
    }
  };

  AuthService() {
    _initializeAuth();
  }

  // Getters
  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.authenticating;

  Future<void> _initializeAuth() async {
    try {
      // Simuler le chargement des données stockées localement
      await Future.delayed(const Duration(milliseconds: 500));

      // Vérifier si un token existe en stockage local
      // Dans une vraie application, utilisez SharedPreferences
      final savedToken = await _getStoredToken();
      final savedUserId = await _getStoredUserId();

      if (savedToken != null && savedUserId != null) {
        // Valider le token
        final isValid = await _validateToken(savedToken);
        if (isValid) {
          _token = savedToken;
          _currentUser = await _getUserById(savedUserId);
          _status = AuthStatus.authenticated;
          _startTokenRefreshTimer();
        } else {
          await _clearStoredAuth();
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Connexion avec email et mot de passe
  Future<AuthResult> signIn(String email, String password) async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      // Simuler une requête réseau
      await Future.delayed(const Duration(seconds: 1));

      // Valider le format de l'email
      if (!_isValidEmail(email)) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return AuthResult(
          success: false,
          message: 'Format d\'email invalide',
        );
      }

      // Hasher le mot de passe pour la comparaison
      final hashedPassword = _hashPassword(password);

      // Vérifier les credentials dans la "base de données"
      final userData = _usersDatabase[email.toLowerCase()];
      if (userData == null || userData['password'] != hashedPassword) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return AuthResult(
          success: false,
          message: 'Email ou mot de passe incorrect',
        );
      }

      // Créer un token d'authentification
      _token = _generateToken(userData['id']);

      // Créer l'objet utilisateur
      _currentUser = User(
        id: userData['id'],
        name: userData['name'],
        email: userData['email'],
        profilePicture: userData['profilePicture'],
        createdAt: DateTime.parse(userData['createdAt']),
        lastLoginAt: DateTime.now(),
        isEmailVerified: userData['isEmailVerified'],
        totalChats: userData['totalChats'],
        totalMessages: userData['totalMessages'],
        totalTimeSpent: userData['totalTimeSpent'],
      );

      // Mettre à jour la dernière connexion
      _usersDatabase?[email];

      // Sauvegarder en local
      await _saveAuthData();

      _status = AuthStatus.authenticated;
      _startTokenRefreshTimer();
      notifyListeners();

      return AuthResult(
        success: true,
        message: 'Connexion réussie',
        user: _currentUser,
      );
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return AuthResult(
        success: false,
        message: 'Erreur de connexion: ${e.toString()}',
      );
    }
  }

  /// Inscription avec email, nom et mot de passe
  Future<AuthResult> signUp(String name, String email, String password) async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      // Validations
      if (name.trim().length < 2) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return AuthResult(
          success: false,
          message: 'Le nom doit contenir au moins 2 caractères',
        );
      }

      if (!_isValidEmail(email)) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return AuthResult(
          success: false,
          message: 'Format d\'email invalide',
        );
      }

      if (password.length < 6) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return AuthResult(
          success: false,
          message: 'Le mot de passe doit contenir au moins 6 caractères',
        );
      }

      // Vérifier si l'email existe déjà
      if (_usersDatabase.containsKey(email.toLowerCase())) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return AuthResult(
          success: false,
          message: 'Un compte avec cet email existe déjà',
        );
      }

      // Créer un nouvel utilisateur
      final userId = _generateUserId();
      final hashedPassword = _hashPassword(password);
      final now = DateTime.now();

      _usersDatabase[email.toLowerCase()] = {
        'id': userId,
        'name': name.trim(),
        'email': email.toLowerCase(),
        'password': hashedPassword,
        'profilePicture': null,
        'createdAt': now.toIso8601String(),
        'lastLoginAt': now.toIso8601String(),
        'isEmailVerified': false,
        'totalChats': 0,
        'totalMessages': 0,
        'totalTimeSpent': 0,
      };

      // Créer le token
      _token = _generateToken(userId);

      // Créer l'objet utilisateur
      _currentUser = User(
        id: userId,
        name: name.trim(),
        email: email.toLowerCase(),
        profilePicture: null,
        createdAt: now,
        lastLoginAt: now,
        isEmailVerified: false,
        totalChats: 0,
        totalMessages: 0,
        totalTimeSpent: 0,
      );

      await _saveAuthData();

      _status = AuthStatus.authenticated;
      _startTokenRefreshTimer();
      notifyListeners();

      return AuthResult(
        success: true,
        message: 'Compte créé avec succès',
        user: _currentUser,
      );
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return AuthResult(
        success: false,
        message: 'Erreur lors de la création du compte: ${e.toString()}',
      );
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      _tokenRefreshTimer?.cancel();
      await _clearStoredAuth();

      _currentUser = null;
      _token = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
    }
  }

  /// Réinitialisation du mot de passe
  Future<AuthResult> resetPassword(String email) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      if (!_isValidEmail(email)) {
        return AuthResult(
          success: false,
          message: 'Format d\'email invalide',
        );
      }

      if (!_usersDatabase.containsKey(email.toLowerCase())) {
        return AuthResult(
          success: false,
          message: 'Aucun compte trouvé avec cet email',
        );
      }

      // Simuler l'envoi d'un email de réinitialisation
      return AuthResult(
        success: true,
        message: 'Email de réinitialisation envoyé',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Erreur lors de la réinitialisation: ${e.toString()}',
      );
    }
  }

  /// Changer le mot de passe
  Future<AuthResult> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) {
      return AuthResult(
        success: false,
        message: 'Utilisateur non connecté',
      );
    }

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final userData = _usersDatabase[_currentUser!.email];
      if (userData == null) {
        return AuthResult(
          success: false,
          message: 'Utilisateur introuvable',
        );
      }

      // Vérifier le mot de passe actuel
      final hashedCurrentPassword = _hashPassword(currentPassword);
      if (userData['password'] != hashedCurrentPassword) {
        return AuthResult(
          success: false,
          message: 'Mot de passe actuel incorrect',
        );
      }

      if (newPassword.length < 6) {
        return AuthResult(
          success: false,
          message: 'Le nouveau mot de passe doit contenir au moins 6 caractères',
        );
      }

      // Mettre à jour le mot de passe
      userData['password'] = _hashPassword(newPassword);

      return AuthResult(
        success: true,
        message: 'Mot de passe modifié avec succès',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Erreur lors du changement de mot de passe: ${e.toString()}',
      );
    }
  }

  /// Mettre à jour le profil utilisateur
  Future<AuthResult> updateProfile({
    String? name,
    String? profilePicture,
  }) async {
    if (_currentUser == null) {
      return AuthResult(
        success: false,
        message: 'Utilisateur non connecté',
      );
    }

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final userData = _usersDatabase[_currentUser!.email];
      if (userData == null) {
        return AuthResult(
          success: false,
          message: 'Utilisateur introuvable',
        );
      }

      // Mettre à jour les données
      if (name != null && name.trim().isNotEmpty) {
        userData['name'] = name.trim();
      }
      if (profilePicture != null) {
        userData['profilePicture'] = profilePicture;
      }

      // Mettre à jour l'objet utilisateur local
      _currentUser = _currentUser!.copyWith(
        name: userData['name'],
        profilePicture: userData['profilePicture'],
      );

      await _saveAuthData();
      notifyListeners();

      return AuthResult(
        success: true,
        message: 'Profil mis à jour avec succès',
        user: _currentUser,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Erreur lors de la mise à jour: ${e.toString()}',
      );
    }
  }

  /// Supprimer le compte
  Future<AuthResult> deleteAccount(String password) async {
    if (_currentUser == null) {
      return AuthResult(
        success: false,
        message: 'Utilisateur non connecté',
      );
    }

    try {
      await Future.delayed(const Duration(seconds: 1));

      final userData = _usersDatabase[_currentUser!.email];
      if (userData == null) {
        return AuthResult(
          success: false,
          message: 'Utilisateur introuvable',
        );
      }

      // Vérifier le mot de passe
      final hashedPassword = _hashPassword(password);
      if (userData['password'] != hashedPassword) {
        return AuthResult(
          success: false,
          message: 'Mot de passe incorrect',
        );
      }

      // Supprimer l'utilisateur
      _usersDatabase.remove(_currentUser!.email);

      // Déconnecter
      await logout();

      return AuthResult(
        success: true,
        message: 'Compte supprimé avec succès',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Erreur lors de la suppression: ${e.toString()}',
      );
    }
  }

  // Méthodes privées

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateToken(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '$userId:$timestamp';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return 'token_${digest.toString()}';
  }

  String _generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<bool> _validateToken(String token) async {
    // Simuler la validation du token
    await Future.delayed(const Duration(milliseconds: 200));
    return token.startsWith('token_');
  }

  Future<User?> _getUserById(String userId) async {
    for (final userData in _usersDatabase.values) {
      if (userData['id'] == userId) {
        return User(
          id: userData['id'],
          name: userData['name'],
          email: userData['email'],
          profilePicture: userData['profilePicture'],
          createdAt: DateTime.parse(userData['createdAt']),
          lastLoginAt: userData['lastLoginAt'] != null
              ? DateTime.parse(userData['lastLoginAt'])
              : null,
          isEmailVerified: userData['isEmailVerified'],
          totalChats: userData['totalChats'],
          totalMessages: userData['totalMessages'],
          totalTimeSpent: userData['totalTimeSpent'],
        );
      }
    }
    return null;
  }

  void _startTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(
      const Duration(minutes: 30),
          (timer) => _refreshToken(),
    );
  }

  Future<void> _refreshToken() async {
    if (_currentUser != null) {
      _token = _generateToken(_currentUser!.id);
      await _saveAuthData();
    }
  }

  Future<void> _saveAuthData() async {
    // Simuler la sauvegarde en local
    // Dans une vraie application, utilisez SharedPreferences
    debugPrint('Sauvegarde des données d\'authentification');
  }

  Future<String?> _getStoredToken() async {
    // Simuler la récupération du token stocké
    return null;
  }

  Future<String?> _getStoredUserId() async {
    // Simuler la récupération de l'ID utilisateur stocké
    return null;
  }

  Future<void> _clearStoredAuth() async {
    // Simuler la suppression des données stockées
    debugPrint('Suppression des données d\'authentification stockées');
  }

  @override
  void dispose() {
    _tokenRefreshTimer?.cancel();
    super.dispose();
  }
}

class AuthResult {
  final bool success;
  final String message;
  final User? user;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}