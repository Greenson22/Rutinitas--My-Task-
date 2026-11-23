import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/adaptive_banner_ad.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../controllers/ad_showcase_controller.dart';

class AdBannerShowcaseScreen extends StatefulWidget {
  const AdBannerShowcaseScreen({super.key});

  static const List<({String label, String adKey})> adSlots = [
    (label: 'Task Master', adKey: 'task_master_banner'),
    (label: 'MyChecklist Hub', adKey: 'checklist_hub_banner'),
    (label: 'MyChecklist Detail', adKey: 'checklist_detail_banner'),
    (label: 'MyNote Hub', adKey: 'note_hub_banner'),
    (label: 'MyNote Detail', adKey: 'note_detail_banner'),
    (label: 'MyPrompt Hub', adKey: 'prompt_hub_banner'),
    (label: 'MyPrompt Detail', adKey: 'prompt_detail_banner'),
    (label: 'My Documents', adKey: 'document_hub_banner'),
    (label: 'Data Center', adKey: 'data_center'),
  ];

  static const List<int> availableIntervals = [30, 60, 90, 120, 180, 300];

  @override
  State<AdBannerShowcaseScreen> createState() => _AdBannerShowcaseScreenState();
}

class _AdBannerShowcaseScreenState extends State<AdBannerShowcaseScreen> {
  late final AdShowcaseController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AdShowcaseController();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad Banner Showcase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Manual',
            onPressed: () {
              _controller.triggerManualRefresh();
            },
          ),
        ],
      ),
      drawer: const DrawerMenu(isAdShowcaseActive: true),
      body: Column(
        children: [
          // Baris kontrol interval & countdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Interval: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    final currentInterval = _controller.intervalSeconds;
                    final dropdownValue =
                        AdBannerShowcaseScreen.availableIntervals.contains(
                              currentInterval,
                            )
                            ? currentInterval
                            : AdBannerShowcaseScreen.availableIntervals.first;

                    return DropdownButton<int>(
                      value: dropdownValue,
                      items:
                          AdBannerShowcaseScreen.availableIntervals.map((int s) {
                            return DropdownMenuItem<int>(
                              value: s,
                              child: Text('${s}s'),
                            );
                          }).toList(),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          _controller.setInterval(newValue);
                        }
                      },
                    );
                  },
                ),
                const Spacer(),
                ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    return Text(
                      'Next: ${_controller.secondsUntilNextRefresh}s',
                      style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Daftar slot banner
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final refreshKey = _controller.refreshKey;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: AdBannerShowcaseScreen.adSlots.length,
                  itemBuilder: (context, index) {
                    final slot = AdBannerShowcaseScreen.adSlots[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            slot.label,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                        Center(
                          child: AdaptiveBannerAd(
                            key: ValueKey('${slot.adKey}_$refreshKey'),
                            adKey: slot.adKey,
                          ),
                        ),
                        const Divider(height: 24, thickness: 1),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
