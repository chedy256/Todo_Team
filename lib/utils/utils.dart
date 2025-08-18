//TODO json parse

class Utils {
  static String timeLeft(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      return 'Expiré';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    }
    return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
  }
}