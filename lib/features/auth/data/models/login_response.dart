import 'token_pair.dart';

/// Respuesta de login y refresh; challengeId puede omitirse en MOBILE.
class LoginResponse {
  const LoginResponse({
    required this.status,
    this.challengeId,
    this.login,
    this.codper,
    this.accessToken,
    this.refreshToken,
    this.tokenType,
    this.expiresIn,
    this.sid,
  });

  final String status;
  final String? challengeId;
  final String? login;
  final int? codper;
  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;
  final int? expiresIn;
  final String? sid;

  TokenPair get tokenPair {
    final access = accessToken;
    final refresh = refreshToken;
    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty) {
      throw const FormatException(
        'La respuesta de autenticación no contiene tokens.',
      );
    }
    return TokenPair(accessToken: access, refreshToken: refresh);
  }

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    status: json['status'] is String ? json['status'] as String : '',
    challengeId: _string(json['challengeId']),
    login: _string(json['login']),
    codper: _integer(json['codper']),
    accessToken: _string(json['accessToken']),
    refreshToken: _string(json['refreshToken']),
    tokenType: _string(json['tokenType']),
    expiresIn: _integer(json['expiresIn']),
    sid: _string(json['sid']),
  );

  static String? _string(Object? value) => value is String ? value : null;

  static int? _integer(Object? value) => value is int
      ? value
      : value is num
      ? value.toInt()
      : null;

  @override
  String toString() =>
      'LoginResponse(status: $status, login: $login, codper: $codper, '
      'accessToken: <redacted>, refreshToken: <redacted>, sid: <redacted>)';
}
