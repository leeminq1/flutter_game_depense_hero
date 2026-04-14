import 'package:depense_game/data/persistence/progress_store.dart';
import 'package:depense_game/data/persistence/progress_store_factory_native.dart'
    if (dart.library.js_interop) 'package:depense_game/data/persistence/progress_store_factory_web.dart'
    as progress_store_factory;

Future<ProgressStore> openProgressStore() {
  return progress_store_factory.openProgressStore();
}
