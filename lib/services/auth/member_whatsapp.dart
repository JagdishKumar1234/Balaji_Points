/// A WhatsApp chat link to a member, opened from the admin's own phone
/// (free; no WhatsApp Business setup). Indian 10-digit numbers get +91.
class MemberWhatsApp {
  MemberWhatsApp._();

  /// Digits only, with the country code (e.g. 919600609121), or null when
  /// the number cannot be used.
  static String? waNumber(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }
    if (digits.length == 10) return '91$digits';
    if (digits.length == 12 && digits.startsWith('91')) return digits;
    return null;
  }

  /// `https://wa.me/<number>?text=<message>`, or null for an unusable number.
  static Uri? chatUri(String phone, String message) {
    final number = waNumber(phone);
    if (number == null) return null;
    return Uri.https('wa.me', '/$number', {'text': message});
  }
}
