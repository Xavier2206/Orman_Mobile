/// Contrato MOBILE exacto del endpoint `/auth/login`.
class LoginRequest {
  const LoginRequest({
    required this.login,
    required this.password,
    required this.deviceId,
    required this.deviceName,
  });

  final String login;
  final String password;
  final String deviceId;
  final String deviceName;

  Map<String, Object> toJson() => {
    'login': login,
    'password': password,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'clientType': 'MOBILE',
  };

  @override
  String toString() =>
      'LoginRequest(login: $login, password: <redacted>, deviceId: $deviceId, '
      'deviceName: $deviceName, clientType: MOBILE)';
}
