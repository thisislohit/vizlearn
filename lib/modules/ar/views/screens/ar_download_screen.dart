import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../routes/app_routes.dart';
import '../../../../theme/app_font.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/extensions/sizedbox_extensions.dart';
import '../../../../views/widgets/custom_app_bar.dart';
import '../../../../views/widgets/custom_elevated_button2.dart';
import '../../../../views/widgets/custom_wrapper.dart';
import '../../controllers/ar_controller.dart';

class ArDownloadScreen extends StatefulWidget {
  const ArDownloadScreen({super.key});

  @override
  State<ArDownloadScreen> createState() => _ArDownloadScreenState();
}

class _ArDownloadScreenState extends State<ArDownloadScreen> {
  late final ArController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<ArController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    await _ctrl.initializeMarkers();
    if (_ctrl.allMarkersDownloaded) _goToScanner();
  }

  void _goToScanner() async {
    // Pre-request permission for a smoother transition
    await Permission.camera.request();
    if (mounted) Get.offNamed(AppRoutes.arScanner);
  }

  @override
  Widget build(BuildContext context) {
    return CustomWrapper(
      appBar: CustomAppBar(
        title: 'AR Mode',
        leadingBack: true,
        onLeadingTap: () => Get.back(),
      ),
      child: Obx(() => _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_ctrl.downloadPhase.value == ArDownloadPhase.error) {
      return _buildErrorView();
    }
    return _buildProgressView();
  }

  Widget _buildProgressView() {
    final phase = _ctrl.downloadPhase.value;
    final isDownloading = phase == ArDownloadPhase.downloading;
    final isFetching = phase == ArDownloadPhase.fetching;
    final isDone = phase == ArDownloadPhase.done;

    final stageText = _ctrl.loadStage.value.isNotEmpty
        ? _ctrl.loadStage.value
        : (isDownloading
            ? 'Downloading AR markers...'
            : isFetching
                ? 'Please wait while we fetch your AR markers.'
                : 'Setting things up...');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _buildIcon(isDone),
          AppSizes.xl.hS,
          Text(
            isDone
                ? 'All Ready!'
                : isFetching
                    ? 'Fetching Content...'
                    : isDownloading
                        ? 'Downloading AR Content'
                        : 'Preparing AR Experience',
            style: AppFont.w700.s24,
            textAlign: TextAlign.center,
          ),
          AppSizes.sm.hS,
          Text(
            isDone ? 'Your AR experience is ready to explore.' : stageText,
            style: AppFont.w400.s14.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          AppSizes.xl.hS,
          if (isDownloading) ...[
            _buildDownloadProgress(),
            AppSizes.xl.hS,
          ] else if (!isDone) ...[
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: AppColors.buttonPrimary,
                strokeWidth: 3,
              ),
            ),
            AppSizes.xl.hS,
          ],
          if (isDone)
            CustomElevatedButton2(
              text: 'Start AR Scanner',
              width: double.infinity,
              height: 52,
              onPressed: _goToScanner,
            ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildIcon(bool isDone) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDone ? AppColors.darkGreen : AppColors.buttonPrimary,
          width: 2,
        ),
      ),
      child: Icon(
        isDone ? Icons.check_circle_outline_rounded : Icons.download_rounded,
        color: isDone ? AppColors.darkGreen : AppColors.buttonPrimary,
        size: 44,
      ),
    );
  }

  Widget _buildDownloadProgress() {
    final pct = _ctrl.loadPercent.value;
    final completed = _ctrl.loadCompleted.value;
    final total = _ctrl.loadTotal.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              total > 0 ? '$completed of $total markers' : 'Downloading...',
              style: AppFont.w500.s13.copyWith(color: Colors.white70),
            ),
            Text(
              '$pct%',
              style: AppFont.w700.s22.copyWith(color: AppColors.buttonPrimary),
            ),
          ],
        ),
        AppSizes.sm.hS,
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
          child: LinearProgressIndicator(
            value: (pct / 100.0).clamp(0.0, 1.0),
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.buttonPrimary),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.red, width: 2),
            ),
            child: const Icon(Icons.wifi_off_rounded, color: AppColors.red, size: 44),
          ),
          AppSizes.xl.hS,
          Text(
            'Something went wrong',
            style: AppFont.w700.s22,
            textAlign: TextAlign.center,
          ),
          AppSizes.sm.hS,
          Text(
            _ctrl.errorMessage.value.isNotEmpty
                ? _ctrl.errorMessage.value
                : 'Please check your internet connection and try again.',
            style: AppFont.w400.s14.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          if (_ctrl.allMarkersDownloaded) ...[
            AppSizes.sm.hS,
            Text(
              'Previously downloaded content is available.',
              style: AppFont.w500.s13.copyWith(color: AppColors.darkGreen),
              textAlign: TextAlign.center,
            ),
          ],
          AppSizes.xl.hS,
          if (_ctrl.allMarkersDownloaded)
            CustomElevatedButton2(
              text: 'Start AR Scanner',
              width: double.infinity,
              height: 52,
              onPressed: _goToScanner,
            )
          else
            CustomElevatedButton2(
              text: 'Try Again',
              width: double.infinity,
              height: 52,
              leftIcon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              onPressed: () async {
                await _ctrl.retryDownload();
                if (_ctrl.allMarkersDownloaded) _goToScanner();
              },
            ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
