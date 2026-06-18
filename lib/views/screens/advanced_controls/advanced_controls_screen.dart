import 'dart:ui';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:vizlearn/gen/assets.gen.dart';
import 'package:vizlearn/utils/app_export.dart';
import 'package:wifi_iot/wifi_iot.dart';

import '../../../controllers/hologram_controller.dart';
import '../../../theme/app_font.dart';
import '../../widgets/custom_drop_down.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/custom_home_app_bar.dart';
import '../../widgets/custom_switch.dart';
import '../../widgets/custom_wrapper.dart';
import '../../widgets/custom_factory_reset_dialog.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/sync_progress_bar.dart';
import 'package:flutter/material.dart';

import '../side_menu/side_menu.dart';

class AdvancedControlsScreen extends StatelessWidget {
  const AdvancedControlsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HologramController>();
    return SideMenu(
      child: CustomWrapper(
        bottomNavBar: const CustomBottomNavBar(),
        child: Column(
          children: [
            const CustomHomeAppBar(),
            const SyncProgressBar(),
            Expanded(
              child: Obx(() {
                final hologramReady = controller.isReady;
                if (!hologramReady) {
                  return const _ConnectionPrompt();
                }
                return SingleChildScrollView(
                padding: EdgeInsets.all(AppSizes.md),
                child: Column(
                  children: [
                    ///Device IP
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Device IP', style: AppFont.w700.s14),
                            Obx(
                              () => Text(
                                controller.deviceIp.value,
                                style: AppFont.w700.s18,
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                        CustomElevatedButton(
                          text: 'Disconnect',
                          width: 150,
                          height: 40,
                          onPressed: () => controller.disconnectDevice(),
                        ),
                      ],
                    ),
                      36.hS,

                    ///Angle Control
                      _AngleControlRow(controller: controller),
                      36.hS,

                      ///Light Test
                      Row(
                        children: [
                          Text('Light Test', style: AppFont.w500.s14),
                          Spacer(),
                          Obx(
                            () => CustomSwitchWithText(
                              value: controller.isLightTestOn.value,
                              onChanged: (val) => controller.setLightTest(val),
                            ),
                          ),
                        ],
                      ),
                      36.hS,

                      12.hS,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomElevatedButton2(
                            text: 'Set Color Tone',
                            width: Get.size.width * 0.44,
                            color: AppColors.white,
                            onPressed: () => _showColorToneDialog(context, controller),
                            buttonTextStyle: AppFont.w700.s16.copyWith(
                              color: AppColors.black,
                            ),
                          ),
                          8.wS,
                          CustomElevatedButton2(
                            text: 'Configure Wi‑Fi',
                            width: Get.size.width * 0.44,
                            color: AppColors.white,
                            onPressed: () => _showWifiDialog(context, controller),
                            buttonTextStyle: AppFont.w700.s16.copyWith(
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                      16.hS,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomElevatedButton2(
                            text: 'Configure Bluetooth',
                            width: Get.size.width * 0.44,
                            color: AppColors.white,
                            onPressed: () => _showBluetoothDialog(context, controller),
                            buttonTextStyle: AppFont.w700.s16.copyWith(
                              color: AppColors.black,
                            ),
                          ),
                          8.wS,
                          _ActionButton(
                            label: 'Display Device Info',
                            onTap: () => controller.displayDeviceInformation(),
                          ),
                        ],
                      ),
                      12.hS,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(
                            () => _ActionButton(
                              label: controller.isStatusFormOpen ? 'Status Form (Hide)' : 'Status Form (Show)',
                              onTap: () => controller.toggleStatusForm(),
                            ),
                          ),
                          Obx(
                            () => _ActionButton(
                              label: controller.isSnCodeVisible ? 'SN Code (Hide)' : 'SN Code (Show)',
                              onTap: () => controller.toggleSnCode(),
                            ),
                          ),
                        ],
                      ),
                      36.hS,

                      /// Factory Reset
                      CustomElevatedButton2(
                        text: 'Factory Reset',
                        onPressed: () {
                          CustomFactoryResetDialog.show(
                            context: context,
                            controller: controller,
                          );
                        },
                        width: double.infinity,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionPrompt extends StatelessWidget {
  const _ConnectionPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSizes.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Connect to a hologram device to access advanced controls.',
              style: AppFont.w700.s14.copyWith(color: AppColors.white),
              textAlign: TextAlign.center,
            ),
            16.hS,
            CustomElevatedButton(
              text: 'Go Home',
              width: 160,
              onPressed: () => Get.offAllNamed(AppRoutes.home),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Get.size.width * 0.44,
      child: CustomElevatedButton2(
        text: label,
        onPressed: onTap,
        color: AppColors.white,
        buttonTextStyle: AppFont.w700.s14.copyWith(color: AppColors.black),
        height: 48,
      ),
    );
  }
}

class _AngleControlRow extends StatelessWidget {
  const _AngleControlRow({required this.controller});

  final HologramController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isOpen = controller.isAngleScreenOpen.value;
      return Row(
                      children: [
                        GestureDetector(
            onTap: controller.nudgeAngleDecrease,
                          child: Container(
                            width: 70,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.white,
                            ),
                            padding: EdgeInsets.all(12),
              child: Center(
                            child: SizedBox(
                  width: 16,
                  height: 16,
                              child: CustomImageView(
                                imagePath: Assets.icons.minus,
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                  ),
                              ),
                            ),
                          ),
                        ),
                        8.wS,
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isOpen) {
                  controller.closeAngleScreen();
                } else {
                  controller.openAngleScreen();
                }
              },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.white,
                              ),
                              padding: EdgeInsets.all(12),
                              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CustomImageView(
                        imagePath: isOpen
                            ? Assets.icons.openAngle
                            : Assets.icons.closeAngle,
                                      width: 24,
                        height: 24,
                                    ),
                                  ),
                    8.wS,
                                  Text(
                      isOpen ? 'Close Angle' : 'Open Angle',
                                    style: AppFont.w700.s16.copyWith(
                        color: AppColors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        8.wS,
                        GestureDetector(
            onTap: controller.nudgeAngleIncrease,
                          child: Container(
                            width: 70,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.white,
                            ),
                            padding: EdgeInsets.all(12),
              child: Center(
                            child: SizedBox(
                  width: 16,
                  height: 16,
                              child: CustomImageView(
                                imagePath: Assets.icons.add,
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                  ),
                              ),
                            ),
                          ),
                        ),
                      ],
      );
    });
  }
}
Future<void> _showColorToneDialog(
  BuildContext context,
  HologramController controller,
) async {
  final rController = TextEditingController(text: '32768');
  final gController = TextEditingController(text: '32768');
  final bController = TextEditingController(text: '32768');
  int selectedPreset = -1;
  const presets = [
    {'label': 'Neutral', 'values': [32768, 32768, 32768]},
    {'label': 'Warm', 'values': [52768, 32768, 32768]},
    {'label': 'Cool', 'values': [32768, 50000, 50000]},
    {'label': 'Highlight', 'values': [65536, 65536, 65536]},
  ];

  await showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.25),
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return _GlassFormDialog(
            title: 'Set Color Tone',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adjust RGB tone values (0 - 65536)',
                  style: AppFont.w500.s12.copyWith(color: Colors.white.withOpacity(0.9)),
                ),
                12.hS,
                _GlassTextField(
                  controller: rController,
                  label: 'Red Tone',
                  keyboardType: TextInputType.number,
                ),
                12.hS,
                _GlassTextField(
                  controller: gController,
                  label: 'Green Tone',
                  keyboardType: TextInputType.number,
                ),
                12.hS,
                _GlassTextField(
                  controller: bController,
                  label: 'Blue Tone',
                  keyboardType: TextInputType.number,
                ),
                16.hS,
                Text(
                  'Presets',
                  style: AppFont.w600.s12.copyWith(color: Colors.white),
                ),
                8.hS,
                Wrap(
                  spacing: 8,
                  children: presets.asMap().entries.map((entry) {
                    final index = entry.key;
                    final preset = entry.value;
                    return ChoiceChip(
                      label: Text(preset['label']! as String),
                      selected: selectedPreset == index,
                      onSelected: (selected) {
                        setState(() {
                          selectedPreset = selected ? index : -1;
                          final values = preset['values']! as List<int>;
                          rController.text = values[0].toString();
                          gController.text = values[1].toString();
                          bController.text = values[2].toString();
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            onSubmit: () {
              final red = int.tryParse(rController.text) ?? 32768;
              final green = int.tryParse(gController.text) ?? 32768;
              final blue = int.tryParse(bController.text) ?? 32768;
              final redTone = red.clamp(0, 65536).toInt();
              final greenTone = green.clamp(0, 65536).toInt();
              final blueTone = blue.clamp(0, 65536).toInt();
              controller.setColorToneValues(
                redTone: redTone,
                greenTone: greenTone,
                blueTone: blueTone,
              );
              Navigator.of(ctx).pop();
            },
          );
        },
      );
    },
  );
}

Future<void> _showWifiDialog(
  BuildContext context,
  HologramController controller,
) async {
  final ssidController = TextEditingController();
  final passwordController = TextEditingController();
  int mode = 0;
  bool isHotspot = false;
  String? selectedSsid;

  // Show loader while scanning
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (loaderContext) => WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomLoader(
                message: 'Scanning for WiFi networks...',
                size: 48,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // Initial scan
  await controller.scanWifiNetworks();
  
  // Close loader
  if (context.mounted) {
    Navigator.of(context).pop();
  }

  await showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.25),
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return _GlassFormDialog(
            title: 'Configure Wi‑Fi',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomDropdown<String>(
                  hintText: 'Mode',
                  items: const ['Change', 'Add', 'Delete'],
                  selectedValue: switch (mode) {
                    0 => 'Change',
                    1 => 'Add',
                    2 => 'Delete',
                    _ => 'Change',
                  },
                  onChanged: (value) {
                    setState(() {
                      final v = value ?? 'Change';
                      mode = switch (v) {
                        'Add' => 1,
                        'Delete' => 2,
                        _ => 0,
                      };
                    });
                  },
                  backgroundColor: Colors.white.withOpacity(0.08),
                  borderColor: Colors.white.withOpacity(0.35),
                  textColor: Colors.white,
                  dropdownBackgroundColor: Colors.white,
                ),
                12.hS,
                _GlassSwitchTile(
                  title: 'Is Hotspot',
                  value: isHotspot,
                  onChanged: (value) => setState(() => isHotspot = value),
                ),
                12.hS,
                Row(
                  children: [
                    Expanded(
                      child: Obx(() => CustomDropdown<String>(
                        hintText: 'Select WiFi Network',
                        items: [
                          'Manual Entry',
                          ...controller.scannedWifiNetworks.map((n) => n.ssid ?? 'Unknown'),
                        ],
                        selectedValue: selectedSsid,
                        onChanged: (value) {
                          setState(() {
                            if (value == 'Manual Entry') {
                              selectedSsid = null;
                              ssidController.clear();
                            } else {
                              selectedSsid = value;
                              ssidController.text = value ?? '';
                            }
                          });
                        },
                        backgroundColor: Colors.white.withOpacity(0.08),
                        borderColor: Colors.white.withOpacity(0.35),
                        textColor: Colors.white,
                        dropdownBackgroundColor: Colors.white,
                      )),
                    ),
                    8.wS,
                    Obx(() => controller.isScanningWifi.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            onPressed: () async {
                              await controller.scanWifiNetworks();
                            },
                          )),
                  ],
                ),
                12.hS,
                _GlassTextField(
                  controller: ssidController,
                  label: 'SSID (optional for delete)',
                  enabled: selectedSsid == null,
                ),
                12.hS,
                _GlassTextField(
                  controller: passwordController,
                  label: 'Password (optional)',
                  obscureText: true,
                ),
              ],
            ),
            onSubmit: () async {
              final ssid = ssidController.text.trim();
              if (ssid.isEmpty && mode != 2) {
                AppUtils.showGetSnackbar('Error', 'Please select or enter a WiFi network');
                return;
              }

              // Check if password is needed (for secured networks)
              String? password = passwordController.text.trim();
              if (password.isEmpty && mode != 2) {
                // Check if selected network is secured
                if (selectedSsid != null) {
                  WifiNetwork? network;
                  try {
                    network = controller.scannedWifiNetworks.firstWhere(
                      (n) => n.ssid == selectedSsid,
                    );
                  } catch (e) {
                    network = null;
                  }
                  // Check if network is secured (has capabilities that indicate encryption)
                  final isSecured = network != null && 
                      network.capabilities != null && 
                      network.capabilities!.isNotEmpty &&
                      !network.capabilities!.contains('OPEN');
                  if (isSecured) {
                    // Ask for password
                    final result = await _showPasswordDialog(ctx, 'WiFi Password', 'Enter password for $selectedSsid');
                    if (result == null) {
                      return; // User cancelled
                    }
                    password = result;
                  }
                }
              }

              controller.configureWifi(
                mode: mode,
                isHotspot: isHotspot,
                ssid: ssid.isEmpty ? null : ssid,
                password: password.isEmpty ? null : password,
              );
              Navigator.of(ctx).pop();
            },
          );
        },
      );
    },
  );
}

