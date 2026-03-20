import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HealthData {
  final String userName;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  final double calcium;
  final int steps;
  final double water;
  final double height;
  final double weight;
  final String email;
  final String phone;
  final double calorieGoal;
  final double proteinGoal;
  final double carbsGoal;
  final double fatsGoal;
  final double waterGoal;
  final int stepGoal;

  HealthData({
    this.userName = "John Doe",
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fats = 0,
    this.calcium = 0,
    this.steps = 0,
    this.water = 0,
    this.height = 170,
    this.weight = 70,
    this.email = "john.doe@example.com",
    this.phone = "+91 98765 43210",
    this.calorieGoal = 2000,
    this.proteinGoal = 80,
    this.carbsGoal = 250,
    this.fatsGoal = 65,
    this.waterGoal = 3.0,
    this.stepGoal = 10000,
  });

  HealthData copyWith({
    String? userName,
    double? calories,
    double? protein,
    double? carbs,
    double? fats,
    double? calcium,
    int? steps,
    double? water,
    double? height,
    double? weight,
    String? email,
    String? phone,
    double? calorieGoal,
    double? proteinGoal,
    double? carbsGoal,
    double? fatsGoal,
    double? waterGoal,
    int? stepGoal,
  }) {
    return HealthData(
      userName: userName ?? this.userName,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      calcium: calcium ?? this.calcium,
      steps: steps ?? this.steps,
      water: water ?? this.water,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbsGoal: carbsGoal ?? this.carbsGoal,
      fatsGoal: fatsGoal ?? this.fatsGoal,
      waterGoal: waterGoal ?? this.waterGoal,
      stepGoal: stepGoal ?? this.stepGoal,
    );
  }
}

class HealthService extends ChangeNotifier {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  HealthData _currentData = HealthData(
    userName: "John Doe",
    calories: 1240,
    protein: 45,
    carbs: 120,
    fats: 50,
    calcium: 400,
    steps: 6432,
    water: 1.2,
    height: 178,
    weight: 74,
    email: "john.doe@example.com",
    phone: "+91 98765 43210",
  );

  HealthData get currentData => _currentData;

  void updateProfile({String? name, double? height, double? weight, String? email, String? phone}) {
    _currentData = _currentData.copyWith(
      userName: name,
      height: height,
      weight: weight,
      email: email,
      phone: phone,
    );
    notifyListeners();
  }

  void updateGoals({
    double? calorieGoal,
    double? proteinGoal,
    double? carbsGoal,
    double? fatsGoal,
    double? waterGoal,
    int? stepGoal,
  }) {
    _currentData = _currentData.copyWith(
      calorieGoal: calorieGoal,
      proteinGoal: proteinGoal,
      carbsGoal: carbsGoal,
      fatsGoal: fatsGoal,
      waterGoal: waterGoal,
      stepGoal: stepGoal,
    );
    notifyListeners();
  }

  void addFood(double calories, double protein, double carbs, double fats, double calcium) {
    _currentData = _currentData.copyWith(
      calories: _currentData.calories + calories,
      protein: _currentData.protein + protein,
      carbs: _currentData.carbs + carbs,
      fats: _currentData.fats + fats,
      calcium: _currentData.calcium + calcium,
    );
    notifyListeners();
  }

  void addWater(double amount) {
    _currentData = _currentData.copyWith(water: _currentData.water + amount);
    notifyListeners();
  }

  void addSteps(int count) {
    _currentData = _currentData.copyWith(steps: _currentData.steps + count);
    notifyListeners();
  }

  Future<void> fetchTodayLogs() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final startOfDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).toIso8601String();
    
    try {
      final response = await Supabase.instance.client
          .from('food_logs')
          .select()
          .eq('user_id', user.id)
          .gte('created_at', startOfDay);

      double loadedCals = 0;
      double loadedProtein = 0;
      double loadedCarbs = 0;
      double loadedFats = 0;

      for (var log in response) {
        loadedCals += (log['calories'] ?? 0);
        loadedProtein += (log['protein'] ?? 0);
        loadedCarbs += (log['carbs'] ?? 0);
        loadedFats += (log['fats'] ?? 0);
      }

      _currentData = _currentData.copyWith(
        calories: loadedCals,
        protein: loadedProtein,
        carbs: loadedCarbs,
        fats: loadedFats,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching logs: $e');
    }
  }

  Future<int> getDailyStreak() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 0;
    
    try {
      final startOfDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).toIso8601String();
      final count = await Supabase.instance.client
          .from('food_logs')
          .select('id')
          .eq('user_id', user.id)
          .gte('created_at', startOfDay)
          .count(CountOption.exact);
      
      return (count.count > 0) ? 1 : 0; 
    } catch (_) {
      return 1;
    }
  }
}
