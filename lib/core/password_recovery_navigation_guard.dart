class PasswordRecoveryNavigationGuard {
  bool _open = false;
  bool tryOpen() {
    if (_open) return false;
    _open = true;
    return true;
  }

  void close() => _open = false;
}
