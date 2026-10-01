/// Hooks for services that must follow the authenticated session lifecycle.
abstract interface class AuthSessionLifecycle {
  void onAuthenticated();

  void onSigningOut();

  void onUnauthenticated();
}
