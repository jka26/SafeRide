class SessionStore {
  SessionStore._();

  static final SessionStore instance = SessionStore._();

  String? token;

  void clear() {
    token = null;
  }
}
