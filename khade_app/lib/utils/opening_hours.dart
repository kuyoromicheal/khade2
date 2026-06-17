bool isProviderOpen(Map<String, dynamic>? openingHours) {
  if (openingHours == null || openingHours.isEmpty) return true;
  final now = DateTime.now();
  const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  final day = days[now.weekday - 1];
  final hours = openingHours[day];
  if (hours == null) return false;
  if (hours is! Map) return false;
  final openStr = hours['open']?.toString();
  final closeStr = hours['close']?.toString();
  if (openStr == null || closeStr == null) return false;
  final open = _parseMinutes(openStr);
  final close = _parseMinutes(closeStr);
  final current = now.hour * 60 + now.minute;
  return current >= open && current <= close;
}

int _parseMinutes(String time) {
  final parts = time.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

String formatOpeningHoursDisplay(String time24) {
  final parts = time24.split(':');
  var h = int.parse(parts[0]);
  final m = parts[1];
  final ampm = h >= 12 ? 'PM' : 'AM';
  if (h > 12) h -= 12;
  if (h == 0) h = 12;
  return '$h:$m $ampm';
}

String _formatTime(String time24) => formatOpeningHoursDisplay(time24);

/// Returns day label → hours string. Marks today.
Map<String, String> formatOpeningHours(Map<String, dynamic>? openingHours) {
  const defaults = {
    'Monday': '9:00 AM — 7:00 PM',
    'Tuesday': '9:00 AM — 7:00 PM',
    'Wednesday': '9:00 AM — 7:00 PM',
    'Thursday': '9:00 AM — 8:00 PM',
    'Friday': '9:00 AM — 8:00 PM',
    'Saturday': '8:00 AM — 9:00 PM',
    'Sunday': 'Closed',
  };
  if (openingHours == null || openingHours.isEmpty) return defaults;

  const dayMap = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };
  final todayIndex = DateTime.now().weekday - 1;
  final todayKey = dayMap.keys.elementAt(todayIndex);
  final result = <String, String>{};

  for (final entry in dayMap.entries) {
    final raw = openingHours[entry.key];
    if (raw == null) {
      result[entry.value] = 'Closed';
    } else if (raw is Map && raw['open'] != null && raw['close'] != null) {
      result[entry.value] = '${_formatTime(raw['open'])} — ${_formatTime(raw['close'])}';
    } else {
      result[entry.value] = defaults[entry.value] ?? 'Closed';
    }
    if (entry.key == todayKey) {
      result['__today__'] = entry.value;
    }
  }
  return result;
}
