import '../services/api_service.dart';
import 'package:flutter/foundation.dart';

class UserProvider with ChangeNotifier {
  String _mode = "createdAt"; // Default sort mode
  String _order = "asc"; // Default sort order

  String get mode => _mode;
  String get order => _order;

  void updateSortPreference(String mode, String order) async {
    try{
      final success = await ApiService.updateSortPreference(mode, order);
      if(success){
        _mode = mode;
        _order = order;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating sort preference: $e');
      }
    }
  }
}
