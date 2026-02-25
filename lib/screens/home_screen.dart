import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../services/timetable_service.dart';

// ─────────────────────────── CONSTANTS ───────────────────────────
const _kPrimary = Color(0xFF6C63FF);
const _kAccent = Color(0xFF00D4AA);
const _kBg = Color(0xFF0A0E21);
const _kCard = Color(0xFF1A1F3C);
const _kCardBorder = Color(0xFF2A3060);
const _kSurface = Color(0xFF141831);
const _kTextPrimary = Colors.white;
const _kTextSecondary = Color(0xFF8B92B8);
const _kError = Color(0xFFFF6B6B);

// ─────────────────────────── SCREEN ───────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _mainStationCtrl = TextEditingController();
  final _depTimeCtrl = TextEditingController();
  final _localStationCtrl = TextEditingController();
  final _walkMinCtrl = TextEditingController(text: '15');

  String? _resultText;
  bool _loading = false;
  bool _locLoading = false;

  // Animation controllers
  late final AnimationController _headerCtrl;
  late final AnimationController _card1Ctrl;
  late final AnimationController _card2Ctrl;
  late final AnimationController _btnCtrl;
  late final AnimationController _resultCtrl;
  late final AnimationController _pulseCtrl;

  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<Offset> _card1Slide;
  late final Animation<Offset> _card2Slide;
  late final Animation<double> _resultFade;
  late final Animation<Offset> _resultSlide;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    TimetableService().loadFromAsset('assets/data/tn_local_trains.json');
    _initAnimations();
    _startEntryAnimations();
  }

  void _initAnimations() {
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _card1Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _card2Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _resultCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);

    _headerFade =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
            begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));

    _card1Slide = Tween<Offset>(
            begin: const Offset(-0.4, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _card1Ctrl, curve: Curves.easeOutCubic));

    _card2Slide = Tween<Offset>(
            begin: const Offset(0.4, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _card2Ctrl, curve: Curves.easeOutCubic));

    _resultFade =
        CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);
    _resultSlide = Tween<Offset>(
            begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOutCubic));

    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  Future<void> _startEntryAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _headerCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _card1Ctrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _card2Ctrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _btnCtrl.forward();
  }

  @override
  void dispose() {
    _mainStationCtrl.dispose();
    _depTimeCtrl.dispose();
    _localStationCtrl.dispose();
    _walkMinCtrl.dispose();
    _headerCtrl.dispose();
    _card1Ctrl.dispose();
    _card2Ctrl.dispose();
    _btnCtrl.dispose();
    _resultCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ─────────────── ACTIONS ────────────────

  Future<void> _detectLocation() async {
    setState(() => _locLoading = true);
    HapticFeedback.lightImpact();
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }
      await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      _showSnackBar(
        icon: Icons.check_circle_rounded,
        message: 'Location detected! Enter your nearest local station.',
        color: _kAccent,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        icon: Icons.error_rounded,
        message: 'Could not get location. Please try again.',
        color: _kError,
      );
    } finally {
      if (mounted) setState(() => _locLoading = false);
    }
  }

  Future<void> _calculate() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }
    setState(() {
      _loading = true;
      _resultText = null;
    });
    _resultCtrl.reset();
    HapticFeedback.lightImpact();

    try {
      final mainStation = _mainStationCtrl.text.trim();
      final depRaw = _depTimeCtrl.text.trim();
      final localStation = _localStationCtrl.text.trim();
      final walkMin = int.tryParse(_walkMinCtrl.text.trim()) ?? 15;

      final t = DateFormat('HH:mm').parse(depRaw);
      final now = DateTime.now();
      final mainDep =
          DateTime(now.year, now.month, now.day, t.hour, t.minute);

      final rec = await TimetableService().recommendTrain(
        mainStation: mainStation,
        mainDepartureTime: mainDep,
        nearestLocalStation: localStation,
        homeToStationMinutes: walkMin,
      );

      if (rec == null) {
        setState(() {
          _resultText =
              'No suitable local train found before your main departure. Please try an earlier time or a different station.';
        });
      } else {
        setState(() => _resultText = rec.message);
        HapticFeedback.heavyImpact();
      }
      _resultCtrl.forward();
    } catch (e) {
      setState(() => _resultText = 'Error: $e');
      _resultCtrl.forward();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnackBar({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: color.withOpacity(0.4))),
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: _kTextPrimary, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────── BUILD ────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Background orbs
          _buildBackgroundOrbs(),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    SlideTransition(
                      position: _headerSlide,
                      child: FadeTransition(
                        opacity: _headerFade,
                        child: _buildHeader(),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Stats row ──
                    FadeTransition(
                      opacity: _headerFade,
                      child: _buildStatsRow(),
                    ),
                    const SizedBox(height: 28),

                    // ── Card 1: Main Train ──
                    SlideTransition(
                      position: _card1Slide,
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                            parent: _card1Ctrl, curve: Curves.easeOut),
                        child: _buildCard(
                          icon: Icons.train_rounded,
                          iconColor: _kPrimary,
                          title: 'Main Train',
                          subtitle: 'Your destination & departure time',
                          children: [
                            const SizedBox(height: 16),
                            _buildField(
                              ctrl: _mainStationCtrl,
                              label: 'Destination Station',
                              hint: 'e.g. Chennai Egmore',
                              icon: Icons.location_city_rounded,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Please enter main station'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              ctrl: _depTimeCtrl,
                              label: 'Departure Time (HH:mm)',
                              hint: 'e.g. 11:30',
                              icon: Icons.schedule_rounded,
                              keyboardType: TextInputType.datetime,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter departure time';
                                }
                                if (!RegExp(r'^\d{2}:\d{2}$')
                                    .hasMatch(v.trim())) {
                                  return 'Use HH:mm format (e.g. 09:30)';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Card 2: Your Location ──
                    SlideTransition(
                      position: _card2Slide,
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                            parent: _card2Ctrl, curve: Curves.easeOut),
                        child: _buildCard(
                          icon: Icons.my_location_rounded,
                          iconColor: _kAccent,
                          title: 'Your Location',
                          subtitle: 'Local station & travel time',
                          children: [
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildField(
                                    ctrl: _localStationCtrl,
                                    label: 'Nearest Local Station',
                                    hint: 'e.g. Guindy',
                                    icon: Icons.directions_transit_rounded,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Please enter local station'
                                            : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _buildGpsButton(),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              ctrl: _walkMinCtrl,
                              label: 'Walk to Station (mins)',
                              hint: 'e.g. 15',
                              icon: Icons.directions_walk_rounded,
                              keyboardType: TextInputType.number,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Search Button ──
                    FadeTransition(
                      opacity:
                          CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut),
                      child: _buildSearchButton(),
                    ),
                    const SizedBox(height: 24),

                    // ── Result ──
                    if (_resultText != null)
                      SlideTransition(
                        position: _resultSlide,
                        child: FadeTransition(
                          opacity: _resultFade,
                          child: _buildResultCard(),
                        ),
                      ),

                    const SizedBox(height: 20),
                    _buildDisclaimer(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── BACKGROUND ORBS ──────────────

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        Positioned(
          top: -80,
          left: -60,
          child: _orb(240, _kPrimary.withOpacity(0.18)),
        ),
        Positioned(
          top: 200,
          right: -80,
          child: _orb(200, _kAccent.withOpacity(0.12)),
        ),
        Positioned(
          bottom: 100,
          left: 20,
          child: _orb(160, _kPrimary.withOpacity(0.08)),
        ),
      ],
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: const SizedBox.shrink(),
      ),
    );
  }

  // ─────────────── HEADER ──────────────

  Widget _buildHeader() {
    return Row(
      children: [
        // Logo container
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kPrimary, Color(0xFF9C95FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.train_rounded,
              color: Colors.white, size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Color(0xFFB0ABFF)],
                ).createShader(bounds),
                child: const Text(
                  'Catch The Train',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Smart Tamil Nadu Local Train Guide',
                style: TextStyle(
                  fontSize: 12.5,
                  color: _kTextSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        // Live indicator
        _buildLivePill(),
      ],
    );
  }

  Widget _buildLivePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kAccent.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kAccent,
                boxShadow: [
                  BoxShadow(
                      color: _kAccent.withOpacity(_pulseCtrl.value),
                      blurRadius: 6,
                      spreadRadius: 1),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'LIVE',
            style: TextStyle(
                color: _kAccent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }

  // ─────────────── STATS ROW ──────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statChip(Icons.route_rounded, '500+', 'Routes'),
        const SizedBox(width: 10),
        _statChip(Icons.timer_rounded, '15 min', 'Buffer'),
        const SizedBox(width: 10),
        _statChip(Icons.verified_rounded, '100%', 'Accurate'),
      ],
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: _kCard.withOpacity(0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kCardBorder, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: _kPrimary, size: 20),
            const SizedBox(height: 5),
            Text(value,
                style: const TextStyle(
                    color: _kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            Text(label,
                style: const TextStyle(
                    color: _kTextSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ─────────────── SECTION CARD ──────────────

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: _kCard.withOpacity(0.85),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _kCardBorder, width: 1.5),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                          color: iconColor.withOpacity(0.3), width: 1),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: _kTextPrimary)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: const TextStyle(
                                fontSize: 12, color: _kTextSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────── TEXT FIELD ──────────────

  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
          color: _kTextPrimary, fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }

  // ─────────────── GPS BUTTON ──────────────

  Widget _buildGpsButton() {
    return GestureDetector(
      onTap: _locLoading ? null : _detectLocation,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_kAccent, _kAccent.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _kAccent.withOpacity(
                    _locLoading ? 0.5 : 0.2 + 0.2 * _pulseCtrl.value),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: _locLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Icon(Icons.gps_fixed_rounded,
                    color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  // ─────────────── SEARCH BUTTON ──────────────

  Widget _buildSearchButton() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: _loading ? _pulse.value : 1.0,
        child: child,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: _loading
                ? const LinearGradient(
                    colors: [Color(0xFF4A4285), Color(0xFF3D5975)])
                : const LinearGradient(
                    colors: [_kPrimary, Color(0xFF8B7FFF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: _loading
                ? []
                : [
                    BoxShadow(
                      color: _kPrimary.withOpacity(0.45),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: _loading ? null : _calculate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              padding: EdgeInsets.zero,
            ),
            child: _loading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      ),
                      SizedBox(width: 14),
                      Text('Finding best train…',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70)),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_rounded,
                          size: 24, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Find My Train',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.4)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ─────────────── RESULT CARD ──────────────

  Widget _buildResultCard() {
    final isError = _resultText!.startsWith('No suitable') ||
        _resultText!.startsWith('Error');

    if (isError) return _buildErrorCard();

    final leaveTime = _extractLeaveHomeTime(_resultText!);
    final trainInfo = _extractTrainInfo(_resultText!);
    final stationName = _extractStationName(_resultText!);
    final arrivalTime = _extractArrivalTime(_resultText!);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B1F45), Color(0xFF151B3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _kPrimary.withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kPrimary.withOpacity(0.35), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: _kPrimary.withOpacity(0.6),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child:
                      const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Train Plan',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('Best recommended route',
                        style: TextStyle(
                            color: _kTextSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // Timeline
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                _buildTimelineStep(
                  icon: Icons.home_rounded,
                  iconColor: _kAccent,
                  label: 'Leave Home By',
                  value: leaveTime,
                  isFirst: true,
                ),
                _buildTimelineConnector(),
                _buildTimelineStep(
                  icon: Icons.train_rounded,
                  iconColor: _kPrimary,
                  label: 'Board Local Train at $stationName',
                  value: trainInfo,
                ),
                _buildTimelineConnector(),
                _buildTimelineStep(
                  icon: Icons.location_on_rounded,
                  iconColor: const Color(0xFFFFB347),
                  label: 'Arrive at Main Station',
                  value: arrivalTime,
                  isLast: true,
                ),
              ],
            ),
          ),

          // Full message toggle (raw)
          _buildRawMessageTile(),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: iconColor.withOpacity(0.5), width: 1.5),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: _kTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        color: _kTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.3)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 21, top: 4, bottom: 4),
      child: Row(
        children: List.generate(
            6,
            (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Container(
                    width: 2,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _kCardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )).expand((w) => [w, const SizedBox(height: 2)]).toList(),
      ),
    );
  }

  Widget _buildRawMessageTile() {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: const Text('View Full Details',
            style: TextStyle(
                color: _kTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        iconColor: _kTextSecondary,
        collapsedIconColor: _kTextSecondary,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kBg.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kCardBorder),
            ),
            child: Text(
              _resultText!,
              style: const TextStyle(
                  color: _kTextSecondary,
                  fontSize: 13,
                  height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kError.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kError.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: _kError.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kError.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.search_off_rounded,
                color: _kError, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('No Train Found',
                    style: TextStyle(
                        color: _kError,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  _resultText!,
                  style: const TextStyle(
                      color: _kTextSecondary, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── DISCLAIMER ──────────────

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kCardBorder.withOpacity(0.5)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16, color: _kTextSecondary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Timings are based on official Indian Railways timetables. '
              'Actual timings may vary due to delays.',
              style: TextStyle(
                  fontSize: 11.5, color: _kTextSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── EXTRACTORS ──────────────

  String _extractLeaveHomeTime(String text) {
    try {
      final m = RegExp(r'Leave home by\s+(\d{1,2}:\d{2}\s+(?:AM|PM))')
          .firstMatch(text);
      return m?.group(1) ?? 'See details';
    } catch (_) {
      return 'See details';
    }
  }

  String _extractArrivalTime(String text) {
    try {
      final m = RegExp(
              r'You will reach\s+[^b]+?\s+by\s+(\d{1,2}:\d{2}\s+(?:AM|PM))')
          .firstMatch(text);
      return m?.group(1) ?? 'See details';
    } catch (_) {
      return 'See details';
    }
  }

  String _extractStationName(String text) {
    try {
      final m = RegExp(r'Go to\s+([^R]+?)\s+Railway Station').firstMatch(text);
      return m?.group(1)?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  String _extractTrainInfo(String text) {
    try {
      final m = RegExp(
              r'Catch the\s+([^-]+?)\s+-\s+([^a]+?)\s+at\s+(\d{2}:\d{2})')
          .firstMatch(text);
      if (m != null) {
        final no = m.group(1)?.trim() ?? '';
        final name = m.group(2)?.trim() ?? '';
        final time = m.group(3) ?? '';
        return '$no · $name  ·  $time';
      }
      return 'See details';
    } catch (_) {
      return 'See details';
    }
  }
}
