class Transaccion {
  final int? id;
  final String description;
  final double amount;
  final DateTime date;
  final bool isIncome;
  final String category; // Nuevo campo para categoría

  Transaccion({
    this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.isIncome,
    required this.category, // Requiere categoría
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'isIncome': isIncome ? 1 : 0,
      'category': category, // Guardar la categoría
    };
  }

  static Transaccion fromMap(Map<String, dynamic> map) {
    return Transaccion(
      id: map['id'],
      description: map['description'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      isIncome: map['isIncome'] == 1,
      category: map['category'], // Cargar la categoría
    );
  }
}
