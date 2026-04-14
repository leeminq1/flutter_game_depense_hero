import 'package:depense_game/data/persistence/in_memory_progress_store.dart';
import 'package:depense_game/data/persistence/progress_store.dart';

Future<ProgressStore> openProgressStore() {
  return InMemoryProgressStore.open();
}
