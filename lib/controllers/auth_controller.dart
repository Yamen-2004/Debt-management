import 'package:firebase_auth/firebase_auth.dart';
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
      errorMessage.value = 'الرجاء إدخال البريد الإلكتروني وكلمة المرور';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final user = await _authService.login(email, password);

      // التأكد من وجود مستند المتجر لهذا الحساب.
      // يمكن تعديل shopName/ownerName لاحقاً من Firebase Console.
      if (user != null) {
        await _firestoreService.createShopIfNotExists(
          shopName: 'متجري',
          ownerName: user.email ?? 'المالك',
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
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-email':
          return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
        case 'user-disabled':
          return 'تم تعطيل هذا الحساب';
        case 'too-many-requests':
          return 'محاولات كثيرة، حاول لاحقاً';
        case 'network-request-failed':
          return 'تحقق من اتصالك بالإنترنت';
      }
    }
    return 'فشل تسجيل الدخول، حاول مرة أخرى';
  }
}
