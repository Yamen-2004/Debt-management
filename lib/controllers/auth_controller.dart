import 'package:get/get.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  final isLoading = false.obs;
  final errorMessage = RxnString();

  bool get isLoggedIn => _authService.isLoggedIn();

  Future<bool> login(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      errorMessage.value = 'Please enter email and password';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final user = await _authService.login(email, password);

      // Make sure a shop document exists for this account.
      // Developers can edit shopName/ownerName later in Firebase Console.
      if (user != null) {
        await _firestoreService.createShopIfNotExists(
          shopName: 'My Shop',
          ownerName: user.email ?? 'Owner',
        );
      }

      return true;
    } catch (e) {
      errorMessage.value = _mapError(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  String _mapError(dynamic e) {
    final message = e.toString();
    if (message.contains('user-not-found') ||
        message.contains('wrong-password') ||
        message.contains('invalid-credential')) {
      return 'Invalid email or password';
    }
    return 'Login failed. Please try again';
  }
}
