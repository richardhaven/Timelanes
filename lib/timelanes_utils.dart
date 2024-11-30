library timelanes;

import 'package:intl/intl.dart';

String formatDateTime(DateTime dateTime, Duration scope, String? format) {
  if (format == null) {
    if (scope < const Duration(days: 1)) {
      format = "hh:mm";
    } else if (scope < const Duration(days: 365)) {
      format = "dd MMMM yy";
    } else if (scope < const Duration(days: 1500)) {
      format = "MMMM yyyy";
    } else {
      format = "yyyy";
    }
  }

  DateFormat dateFormatter = DateFormat(format);
  return dateFormatter.format(dateTime);
}