String _getBluetoothDeviceName(BluetoothDevice device, HologramController controller) {
  // First try to get name from controller's stored names (from advertisement data)
  final storedName = controller.getBluetoothDeviceName(device);
  if (storedName != null && storedName.isNotEmpty) {
    return storedName;
  }
  
  // Fallback to device properties
  final platformName = device.platformName;
  if (platformName.isNotEmpty) {
    return platformName;
  }
  
  final advName = device.advName;
  if (advName.isNotEmpty) {
    return advName;
  }
  
  final localName = device.localName;
  if (localName.isNotEmpty) {
    return localName;
  }
  
  return device.remoteId.str;
}

Future<void> _showBluetoothDialog(
  BuildContext context,
  HologramController controller,
) async {
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  int action = 1;
  BluetoothDevice? selectedDevice;

  // Show loader while scanning
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (loaderContext) => WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomLoader(
                message: 'Scanning for Bluetooth devices...',
                size: 48,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // Initial scan
  await controller.scanBluetoothDevices();
  
  // Close loader
  if (context.mounted) {
    Navigator.of(context).pop();
  }

  await showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.25),
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return _GlassFormDialog(
            title: 'Configure Bluetooth',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomDropdown<String>(
                  hintText: 'Action',
                  items: const ['Disconnect', 'Connect'],
                  selectedValue: action == 0 ? 'Disconnect' : 'Connect',
                  onChanged: (value) {
                    setState(() {
                      final v = value ?? 'Connect';
                      action = v == 'Disconnect' ? 0 : 1;
                    });
                  },
                  backgroundColor: Colors.white.withOpacity(0.08),
                  borderColor: Colors.white.withOpacity(0.35),
                  textColor: Colors.white,
                  dropdownBackgroundColor: Colors.white,
                ),
                12.hS,
                Row(
                  children: [
                    Expanded(
                      child: Obx(() => CustomDropdown<String>(
                        hintText: 'Select Bluetooth Device',
                        items: [
                          'Manual Entry',
                          ...controller.scannedBluetoothDevices.map((d) => _getBluetoothDeviceName(d, controller)),
                        ],
                        selectedValue: selectedDevice == null ? null : _getBluetoothDeviceName(selectedDevice!, controller),
                        onChanged: (value) {
                          setState(() {
                            if (value == 'Manual Entry') {
                              selectedDevice = null;
                              nameController.clear();
                            } else {
                              try {
                                selectedDevice = controller.scannedBluetoothDevices.firstWhere(
                                  (d) => _getBluetoothDeviceName(d, controller) == value,
                                );
                              } catch (e) {
                                selectedDevice = null;
                              }
                              nameController.text = value ?? '';
                            }
                          });
                        },
                        backgroundColor: Colors.white.withOpacity(0.08),
                        borderColor: Colors.white.withOpacity(0.35),
                        textColor: Colors.white,
                        dropdownBackgroundColor: Colors.white,
                      )),
                    ),
                    8.wS,
                    Obx(() => controller.isScanningBluetooth.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            onPressed: () async {
                              await controller.scanBluetoothDevices();
                            },
                          )),
                  ],
                ),
                12.hS,
                _GlassTextField(
                  controller: nameController,
                  label: 'Bluetooth Name',
                  enabled: selectedDevice == null,
                ),
                12.hS,
                _GlassTextField(
                  controller: passwordController,
                  label: 'Password (optional)',
                  obscureText: true,
                ),
              ],
            ),
            onSubmit: () async {
              final name = nameController.text.trim();
              if (name.isEmpty && action == 1) {
                AppUtils.showGetSnackbar('Error', 'Please select or enter a Bluetooth device');
                return;
              }

              // Check if password is needed (Bluetooth usually doesn't need password)
              final passwordText = passwordController.text.trim();
              final String? password = passwordText.isEmpty ? null : passwordText;

              controller.configureBluetooth(
                action: action,
                bluetoothName: name.isEmpty ? null : name,
                password: password,
              );
              Navigator.of(ctx).pop();
            },
          );
        },
      );
    },
  );
}

