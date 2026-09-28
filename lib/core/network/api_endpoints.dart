/// Endpoints de autenticación del backend ORMAN.
abstract final class ApiEndpoints {
  static const login = 'api/v1/auth/login';
  static const refresh = 'api/v1/auth/refresh';
  static const logout = 'api/v1/auth/logout';
  static const context = 'api/v1/auth/context';
}
