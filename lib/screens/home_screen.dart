import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../services/timetable_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mainStationController = TextEditingController();
  final _mainDepartureController = TextEditingController();
  final _nearestLocalStationController = TextEditingController();
  final _homeToStationMinutesController =
      TextEditingController(text: '15'); // simple input for now

  String? _resultText;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    TimetableService().loadFromAsset('assets/data/tn_local_trains.json');
  }

  @override
  void dispose() {
    _mainStationController.dispose();
    _mainDepartureController.dispose();
    _nearestLocalStationController.dispose();
    _homeToStationMinutesController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _loading = true;
    });
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }

      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // NOTE: Phase-1: we don't reverse-geocode; user still chooses nearest station.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location detected. Please enter your nearest local station.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _calculateRecommendation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _resultText = null;
    });

    try {
      final mainStation = _mainStationController.text.trim();
      final mainDepartureRaw = _mainDepartureController.text.trim();
      final nearestLocalStation = _nearestLocalStationController.text.trim();
      final homeToStationMinutes =
          int.tryParse(_homeToStationMinutesController.text.trim()) ?? 15;

      final time = DateFormat('HH:mm').parse(mainDepartureRaw);
      final now = DateTime.now();
      final mainDeparture = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      final rec = await TimetableService().recommendTrain(
        mainStation: mainStation,
        mainDepartureTime: mainDeparture,
        nearestLocalStation: nearestLocalStation,
        homeToStationMinutes: homeToStationMinutes,
      );

      if (rec == null) {
        setState(() {
          _resultText =
              'No suitable local train found before your main departure time. Please choose an earlier main train or different local station.';
        });
      } else {
        setState(() {
          _resultText = rec.message;
        });
      }
    } catch (e) {
      setState(() {
        _resultText = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Local Train Guide'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tell us your main train details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mainStationController,
                  decoration: const InputDecoration(
                    labelText: 'Main Station (e.g., Chennai Egmore)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mainDepartureController,
                  decoration: const InputDecoration(
                    labelText: 'Main Train Departure Time (HH:mm, 24-hr)',
                    hintText: '11:00',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Required';
                    }
                    final regex = RegExp(r'^\d{2}:\d{2}$');
                    if (!regex.hasMatch(v.trim())) {
                      return 'Use HH:mm format';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Your location & nearest local station',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nearestLocalStationController,
                        decoration: const InputDecoration(
                          labelText: 'Nearest Local Station (e.g., Guindy)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _loading ? null : _detectLocation,
                      icon: const Icon(Icons.my_location),
                      tooltip: 'Use GPS',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _homeToStationMinutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Home → Station Travel Time (minutes)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _calculateRecommendation,
                    icon: const Icon(Icons.search),
                    label: _loading
                        ? const Text('Calculating...')
                        : const Text('Find Best Local Train'),
                  ),
                ),
                const SizedBox(height: 24),
                if (_resultText != null)
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recommendation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _resultText!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Disclaimer: Train timings are based on official Indian Railways timetables. Actual timings may vary.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

