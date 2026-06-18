import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/controllers/hologram_controller.dart';

import '../../../controllers/connection_controller.dart';
import '../../../theme/app_font.dart';
import '../../../utils/app_export.dart';
import '../../../utils/app_utils.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_wrapper.dart';
import '../../widgets/gradient_divider.dart';
import '../side_menu/side_menu.dart';

class HologramTestScreen extends StatelessWidget {
  const HologramTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HologramController>();
    final connectionController = Get.find<ConnectionController>();
    final actions = _buildActions(controller);

    return SideMenu(
      child: CustomWrapper(
        child: Column(
          children: [
            const CustomAppBar(),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          // indicator: BoxDecoration(
                          //   color: AppColors.buttonPrimary,
                          //   borderRadius: BorderRadius.circular(10),
                          //
                          // ),
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.white.withOpacity(0.7),
                          tabs: const [
                            Tab(text: 'Actions'),
                            Tab(text: 'Logs'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _ActionsTab(
                            controller: controller,
                            connectionController: connectionController,
                            actions: actions,
                          ),
                          _LogsTab(controller: controller),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_HologramTestAction> _buildActions(HologramController controller) => [
        _HologramTestAction(
          title: 'Reconnect WebSocket',
          description: 'Force a reconnection attempt with the hologram device.',
          buttonLabel: 'Reconnect',
          onPressed: controller.connectToDevice,
        ),
        _HologramTestAction(
          title: 'Disconnect WebSocket',
          description: 'Shut down the current hologram connection.',
          buttonLabel: 'Disconnect',
          onPressed: controller.disconnectDevice,
        ),
        _HologramTestAction(
          title: 'Refresh Device Files',
          description: 'Requests the latest file list from the hologram.',
          buttonLabel: 'Refresh',
          onPressed: controller.refreshDeviceFiles,
        ),
        _HologramTestAction(
          title: 'Toggle Device Power',
          description: 'Switch hologram device power ON/OFF.',
          buttonLabel: 'Toggle Power',
          onPressed: controller.toggleDevicePower,
        ),
        _HologramTestAction(
          title: 'Toggle Play / Pause',
          description: 'Play or pause the currently selected media.',
          buttonLabel: 'Toggle Playback',
          onPressed: controller.togglePlayPause,
        ),
        _HologramTestAction(
          title: 'Restart Device',
          description: 'Send a restart signal to the hologram.',
          buttonLabel: 'Restart',
          onPressed: controller.restartDevice,
        ),
        _HologramTestAction(
          title: 'Open Angle Screen',
          description: 'Shows the adjustment screen on the hologram.',
          buttonLabel: 'Open',
          onPressed: controller.openAngleScreen,
        ),
        _HologramTestAction(
          title: 'Close Angle Screen',
          description: 'Hides the adjustment screen on the hologram.',
          buttonLabel: 'Close',
          onPressed: controller.closeAngleScreen,
        ),
        _HologramTestAction(
          title: 'Toggle Light Test',
          description: 'Turns the light test pattern ON/OFF.',
          buttonLabel: 'Toggle Light',
          onPressed: () async => controller.toggleLightTest(),
        ),
        _HologramTestAction(
          title: 'Start Factory Reset',
          description: 'Starts the 5 second factory reset countdown.',
          buttonLabel: 'Start Reset',
          onPressed: () async => controller.startFactoryReset(),
        ),
      ];
}

class _ActionsTab extends StatelessWidget {
  const _ActionsTab({
    required this.controller,
    required this.connectionController,
    required this.actions,
  });

  final HologramController controller;
  final ConnectionController connectionController;
  final List<_HologramTestAction> actions;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusCard(controller: controller, connectionController: connectionController),
          24.hS,
          Text(
            'API Actions',
            style: AppFont.w700.s16.copyWith(color: AppColors.white),
          ),
          12.hS,
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            separatorBuilder: (_, __) => const GradientDivider(),
            itemBuilder: (context, index) => _ActionTile(action: actions[index]),
          ),
        ],
      ),
    );
  }
}

class _LogsTab extends StatelessWidget {
  const _LogsTab({required this.controller});

  final HologramController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSizes.md),
      child: Obx(() {
        final logs = controller.logHistory;
        if (logs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Text(
              'No logs yet. Trigger an action to see live logs.',
              style: AppFont.w500.s12.copyWith(color: AppColors.white),
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: ListView.separated(
            padding: EdgeInsets.all(AppSizes.md),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const GradientDivider(height: 1),
            itemBuilder: (context, index) {
              return Text(
                logs[index],
                style: AppFont.w500.s12.copyWith(color: AppColors.white),
              );
            },
          ),
        );
      }),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.controller,
    required this.connectionController,
  });

  final HologramController controller;
  final ConnectionController connectionController;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.white.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Overview',
              style: AppFont.w700.s16.copyWith(color: AppColors.white),
            ),
            12.hS,
            _StatusRow(
              label: 'WebSocket',
              value: controller.isReady ? 'Connected' : 'Disconnected',
            ),
            _StatusRow(
              label: 'Device IP',
              value: controller.deviceIp.value,
            ),
            _StatusRow(
              label: 'Detection State',
              value: connectionController.currentState.value.name,
            ),
            if (controller.connectionError.value.isNotEmpty) ...[
              8.hS,
              Text(
                controller.connectionError.value,
                style: AppFont.w500.s12.copyWith(color: AppColors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppFont.w500.s12.copyWith(color: AppColors.white.withOpacity(0.7)),
            ),
          ),
          Text(
            value,
            style: AppFont.w700.s12.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

class _HologramTestAction {
  const _HologramTestAction({
    required this.title,
    this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String? description;
  final String buttonLabel;
  final Future<void> Function() onPressed;
}

class _ActionTile extends StatefulWidget {
  const _ActionTile({required this.action});

  final _HologramTestAction action;

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _isRunning = false;

  Future<void> _handleTap() async {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    try {
      await widget.action.onPressed();
    } catch (e) {
      AppUtils.showGetSnackbar(
        'Hologram',
        'Action failed: $e',
        backgroundColor: AppColors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isRunning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.action.title,
            style: AppFont.w700.s14.copyWith(color: AppColors.white),
          ),
          if (widget.action.description != null) ...[
            4.hS,
            Text(
              widget.action.description!,
              style: AppFont.w500.s12.copyWith(color: AppColors.white.withOpacity(0.7)),
            ),
          ],
          8.hS,
          Align(
            alignment: Alignment.centerRight,
            child: CustomElevatedButton(
              text: _isRunning ? 'Running...' : widget.action.buttonLabel,
              width: 180,
              height: 44,
              isDisabled: _isRunning,
              onPressed: _handleTap,
            ),
          ),
        ],
      ),
    );
  }
}

