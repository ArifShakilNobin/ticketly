import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Visual state of the hold-to-talk button.
enum VoiceButtonState {
  idle,
  recording,
  processing,
}

/// Big press-and-hold microphone button used on the home screen.
class VoiceButton extends StatefulWidget {
  const VoiceButton({
    super.key,
    required this.state,
    required this.onStart,
    required this.onStop,
  });

  final VoiceButtonState state;

  /// Called when the passenger presses down.
  final Future<void> Function() onStart;

  /// Called when the passenger lifts their finger.
  final Future<void> Function() onStop;

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );

  @override
  void initState() {
    super.initState();
    if (widget.state == VoiceButtonState.recording) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == oldWidget.state) return;
    if (widget.state == VoiceButtonState.recording) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _handlePress() {
    if (widget.state != VoiceButtonState.idle) return;
    widget.onStart();
  }

  void _handleRelease() {
    if (widget.state != VoiceButtonState.recording) return;
    widget.onStop();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final caption = switch (state) {
      VoiceButtonState.idle => 'ধরে রাখুন এবং কথা বলুন',
      VoiceButtonState.recording => 'শুনছি... ছেড়ে দিন',
      VoiceButtonState.processing => 'বিশ্লেষণ চলছে...',
    };

    return Semantics(
      button: true,
      label: caption,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _handlePress(),
        onPointerUp: (_) => _handleRelease(),
        onPointerCancel: (_) => _handleRelease(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final scale =
                    state == VoiceButtonState.recording ? 1 + _pulse.value * 0.12 : 1.0;
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  color: switch (state) {
                    VoiceButtonState.idle => kBrandGreen,
                    VoiceButtonState.recording => kBrandRed,
                    VoiceButtonState.processing => const Color(0xFF9AA39A),
                  },
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: switch (state) {
                        VoiceButtonState.idle => kBrandGreen,
                        VoiceButtonState.recording => kBrandRed,
                        VoiceButtonState.processing => const Color(0xFF9AA39A),
                      }.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: state == VoiceButtonState.processing
                    ? const Padding(
                        padding: EdgeInsets.all(34),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        state == VoiceButtonState.recording
                            ? Icons.mic
                            : Icons.mic_none,
                        size: 46,
                        color: Colors.white,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              caption,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4A524A),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
