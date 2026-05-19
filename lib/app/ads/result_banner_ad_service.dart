import 'package:flutter/widgets.dart';

import 'result_banner_ad_service_stub.dart'
    if (dart.library.io) 'result_banner_ad_service_mobile.dart'
    as platform;

abstract class ResultBannerAdHandle {
  Widget buildWidget();

  void dispose();
}

abstract class ResultBannerAdService {
  Future<void> initialize();

  Future<ResultBannerAdHandle?> load();

  void dispose();
}

ResultBannerAdService createResultBannerAdService() {
  return platform.createResultBannerAdService();
}
