class FormatUtils {
  FormatUtils._();

  /// Format tiền
  static String formatCurrency(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      buf.write(s[i]);
      if (idx > 1 && idx % 3 == 1) buf.write('.');
    }
    return '${buf.toString()}đ';
  }

  /// Format khoảng cách
  static String formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()}m';
    }
    return '${km.toStringAsFixed(1)}km';
  }

  /// Format thời gian
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes phút';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '$hours giờ';
    }
    return '$hours giờ $mins phút';
  }
}