import 'package:flutter/widgets.dart';
void test(Notification n) {
  if (n is ScrollMetricsNotification) {
    print(n.metrics.extentAfter);
  }
}
