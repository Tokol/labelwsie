import 'package:flutter/material.dart';

class ProcessLoadingView extends StatefulWidget {
  final String productLabel;
  final String status;
  final int currentStep;

  const ProcessLoadingView({
    super.key,
    required this.productLabel,
    required this.status,
    required this.currentStep,
  });

  @override
  State<ProcessLoadingView> createState() => _ProcessLoadingViewState();
}

class _ProcessLoadingViewState extends State<ProcessLoadingView>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _rotationController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _pulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const steps = [
      "Product data loaded",
      "Ingredients and nutrition extracted",
      "Preferences evaluated",
      "Result summary prepared",
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F3),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FCF7),
              Color(0xFFF0F6F1),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _pulseController,
                    _rotationController,
                  ]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulse.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 168,
                            height: 168,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF8DE0A8).withOpacity(0.28),
                                  const Color(0xFF8DE0A8).withOpacity(0.04),
                                ],
                              ),
                            ),
                          ),
                          Transform.rotate(
                            angle: _rotationController.value * 6.28,
                            child: Container(
                              width: 126,
                              height: 126,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF9BC8AB),
                                  width: 2.5,
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2F7A4B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2F7A4B).withOpacity(0.10),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Image.asset(
                                "assets/icons/logo_transparent.png",
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                const Text(
                  "Analyzing Product",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF224D35),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Checking ${widget.productLabel} against your saved preferences",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF6A7C6F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    widget.status,
                    key: ValueKey(widget.status),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Color(0xFF2F7A4B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.82),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFDCE7DD)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: List.generate(steps.length, (index) {
                      final isComplete = index < widget.currentStep;
                      final isActive = index == widget.currentStep;
                      final tone = isComplete || isActive
                          ? const Color(0xFF2F7A4B)
                          : const Color(0xFF9AAEA1);

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == steps.length - 1 ? 0 : 14,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isComplete
                                    ? const Color(0xFF2F7A4B)
                                    : isActive
                                        ? const Color(0xFFE7F3EB)
                                        : const Color(0xFFF0F4F1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: tone,
                                  width: isActive ? 2 : 1.4,
                                ),
                              ),
                              child: isComplete
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : isActive
                                      ? const Center(
                                          child: SizedBox(
                                            width: 8,
                                            height: 8,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: Color(0xFF2F7A4B),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        )
                                      : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                steps[index],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      isActive ? FontWeight.w800 : FontWeight.w600,
                                  color: isComplete || isActive
                                      ? const Color(0xFF31523F)
                                      : const Color(0xFF819388),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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
