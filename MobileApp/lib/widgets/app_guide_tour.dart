import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AppGuideTour extends StatefulWidget {
  final Map<String, GlobalKey> targets;
  final VoidCallback onComplete;
  const AppGuideTour({super.key, required this.targets, required this.onComplete});

  @override
  State<AppGuideTour> createState() => _AppGuideTourState();
}

class _AppGuideTourState extends State<AppGuideTour> {
  int _step = 0;
  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Safety Score',
      'desc': 'This is your real-time safety performance index. High scores earn better incentives.',
      'target': 'score',
    },
    {
      'title': 'Mode Switch',
      'desc': 'Switch between Direct Mode for deliveries and Shadow Mode for background tracking.',
      'target': 'mode',
    },
    {
      'title': 'Go Live',
      'desc': 'Tap here to start your shift and begin receiving missions from command.',
      'target': 'live',
    },
    {
      'title': 'Mission Hub',
      'desc': 'View details of your currently assigned delivery missions here.',
      'target': 'dispatch',
    },
  ];

  Rect? _getTargetRect() {
    final targetKey = widget.targets[_steps[_step]['target']];
    if (targetKey == null) return null;

    final RenderBox? box = targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;

    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final current = _steps[_step];
    final rect = _getTargetRect();

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dark Overlay with Hole
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.85),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                if (rect != null)
                  Positioned.fromRect(
                    rect: rect.inflate(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content Layer
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (rect != null) ...[
                   // If target is in bottom half, show text at top, and vice-versa
                   Spacer(flex: rect.top > MediaQuery.of(context).size.height / 2 ? 1 : 10),
                ],

                Container(
                  margin: const Offset(24, 24).dx == 24 ? const EdgeInsets.all(24) : EdgeInsets.zero,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "STEP ${_step + 1} OF ${_steps.length}",
                            style: TextStyle(
                              color: AppColors.primary.withOpacity(0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          TextButton(
                            onPressed: widget.onComplete,
                            child: Text(
                              "SKIP",
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        current['title'].toString().toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        current['desc'],
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_step > 0)
                            TextButton(
                              onPressed: () => setState(() => _step--),
                              child: const Text("BACK", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                            )
                          else
                            const SizedBox(width: 60),

                          ElevatedButton(
                            onPressed: () {
                              if (_step < _steps.length - 1) {
                                setState(() => _step++);
                              } else {
                                widget.onComplete();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(_step == _steps.length - 1 ? 'FINISH' : 'NEXT'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (rect != null) ...[
                   Spacer(flex: rect.top <= MediaQuery.of(context).size.height / 2 ? 1 : 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