Future<String?> _showPasswordDialog(BuildContext context, String title, String message) async {
  final passwordController = TextEditingController();
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.25),
    builder: (dialogContext) {
      return _GlassFormDialog(
        title: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: AppFont.w500.s12.copyWith(color: Colors.white.withOpacity(0.9)),
            ),
            12.hS,
            _GlassTextField(
              controller: passwordController,
              label: 'Password',
              obscureText: true,
            ),
          ],
        ),
        onSubmit: () {
          Navigator.of(dialogContext).pop(passwordController.text.trim());
        },
      );
    },
  );
}

class _GlassFormDialog extends StatelessWidget {
  const _GlassFormDialog({
    required this.title,
    required this.child,
    required this.onSubmit,
  });

  final String title;
  final Widget child;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFont.w700.s20.copyWith(color: Colors.white),
                  ),
                  16.hS,
                  child,
                  24.hS,
                  Row(
                    children: [
                      Expanded(
                        child: CustomElevatedButton2(
                          text: 'Cancel',
                          color: AppColors.white,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      12.wS,
                      Expanded(
                        child: CustomElevatedButton(
                          text: 'Apply',
                          onPressed: onSubmit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      style: AppFont.w500.s14.copyWith(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
        ),
      ),
    );
  }
}

class _GlassSwitchTile extends StatelessWidget {
  const _GlassSwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppFont.w600.s13.copyWith(color: Colors.white),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF67F5FC),
            inactiveTrackColor: Colors.white24,
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.black
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
