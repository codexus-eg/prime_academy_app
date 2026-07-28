abstract final class PhoneFormatter {
  static const _allowedPrefixes = ['+20', '+965', '+966'];

  static String? normalize(String input, {String defaultCountry = 'KW'}) {
    final trimmed = input.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('+')) {
      return _isAllowedE164(trimmed) ? trimmed : null;
    }

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) return null;

    if (digitsOnly.startsWith('20') && digitsOnly.length >= 11) {
      return _isAllowedE164('+$digitsOnly') ? '+$digitsOnly' : null;
    }
    if (digitsOnly.startsWith('965') && digitsOnly.length >= 10) {
      return _isAllowedE164('+$digitsOnly') ? '+$digitsOnly' : null;
    }
    if (digitsOnly.startsWith('966') && digitsOnly.length >= 11) {
      return _isAllowedE164('+$digitsOnly') ? '+$digitsOnly' : null;
    }

    var country = defaultCountry;
    final firstDigit = digitsOnly[0];

    if (firstDigit == '9' || firstDigit == '6' || firstDigit == '5') {
      country = 'KW';
    } else if (firstDigit == '0') {
      country = digitsOnly.startsWith('05') ? 'SA' : 'EG';
    } else if (firstDigit == '1') {
      country = 'EG';
    }

    final dialCode = switch (country) {
      'KW' => '+965',
      'SA' => '+966',
      _ => '+20',
    };

    var national = digitsOnly;
    if (national.startsWith('0')) {
      national = national.substring(1);
    }

    final formatted = '$dialCode$national';
    return _isAllowedE164(formatted) ? formatted : null;
  }

  static bool _isAllowedE164(String value) {
    if (!RegExp(r'^\+\d{8,15}$').hasMatch(value)) return false;
    return _allowedPrefixes.any(value.startsWith);
  }
}
