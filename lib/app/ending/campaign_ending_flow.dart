const int finalCampaignStageNumber = 30;

bool shouldPlayCampaignEnding({
  required int stageNumber,
  required bool stageCleared,
  required bool stageFailed,
  required bool endingCompleted,
}) {
  return stageNumber == finalCampaignStageNumber &&
      stageCleared &&
      !stageFailed &&
      !endingCompleted;
}
