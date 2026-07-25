/// Form field validators returning a localisation-agnostic error key or null.
///
/// Screens pass these to `TextFormField.validator` and render the returned
/// message directly (already English). Extend with l10n lookups if you localise
/// validation messages.
abstract final class Validators {
  const Validators._();

  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
  );

  static final RegExp _phoneRegex = RegExp(r'^\+?[1-9]\d{6,14}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Use at least 8 characters';
    if (!v.contains(RegExp(r'[A-Za-z]')) || !v.contains(RegExp(r'\d'))) {
      return 'Include letters and numbers';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? displayName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Name is required';
    if (v.length < 2) return 'Name is too short';
    if (v.length > 24) return 'Name is too long';
    return null;
  }

  static String? phone(String? value) {
    final v = value?.replaceAll(RegExp(r'[\s()-]'), '') ?? '';
    if (v.isEmpty) return 'Phone number is required';
    if (!_phoneRegex.hasMatch(v)) return 'Enter a valid phone number';
    return null;
  }

  static String? otp(String? value) {
    final v = value?.trim() ?? '';
    if (v.length != 6 || int.tryParse(v) == null) return 'Enter the 6-digit code';
    return null;
  }

  static String? robloxUsername(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Roblox username is required';
    if (v.length < 3 || v.length > 20) return 'Username must be 3–20 characters';
    if (!RegExp(r'^\w+$').hasMatch(v)) {
      return 'Only letters, numbers and underscore';
    }
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if ((value?.trim() ?? '').isEmpty) return '$field is required';
    return null;
  }
}
