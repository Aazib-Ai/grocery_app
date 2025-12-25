/// User role enumeration for role-based access control
enum UserRole {
  customer,
  admin;

  /// Convert role to string representation
  String toJson() => name;

  /// Parse role from string
  static UserRole fromJson(String role) {
    return UserRole.values.firstWhere(
      (r) => r.name == role.toLowerCase(),
      orElse: () => UserRole.customer,
    );
  }

  /// Check if this role is admin
  bool get isAdmin => this == UserRole.admin;

  /// Check if this role is customer
  bool get isCustomer => this == UserRole.customer;
}
