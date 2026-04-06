enum UserTier { free, premium }

class UserProperties {
  final String? userId;
  final String? email;
  final String? ageRange;
  final String? gender;
  final UserTier tier;

  const UserProperties({
    this.userId,
    this.email,
    this.ageRange,
    this.gender,
    this.tier = UserTier.free,
  });

  UserProperties copyWith({
    String? userId,
    String? email,
    String? ageRange,
    String? gender,
    UserTier? tier,
  }) {
    return UserProperties(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      ageRange: ageRange ?? this.ageRange,
      gender: gender ?? this.gender,
      tier: tier ?? this.tier,
    );
  }

  Map<String, String> toMap() {
    final map = <String, String>{};
    if (userId != null) map['user_id'] = userId!;
    if (email != null) map['email'] = email!;
    if (ageRange != null) map['age_range'] = ageRange!;
    if (gender != null) map['gender'] = gender!;
    map['tier'] = tier.name;
    return map;
  }

  @override
  String toString() =>
      'UserProperties(userId: $userId, tier: ${tier.name})';
}
