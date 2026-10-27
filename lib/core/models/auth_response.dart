// lib/core/models/auth_response.dart

class AuthResponse {
  final String token;
  final int userId;
  final String role;
  final String username;
  final int? dealerId;
  final String fullName;
  final int? salesId; // ── 1. ADD THIS ──

  AuthResponse({
    required this.token,
    required this.userId,
    required this.role,
    required this.username,
    this.dealerId,
    required this.fullName,
    this.salesId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      userId: json['userId'] ?? 0,
      role: json['role'] ?? '',
      username: json['username'] ?? '',
      dealerId: json['dealerId'],
      fullName: json['fullName'] ?? '',
      salesId: json['salesId'], // ── 2. ADD THIS ──
    );
  }
}