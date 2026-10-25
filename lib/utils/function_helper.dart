import 'package:intl/intl.dart';

class FunctionHelper {
  FunctionHelper._();

  static String formatDateTime(
    DateTime? dateTime, {
    String pattern = 'dd/MM/yyyy HH:mm',
    String placeholder = '-',
  }) {
    if (dateTime == null) return placeholder;
    return DateFormat(pattern).format(dateTime);
  }

  static String formatDate(
    DateTime? dateTime, {
    String pattern = 'dd/MM/yyyy',
    String placeholder = '-',
  }) {
    if (dateTime == null) return placeholder;
    return DateFormat(pattern).format(dateTime);
  }
}

typedef Functionhelper = FunctionHelper;
