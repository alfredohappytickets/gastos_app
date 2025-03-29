import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../db/data_base_helper.dart';

class AddTransactionPage extends StatefulWidget {
  final Transaccion? transaction; // Recibe una transacción opcional

  AddTransactionPage({this.transaction});

  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedCategory;
  bool _isIncome = false;
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = ['Trabajo' ,'Comida', 'Transporte', 'Entretenimiento', 'Salud', 'Educación', 'Vivienda', 'Ahorros', 'Ropa', 'Servicios (luz, agua, internet, etc.)', 'Otros gastos'];


  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      // Si la transacción no es nula, llenar los campos con los datos existentes
      _descriptionController.text = widget.transaction!.description;
      _amountController.text = widget.transaction!.amount.toString();
      _selectedCategory = widget.transaction!.category;
      _isIncome = widget.transaction!.isIncome;
      _selectedDate = widget.transaction!.date;
    }
  }

  // Función para seleccionar la fecha
  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Guardar o actualizar transacción
  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final newTransaction = Transaccion(
        id: widget.transaction?.id, // Usar el id existente si es una actualización
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        isIncome: _isIncome,
        category: _selectedCategory ?? 'Sin categoría',
      );

      final dbHelper = DatabaseHelper();
      if (widget.transaction == null) {
        // Añadir nueva transacción
        await dbHelper.insertTransaction(newTransaction);
      } else {
        // Actualizar transacción existente
        await dbHelper.updateTransaction(newTransaction);
      }

      Navigator.pop(context); // Cerrar la página después de guardar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'Añadir Transacción' : 'Editar Transacción'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Descripción'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa una descripción';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Monto'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa un monto';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor, ingresa un número válido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Seleccionar fecha
              Row(
                children: [
                  Text('Fecha: ${DateFormat.yMMMd().format(_selectedDate)}'),
                  Spacer(),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: Text('Seleccionar Fecha'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Dropdown para categoría
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(labelText: 'Categoría'),
                items: _categories.map<DropdownMenuItem<String>>((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecciona una categoría';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Toggle para ingreso/gasto
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('Es ingreso:'),
                  Switch(
                    value: _isIncome,
                    onChanged: (bool value) {
                      setState(() {
                        _isIncome = value;
                      });
                    },
                  ),
                ],
              ),
              Spacer(),
              ElevatedButton(
                onPressed: _saveTransaction,
                child: Text(widget.transaction == null ? 'Guardar Transacción' : 'Actualizar Transacción'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

