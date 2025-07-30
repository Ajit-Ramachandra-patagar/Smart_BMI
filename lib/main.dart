import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const BMICalculatorApp());

class BMICalculatorApp extends StatelessWidget {
  const BMICalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BMI Calculator',
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 16),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class BMIRecord {
  final double height;
  final double weight;
  final double bmi;
  final DateTime date;

  BMIRecord({
    required this.height,
    required this.weight,
    required this.bmi,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory BMIRecord.fromJson(Map<String, dynamic> json) {
    return BMIRecord(
      height: json['height'].toDouble(),
      weight: json['weight'].toDouble(),
      bmi: json['bmi'].toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.monitor_heart, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'BMI Calculator',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final List<Widget> _screens = [const HomePage(), const HistoryPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  String result = '';

  void calculateBMI() async {
    double height = double.tryParse(heightController.text) ?? 0;
    double weight = double.tryParse(weightController.text) ?? 0;

    if (height > 0 && weight > 0) {
      double bmi = weight / ((height / 100) * (height / 100));
      String bmiResult = bmi.toStringAsFixed(2);

      setState(() {
        result = 'Your BMI is $bmiResult';
      });

      // Save to history with all details
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> historyJson =
          prefs.getStringList('bmi_detailed_history') ?? [];

      BMIRecord record = BMIRecord(
        height: height,
        weight: weight,
        bmi: bmi,
        date: DateTime.now(),
      );

      historyJson.add(jsonEncode(record.toJson()));
      await prefs.setStringList('bmi_detailed_history', historyJson);
    }
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BMI Calculator',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          TextField(
            controller: heightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Height (cm)',
              prefixIcon: const Icon(Icons.height),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: weightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Weight (kg)',
              prefixIcon: const Icon(Icons.monitor_weight),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: calculateBMI,
              icon: const Icon(Icons.calculate, color: Colors.white),
              label: const Text('Calculate BMI',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 30),
          if (result.isNotEmpty)
            Center(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        result,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      if (result.isNotEmpty)
                        Text(
                          _getBMICategory(
                              double.tryParse(result.split(' ').last) ?? 0),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.teal[700],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  Future<List<BMIRecord>> _getHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> historyJson =
        prefs.getStringList('bmi_detailed_history') ?? [];

    return historyJson
        .map((jsonString) {
          return BMIRecord.fromJson(jsonDecode(jsonString));
        })
        .toList()
        .reversed
        .toList(); // Show latest first
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getCategoryColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BMI History',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<BMIRecord>>(
              future: _getHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error loading history'));
                } else if (snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No BMI history available',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      BMIRecord record = snapshot.data![index];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: _getCategoryColor(record.bmi),
                            child: const Icon(Icons.monitor_heart,
                                color: Colors.white),
                          ),
                          title: Text(
                            'BMI: ${record.bmi.toStringAsFixed(2)} - ${_getBMICategory(record.bmi)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.height,
                                      size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                      'Height: ${record.height.toStringAsFixed(0)} cm'),
                                  const SizedBox(width: 16),
                                  Icon(Icons.monitor_weight,
                                      size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                      'Weight: ${record.weight.toStringAsFixed(1)} kg'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time,
                                      size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(record.date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
