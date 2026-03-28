import 'package:intl/intl.dart';

String formatFriendlyDate(DateTime value) => DateFormat('MMM d, h:mm a').format(value);
