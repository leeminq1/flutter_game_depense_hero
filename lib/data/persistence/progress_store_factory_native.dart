import 'package:depense_game/data/persistence/local_progress_store.dart';
import 'package:depense_game/data/persistence/progress_store.dart';

Future<ProgressStore> openProgressStore() {
  return LocalProgressStore.open();
}
