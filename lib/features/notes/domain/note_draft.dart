final class NoteDraft {
  const NoteDraft({this.title, required this.content});

  final String? title;
  final String content;
}

final class NoteValidationException implements Exception {
  const NoteValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
