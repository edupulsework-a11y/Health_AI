enum UserRole {
  regular,
  pregnant,
  parent,
  fitness,
  professional;

  String get displayName {
    switch (this) {
      case UserRole.regular:
        return 'Regular User';
      case UserRole.pregnant:
        return 'Pregnant User';
      case UserRole.parent:
        return 'Parent (Newborn)';
      case UserRole.fitness:
        return 'Fitness User';
      case UserRole.professional:
        return 'Professional';
    }
  }

  String get emoji {
    switch (this) {
      case UserRole.regular:
        return '🧑';
      case UserRole.pregnant:
        return '🤰';
      case UserRole.parent:
        return '👶';
      case UserRole.fitness:
        return '💪';
      case UserRole.professional:
        return '🩺';
    }
  }

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.regular,
    );
  }
}
