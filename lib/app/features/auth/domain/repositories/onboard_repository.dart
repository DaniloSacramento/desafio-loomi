abstract class OnboardRepository {
  Future<void> completeOnboarding();
  Future<Map<String, dynamic>> getUserData();
  Future<void> updateUserData(Map<String, dynamic> data);
  Future<void> deleteUser();
}
