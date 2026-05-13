import 'package:hive/hive.dart';

// Hive type ID for this model — must be unique across all adapters
const int expenseTypeId = 0;

class Expense extends HiveObject {
  double amount;
  String category;
  String note;
  DateTime date;
  bool isExpense; // true = expense, false = income

  Expense({
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    required this.isExpense,
  });
}

/// Manual TypeAdapter — avoids needing build_runner / code generation
class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = expenseTypeId;

  @override
  Expense read(BinaryReader reader) {
    return Expense(
      amount: reader.readDouble(),
      category: reader.readString(),
      note: reader.readString(),
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      isExpense: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer.writeDouble(obj.amount);
    writer.writeString(obj.category);
    writer.writeString(obj.note);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeBool(obj.isExpense);
  }
}
