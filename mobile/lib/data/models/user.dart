class User {
  const User({
    required this.id,
    this.email,
    this.phone,
    required this.displayName,
    this.authProvider = 'email',
    this.role = 'user',
    this.onboardingCompleted = false,
    this.onboardingStep = 'body_stats',
    this.createdAt,
  });

  final String id;
  final String? email;
  final String? phone;
  final String displayName;
  final String authProvider;
  final String role;
  final bool onboardingCompleted;
  final String onboardingStep;
  final DateTime? createdAt;

  bool get isAdmin => role == 'admin';
  bool get needsOnboarding => !isAdmin && !onboardingCompleted;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      displayName: (json['displayName'] as String?) ?? '',
      authProvider: (json['authProvider'] as String?) ?? 'email',
      role: (json['role'] as String?) ?? 'user',
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      onboardingStep: (json['onboardingStep'] as String?) ?? 'body_stats',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'displayName': displayName,
      'authProvider': authProvider,
      'role': role,
      'onboardingCompleted': onboardingCompleted,
      'onboardingStep': onboardingStep,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  User copyWith({
    bool? onboardingCompleted,
    String? onboardingStep,
    String? role,
  }) {
    return User(
      id: id,
      email: email,
      phone: phone,
      displayName: displayName,
      authProvider: authProvider,
      role: role ?? this.role,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      createdAt: createdAt,
    );
  }
}
