/// Small helper for generating a normalized, search-friendly version
/// of a customer's name. Used for both search and alphabetical sorting.
class TextUtils {
  /// Generates a normalized search name from the given [name].
  ///
  /// - Normalizes common Arabic letter variants (أ, إ, آ -> ا, ى -> ي)
  /// - Collapses extra whitespace into single spaces
  /// - Lowercases the result (helps with English names)
  static String generateSearchName(String name) {
    String result = name.trim();

    // Normalize Arabic letters so users can search regardless of
    // which variant of a letter they typed.
    result = result.replaceAll('أ', 'ا');
    result = result.replaceAll('إ', 'ا');
    result = result.replaceAll('آ', 'ا');
    result = result.replaceAll('ى', 'ي');

    // Collapse multiple spaces into one.
    result = result.replaceAll(RegExp(r'\s+'), ' ');

    return result.trim().toLowerCase();
  }
}
