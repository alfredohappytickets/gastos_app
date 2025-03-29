import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'add_transaction_page.dart';
import '../models/transaction.dart';
import '../db/data_base_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Transaccion> _transactions = [];
  List<Transaccion> _filteredTransactions = [];

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategory;
  final List<String> _categories = ['Todos', 'Trabajo' ,'Comida', 'Transporte', 'Entretenimiento', 'Salud', 'Educación', 'Vivienda', 'Ahorros', 'Ropa', 'Servicios (luz, agua, internet, etc.)', 'Otros gastos'];

  double _totalBalance = 0.0;
  double _filteredTransactionsBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _calculateTotalBalance(); // Calcular el balance total al iniciar
  }

  Future<void> _loadTransactions() async {
    final transactions = await _dbHelper.getTransactions();
    setState(() {
      _transactions = transactions;
      _filteredTransactions = transactions;
      _filteredTransactionsBalance = transactions.fold(0.0, (sum, transaction) => sum + transaction.amount);
    });
  }

  // Filtrar por fecha
  void _filterByDate() {
    setState(() {
      _filteredTransactions = _transactions.where((transaction) {
        if (_startDate != null && transaction.date.isBefore(_startDate!)) return false;
        if (_endDate != null && transaction.date.isAfter(_endDate!)) return false;
        return true;
      }).toList();
      _filteredTransactionsBalance = _filteredTransactions.fold(0.0, (sum, transaction) => sum + transaction.amount);
    });
  }

  // Filtrar por categoría
  void _filterByCategory(String? category) {
    setState(() {
      if (category == 'Todos' || category == null) {
        _filteredTransactions = _transactions;
      } else {
        _filteredTransactions = _transactions.where((transaction) {
          return transaction.category == category;
        }).toList();
      }
      _filteredTransactionsBalance = _filteredTransactions.fold(0.0, (sum, transaction) => sum + transaction.amount);
    });
  }

  // Función para seleccionar fechas
  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != DateTimeRange(start: _startDate ?? DateTime.now(), end: _endDate ?? DateTime.now())) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _filterByDate();
      });
    }
  }

  Future<void> _deleteTransaction(int? id) async {
    if (id != null) {
      final dbHelper = DatabaseHelper();
      await dbHelper.deleteTransaction(id);
      _loadTransactions(); // Recargar lista de transacciones
    }
  }

  Future<void> _calculateTotalBalance() async {
    final dbHelper = DatabaseHelper();
    final transactions = await dbHelper.getTransactions(); // Obtener todas las transacciones

    double totalIncome = 0.0;
    double totalExpenses = 0.0;

    for (var transaction in transactions) {
      if (transaction.isIncome) {
        totalIncome += transaction.amount; // Sumar si es un ingreso
      } else {
        totalExpenses += transaction.amount; // Restar si es un gasto
      }
    }

    setState(() {
      _totalBalance = totalIncome - totalExpenses; // Guardar el balance total
    });
  }

  Future<void> exportDataToJSON() async {
    // 1. Consulta la base de datos y obtén los datos
    final dbHelper = DatabaseHelper();

    List<Transaccion> transacciones = await dbHelper.getTransactions();
    List<Map<String, dynamic>> data = transacciones.map((transaccion) => transaccion.toMap()).toList();

    // 2. Convierte los datos a formato JSON
    String jsonData = jsonEncode(data);

    // 3. Obtén la ruta del directorio de almacenamiento externo
    Directory? directory = await getExternalStorageDirectory();
    String filePath = '${directory?.path}/datos_exportados.json';

    // 4. Crea el archivo JSON y escribe los datos
    File file = File(filePath);
    await file.writeAsString(jsonData);

    // 5. (Opcional) Comparte el archivo JSON
    Share.shareXFiles([XFile(filePath)], subject: 'Datos exportados');

    // Imprime la ruta del archivo para informar al usuario
    Fluttertoast.showToast(msg: 'Datos exportados a: $filePath',backgroundColor: Colors.green);
  }

  Future<void> importDataFromJSON() async {
    // 1. Abre el selector de archivos
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    final dbHelper = DatabaseHelper();

    if (result != null) {
      // 2. Obtén la ruta del archivo seleccionado
      File file = File(result.files.single.path!);

      // 3. Lee elcontenido del archivo JSON
      String jsonData = await file.readAsString();

      // 4. Decodifica el JSON a una lista de mapas
      List<dynamic> jsonList = jsonDecode(jsonData);

      try {
        // 5. Inserta los datos en la base de datos
        for (var jsonMap in jsonList) {
          Transaccion transaccion = new Transaccion(
            id: jsonMap['id'],
            description: jsonMap['description'],
            amount: jsonMap['amount'],
            date: DateTime.parse(jsonMap['date'] as String),
            isIncome: jsonMap['isIncome'] == 1 ? true : false,
            category: jsonMap['category'],
          );
          await dbHelper.insertTransaction(transaccion);
        }
        setState(() {
          _loadTransactions();
        });
        Fluttertoast.showToast(msg: 'Datos importados correctamente',backgroundColor: Colors.green);
      }catch (e) {
        Fluttertoast.showToast(msg: 'Error de importación: $e',backgroundColor: Colors.red);
      }
    } else {
      // El usuario canceló la selección del archivo
      Fluttertoast.showToast(msg: 'Importación cancelada',backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gastos e Ingresos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: () {
              exportDataToJSON(); // Llama a la función de exportación
            },
            tooltip: 'Exportar datos',
          ),
          IconButton(
            icon: const Icon(Icons.download),onPressed: () {
            importDataFromJSON(); // Llama a la función de importación
          },
            tooltip: 'Importar datos',
          ),
          IconButton(
            icon: Icon(Icons.filter_alt),
            onPressed: () {
              _selectDateRange(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Mostrar el balance total
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Balance Total:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${_totalBalance.toStringAsFixed(2)}', // Mostrar el balance con dos decimales
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _totalBalance >= 0 ? Colors.green : Colors.red, // Color verde si es positivo, rojo si es negativo
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _selectedCategory,
                  hint: const Text('Selecciona Categoría'),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                      _filterByCategory(newValue);
                    });
                  },
                  items: _categories.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                _selectedCategory == 'Todos' ? Container() : Text(
                  '\$${_filteredTransactionsBalance.toStringAsFixed(2)}', // Mostrar el balance con dos decimales
                  style: const TextStyle(
                    //fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red, // Color verde si es positivo, rojo si es negativo
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTransactions.length,
              itemBuilder: (context, index) {
                final transaction = _filteredTransactions[index];
                return Container(
                  margin: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: transaction.isIncome ? Colors.green[100] : Colors.red[100],
                  ),
                  child: ListTile(
                    leading: Icon(transaction.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                    color: transaction.isIncome ? Colors.green : Colors.red),
                    title: Text(transaction.description),
                    subtitle: Text('${transaction.amount} - ${DateFormat.yMMMd().format(transaction.date)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue[700]),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddTransactionPage(transaction: transaction),
                              ),
                            ).then((_) {
                              _loadTransactions(); // Recargar lista de transacciones después de la edición
                              _calculateTotalBalance();
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            //_deleteTransaction(transaction.id);
                            _showDeleteConfirmationDialog(transaction.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );

              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTransactionPage()),
          ).then((_) {
            // Recargar la lista de transacciones después de añadir una nueva
            _loadTransactions();
            _calculateTotalBalance(); // Actualizar el balance
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(int? id) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // El diálogo no se puede cerrar al tocar fuera de él
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Estás seguro de que deseas eliminar esta transacción?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
            ),
            TextButton(
              child: Text('Eliminar'),
              onPressed: () {
                _deleteTransaction(id); // Eliminar la transacción
                _calculateTotalBalance(); // Actualizar el balance
                Navigator.of(context).pop(); // Cerrar el diálogo después de eliminar
              },
            ),
          ],
        );
      },
    );
  }

}
