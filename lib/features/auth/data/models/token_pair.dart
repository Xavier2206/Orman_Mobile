/// Pareja rotativa de tokens almacenada como una sola entrada segura.
class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  Map<String, String> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    final accessToken = json['accessToken'];
    final refreshToken = json['refreshToken'];
    if (accessToken is! String ||
        accessToken.isEmpty ||
        refreshToken is! String ||
        refreshToken.isEmpty) {
      throw const FormatException('La respuesta no contiene ambos tokens.');
    }
    return TokenPair(accessToken: accessToken, refreshToken: refreshToken);
  }

  @override
  String toString() => 'TokenPair(<redacted>)';
}
