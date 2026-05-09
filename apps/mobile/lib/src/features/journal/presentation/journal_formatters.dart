String formatJournalDate(DateTime dateTime) {
  final localDate = dateTime.toLocal();
  final month = _monthNames[localDate.month - 1];

  return '$month ${localDate.day}, ${localDate.year}';
}

String formatJournalDateTime(DateTime dateTime) {
  final localDate = dateTime.toLocal();
  final hour = localDate.hour == 0
      ? 12
      : localDate.hour > 12
      ? localDate.hour - 12
      : localDate.hour;
  final minute = localDate.minute.toString().padLeft(2, '0');
  final meridiem = localDate.hour >= 12 ? 'PM' : 'AM';

  return '${formatJournalDate(localDate)} at $hour:$minute $meridiem';
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
