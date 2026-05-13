import 'package:hive/hive.dart';

const int goalTypeId = 1;

class Goal extends HiveObject {
  String name;
  double targetAmount;
  double savedAmount;
  DateTime deadline;

  Goal({
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.deadline,
  });

  double get progress =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => savedAmount >= targetAmount;
}

class GoalAdapter extends TypeAdapter<Goal> {
  @override
  final int typeId = goalTypeId;

  @override
  Goal read(BinaryReader reader) {
    return Goal(
      name: reader.readString(),
      targetAmount: reader.readDouble(),
      savedAmount: reader.readDouble(),
      deadline: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, Goal obj) {
    writer.writeString(obj.name);
    writer.writeDouble(obj.targetAmount);
    writer.writeDouble(obj.savedAmount);
    writer.writeInt(obj.deadline.millisecondsSinceEpoch);
  }
}
