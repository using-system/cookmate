/// Derives a short title from the first words of a user message.
///
/// Takes up to [maxWords] words and truncates to [maxLength] characters.
/// Returns `null` if the message is empty or blank.
String? generateTitle(
  String message, {
  int maxWords = 6,
  int maxLength = 50,
}) {
  final words = message.trim().split(RegExp(r'\s+'));
  final title = words.take(maxWords).join(' ');
  if (title.isEmpty) return null;
  return title.length > maxLength
      ? '${title.substring(0, maxLength - 3)}...'
      : title;
}
