import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../services/timetable_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _mainStationController = TextEditingController();
  final _mainDepartureController = TextEditingController();
  final _nearestLocalStationController = TextEditingController();
  final _homeToStationMinutesController =
      TextEditingController(text: '15');

  String? _resultText;
  bool _loading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    TimetableService().loadFromAsset('assets/data/tn_local_trains.json');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _mainStationController.dispose();
    _mainDepartureController.dispose();
    _nearestLocalStationController.dispose();
    _homeToStationMinutesController.dispose();
    _animationController.dispose();
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Location detected. Please enter your nearest local station.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Location error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
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
    _animationController.reset();

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
        _animationController.forward();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.3),
              colorScheme.surface,
              colorScheme.secondaryContainer.withOpacity(0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  _buildHeader(colorScheme),
                  const SizedBox(height: 32),

                  // Main Train Section
                  _buildSectionCard(
                    colorScheme,
                    icon: Icons.train,
                    title: 'Main Train Details',
                    subtitle: 'Where are you heading?',
                    children: [
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _mainStationController,
                        label: 'Main Station',
                        hint: 'e.g., Chennai Egmore',
                        icon: Icons.location_city,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _mainDepartureController,
                        label: 'Departure Time',
                        hint: '11:00 (24-hour format)',
                        icon: Icons.access_time,
                        keyboardType: TextInputType.datetime,
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
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Local Station Section
                  _buildSectionCard(
                    colorScheme,
                    icon: Icons.near_me,
                    title: 'Your Location',
                    subtitle: 'Nearest local station',
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _nearestLocalStationController,
                              label: 'Nearest Local Station',
                              hint: 'e.g., Guindy',
                              icon: Icons.train,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: _loading ? null : _detectLocation,
                              icon: _loading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          colorScheme.primary,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.my_location,
                                      color: colorScheme.primary,
                                    ),
                              tooltip: 'Use GPS',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _homeToStationMinutesController,
                        label: 'Travel Time to Station',
                        hint: 'Minutes from home',
                        icon: Icons.directions_walk,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Search Button
                  _buildSearchButton(colorScheme),
                  const SizedBox(height: 24),

                  // Result Section
                  if (_resultText != null)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildResultCard(colorScheme),
                    ),
                  const SizedBox(height: 24),

                  // Disclaimer
                  _buildDisclaimer(colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.train,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Train Guide',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find your perfect local train',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 16,
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildSearchButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : _calculateRecommendation,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _loading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Finding best train...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Find Best Local Train',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildResultCard(ColorScheme colorScheme) {
    final isError = _resultText!.startsWith('No suitable') ||
        _resultText!.startsWith('Error:');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isError
            ? colorScheme.errorContainer
            : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isError ? colorScheme.error : colorScheme.primary)
                .withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isError
                      ? colorScheme.error
                      : colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isError ? Icons.info_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isError ? 'No Train Found' : 'Recommendation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isError
                      ? colorScheme.onErrorContainer
                      : colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isError) ...[
            _buildTimelineItem(
              colorScheme,
              icon: Icons.home,
              title: 'Leave Home By',
              time: _extractLeaveHomeTime(_resultText!),
            ),
            const SizedBox(height: 16),
            _buildTimelineItem(
              colorScheme,
              icon: Icons.train,
              title: 'Catch Local Train',
              time: _extractTrainInfo(_resultText!),
              subtitle: _extractStationName(_resultText!),
            ),
            const SizedBox(height: 16),
            _buildTimelineItem(
              colorScheme,
              icon: Icons.location_on,
              title: 'Arrive at Main Station',
              time: _extractArrivalTime(_resultText!),
            ),
          ] else
            Text(
              _resultText!,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: colorScheme.onErrorContainer,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String time,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onPrimaryContainer.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _extractLeaveHomeTime(String text) {
    try {
      final regex = RegExp(r'Leave home by\s+(\d{1,2}:\d{2}\s+(?:AM|PM))');
      final match = regex.firstMatch(text);
      return match?.group(1) ?? 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  String _extractArrivalTime(String text) {
    try {
      final regex = RegExp(r'You will reach\s+[^b]+?\s+by\s+(\d{1,2}:\d{2}\s+(?:AM|PM))');
      final match = regex.firstMatch(text);
      return match?.group(1) ?? 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  String _extractStationName(String text) {
    try {
      final regex = RegExp(r'Go to\s+([^R]+?)\s+Railway Station');
      final match = regex.firstMatch(text);
      return match?.group(1)?.trim() ?? '';
    } catch (e) {
      return '';
    }
  }

  String _extractTrainInfo(String text) {
    try {
      final regex = RegExp(r'Catch the\s+([^-]+?)\s+-\s+([^a]+?)\s+at\s+(\d{2}:\d{2})');
      final match = regex.firstMatch(text);
      if (match != null) {
        final trainNo = match.group(1)?.trim() ?? '';
        final trainName = match.group(2)?.trim() ?? '';
        final time = match.group(3) ?? '';
        return '$trainNo - $trainName\nat $time';
      }
      return 'See details';
    } catch (e) {
      return 'See details';
    }
  }

  Widget _buildDisclaimer(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Disclaimer: Train timings are based on official Indian Railways timetables. Actual timings may vary.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.6),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

