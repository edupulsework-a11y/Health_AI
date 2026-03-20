import 'package:flutter/material.dart';

enum AccountType { user, specialist }

class UserData {
  final String name;
  final String email;
  final String? phone;
  final int age;
  final double? weight;
  final double? height;
  final String gender;
  final String category; // e.g., Teenager, Working Professional
  final AccountType accountType;
  final bool isAbhaVerified;
  final String? dietaryPreference;
  final String? activityLevel;
  final String? specialization;

  UserData({
    required this.name,
    required this.email,
    this.phone,
    required this.age,
    this.weight,
    this.height,
    required this.gender,
    required this.category,
    this.accountType = AccountType.user,
    this.isAbhaVerified = false,
    this.specialization,
    this.dietaryPreference,
    this.activityLevel,
  });

  bool get isFemale => gender.toLowerCase() == 'female';
}

// Mock user data for demonstration
final mockUser = UserData(
  name: 'John Doe',
  email: 'john.doe@example.com',
  age: 28,
  gender: 'Male',
  category: 'Working Professional',
  accountType: AccountType.user,
  weight: 75.0,
  height: 180.0,
);

final mockSpecialist = UserData(
  name: 'Dr. Sarah Smith',
  email: 'sarah.smith@healthai.com',
  age: 35,
  gender: 'Female',
  category: 'Specialist',
  accountType: AccountType.specialist,
  isAbhaVerified: true,
  specialization: 'Physiotherapist',
);
