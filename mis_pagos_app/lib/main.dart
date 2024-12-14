import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';  // Importar intl para el formato de números

void main() {
  runApp(RemindersApp());
}

class RemindersApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mis Gastos',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, String>> _reminders = [];
  double _totalGastos = 0;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  // Cargar recordatorios del almacenamiento local
  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? remindersString = prefs.getString('reminders');
    if (remindersString != null) {
      List<dynamic> decodedList = jsonDecode(remindersString);
      List<Map<String, String>> loadedReminders = [];
      double total = 0;

      for (var item in decodedList) {
        if (item is Map<String, dynamic>) {
          loadedReminders.add(Map<String, String>.from(item));
          total += double.tryParse(item['total'] ?? '0') ?? 0;
        }
      }
      setState(() {
        _reminders.addAll(loadedReminders);
        _totalGastos = total;
      });
    }
  }

  // Guardar recordatorios en el almacenamiento local
  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reminders', jsonEncode(_reminders));
  }

  // Eliminar un recordatorio
  void _deleteReminder(int index) {
    setState(() {
      _totalGastos -= double.tryParse(_reminders[index]['total'] ?? '0') ?? 0;
      _reminders.removeAt(index);
    });
    _saveReminders(); // Actualizar almacenamiento local
  }

  // Método para formatear el monto con comas en los miles
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US'); // Formato con comas
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 94, 92, 92),
      appBar: AppBar(
        title: const Text('Mis Gastos'),
        backgroundColor: const Color.fromARGB(255, 58, 56, 56),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 22),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded( // Usamos Expanded para centrar el contenido
                child: _reminders.isEmpty
                    ? const Center(
                        child: Text(
                          'Aún no tienes gastos.',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: _reminders.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Card(
                              color: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                height: 80,
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      child: Icon(Icons.money, color: Colors.white),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _reminders[index]['text'] ?? '',
                                            style: const TextStyle(fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            _reminders[index]['date'] ?? 'Sin fecha',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Total: \$${_formatCurrency(double.tryParse(_reminders[index]['total'] ?? '0') ?? 0)}', // Aplicar formato
                                            style: const TextStyle(fontSize: 14, color: Colors.green),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        _deleteReminder(index);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          Positioned(
            bottom: 0, // Colocamos el widget al fondo
            left: 0,
            right: 0,
            child: Container(
              height: 50,
              padding: const EdgeInsets.only(top: 1, bottom: 3), // Espacio para el total
              decoration: BoxDecoration(
                color: const Color.fromARGB(110, 34, 32, 32),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 20, top: 15),
                child: Text(
                  'Total: \$${_formatCurrency(_totalGastos)}', // Formatear el total
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () => _showAddReminderDialog(context),
        tooltip: 'Añadir gasto',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        child: const Icon(Icons.add, color: Colors.green),
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    final TextEditingController _textController = TextEditingController();
    final TextEditingController _totalController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Nuevo Gasto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe el título de tu gasto.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(5)))
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _totalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: '\$0',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), // Permitir números y el punto
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        String text = newValue.text;

                        // Si el texto está vacío, no hacer nada
                        if (text.isEmpty) {
                          return newValue.copyWith(text: '', selection: TextSelection.collapsed(offset: 0));
                        }

                        // Asegurarse de que el signo "$" esté al principio
                        if (!text.startsWith('\$')) {
                          text = '\$' + text;
                        }

                        // Eliminar las comas
                        text = text.replaceAll(',', ''); // Eliminar las comas

                        // Eliminar cualquier carácter que no sea número o punto
                        text = text.replaceAll(RegExp(r'[^0-9.]'), '');

                        // Asegurarse de que no haya más de un punto
                        int firstDotIndex = text.indexOf('.');
                        if (firstDotIndex != -1) {
                          String integerPart = text.substring(0, firstDotIndex);
                          String decimalPart = text.substring(firstDotIndex + 1);

                          // Limitar los decimales a 2
                          if (decimalPart.length > 2) {
                            decimalPart = decimalPart.substring(0, 2);
                          }
                          text = integerPart + '.' + decimalPart;
                        }

                        // Limitar la parte entera a 9 dígitos
                        List<String> parts = text.split('.');
                        if (parts[0].length > 9) {
                          parts[0] = parts[0].substring(0, 9);
                          text = parts.join('.');
                        } else {
                          text = parts.join('.');
                        }

                        // Asegurarse de que el texto tiene la coma cada tres dígitos antes del punto
                        if (text.contains('.')) {
                          String integerPart = parts[0];
                          String decimalPart = parts[1];

                          integerPart = int.parse(integerPart).toString().replaceAllMapped(
                            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                            (Match m) => '${m[1]},',
                          );
                          text = '\$' + integerPart + '.' + decimalPart;
                        } else {
                          text = int.parse(parts[0]).toString().replaceAllMapped(
                            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                            (Match m) => '${m[1]},',
                          );
                          text = '\$' + text;
                        }

                        // Asegurar que el cursor se mantenga al final del texto
                        return newValue.copyWith(
                          text: text,
                          selection: TextSelection.collapsed(offset: text.length),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, color: Colors.blue),
                    label: Text(
                      selectedDate == null
                          ? 'Seleccionar fecha'
                          : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                      style: const TextStyle(color: Colors.blue),
                    ),
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setStateDialog(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final String text = _textController.text;
                    final String totalText = _totalController.text;
                    if (text.isNotEmpty && totalText.isNotEmpty) {
                      final double total = double.tryParse(totalText.replaceAll('\$', '').replaceAll(',', '')) ?? 0;
                      final dateFormatted = selectedDate != null ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}' : 'Sin fecha';
                      setState(() {
                        _reminders.add({'text': text, 'date': dateFormatted, 'total': total.toStringAsFixed(2)});
                        _totalGastos += total;
                      });
                      _saveReminders(); // Guardamos en el almacenamiento
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
