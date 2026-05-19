import 'package:flutter/widgets.dart';

import 'result_banner_ad_service.dart';

class UnsupportedResultBannerAdService implements ResultBannerAdService {
  const UnsupportedResultBannerAdService();

  @override
  Future<void> initialize() async {}

  @override
  Future<ResultBannerAdHandle?> load() async {
    return null;
  }

  @override
  void dispose() {}
}

class StaticResultBannerAdHandle implements ResultBannerAdHandle {
  const StaticResultBannerAdHandle(this.child);

  final Widget child;

  @override
  Widget buildWidget() => child;

  @override
  void dispose() {}
}

ResultBannerAdService createResultBannerAdService() {
  return const UnsupportedResultBannerAdService();
}
