/// Contexto de autenticación del usuario actual, sin datos de credenciales.
class AuthContext {
  const AuthContext({
    required this.usuario,
    required this.persona,
    required this.roles,
  });

  final AuthContextUsuario usuario;
  final AuthContextPersona? persona;
  final List<AuthContextRol> roles;

  String get nombreCompleto {
    final parts = [persona?.nombre, persona?.ap, persona?.am]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);
    final name = parts.join(' ');
    return name.isEmpty ? usuario.login : name;
  }

  String get rolesLabel => roles.isEmpty
      ? 'Sin roles asignados'
      : roles
            .map((role) => role.nombre)
            .where((name) => name.isNotEmpty)
            .join(', ');

  factory AuthContext.fromJson(Map<String, dynamic> json) {
    final rawUser = _asMap(json['usuario']);
    if (rawUser == null || rawUser['login'] is! String) {
      throw const FormatException('El contexto no contiene un usuario válido.');
    }
    final rawPerson = _asMap(json['persona']);
    final rawRoles = json['roles'];
    return AuthContext(
      usuario: AuthContextUsuario.fromJson(rawUser),
      persona: rawPerson == null
          ? null
          : AuthContextPersona.fromJson(rawPerson),
      roles: rawRoles is List
          ? rawRoles
                .map(_asMap)
                .whereType<Map<String, dynamic>>()
                .map(AuthContextRol.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}

class AuthContextUsuario {
  const AuthContextUsuario({required this.login, this.codper});

  final String login;
  final int? codper;

  factory AuthContextUsuario.fromJson(Map<String, dynamic> json) =>
      AuthContextUsuario(
        login: json['login'] as String,
        codper: _asInt(json['codper']),
      );
}

class AuthContextPersona {
  const AuthContextPersona({this.nombre, this.ap, this.am, this.foto});

  final String? nombre;
  final String? ap;
  final String? am;
  final String? foto;

  factory AuthContextPersona.fromJson(Map<String, dynamic> json) =>
      AuthContextPersona(
        nombre: _asString(json['nombre']),
        ap: _asString(json['ap']),
        am: _asString(json['am']),
        foto: _asString(json['foto']),
      );
}

class AuthContextRol {
  const AuthContextRol({
    required this.codr,
    required this.nombre,
    required this.menus,
  });

  final int? codr;
  final String nombre;
  final List<AuthContextMenu> menus;

  factory AuthContextRol.fromJson(Map<String, dynamic> json) => AuthContextRol(
    codr: _asInt(json['codr']),
    nombre: _asString(json['nombre']) ?? '',
    menus: _parseList(json['menus'], AuthContextMenu.fromJson),
  );
}

class AuthContextMenu {
  const AuthContextMenu({
    required this.codm,
    required this.nombre,
    this.icono,
    required this.procesos,
  });

  final int? codm;
  final String nombre;
  final String? icono;
  final List<AuthContextProceso> procesos;

  factory AuthContextMenu.fromJson(Map<String, dynamic> json) =>
      AuthContextMenu(
        codm: _asInt(json['codm']),
        nombre: _asString(json['nombre']) ?? '',
        icono: _asString(json['icono']),
        procesos: _parseList(json['procesos'], AuthContextProceso.fromJson),
      );
}

class AuthContextProceso {
  const AuthContextProceso({
    required this.codp,
    required this.nombre,
    this.enlace,
  });

  final int? codp;
  final String nombre;
  final String? enlace;

  factory AuthContextProceso.fromJson(Map<String, dynamic> json) =>
      AuthContextProceso(
        codp: _asInt(json['codp']),
        nombre: _asString(json['nombre']) ?? '',
        enlace: _asString(json['enlace']),
      );
}

List<T> _parseList<T>(Object? value, T Function(Map<String, dynamic>) parse) =>
    value is List
    ? value
          .map(_asMap)
          .whereType<Map<String, dynamic>>()
          .map(parse)
          .toList(growable: false)
    : const [];

Map<String, dynamic>? _asMap(Object? value) => value is Map
    ? value.map((key, entry) => MapEntry(key.toString(), entry))
    : null;

String? _asString(Object? value) => value is String ? value : null;

int? _asInt(Object? value) => value is int
    ? value
    : value is num
    ? value.toInt()
    : null;
