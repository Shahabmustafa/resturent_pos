// feature/branch/tables/data/model/table_model.dart

class TableModel {
  final String id;
  final String tableNumber;
  final DateTime createdAt;

  const TableModel({
    required this.id,
    required this.tableNumber,
    required this.createdAt,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) => TableModel(
    id: json['id'] as String,
    tableNumber: json['table_number'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
