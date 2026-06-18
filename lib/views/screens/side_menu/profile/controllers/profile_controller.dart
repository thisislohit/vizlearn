import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../data/models/profile/profile_model.dart';
import '../../../../../data/repositories/profile_repository.dart';
import '../../../../../gen/assets.gen.dart';
import '../../../../../utils/app_utils.dart';
import '../../../../../views/widgets/custom_glass_dialog.dart';

class ProfileController extends GetxController {
  final ProfileRepository _profileRepository;

  ProfileController({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository;

  // Form key for validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Text editing controllers
  final TextEditingController schoolNameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController pinCodeController = TextEditingController();

  // Avatar image
  final Rx<File?> selectedAvatarImage = Rx<File?>(null);
  final RxString avatarPath = Assets.icons.profilePng.path.obs;

  // Profile data
  final Rx<ProfileModel?> profile = Rx<ProfileModel?>(null);
  
  // Convenience getters
  String get schoolName => profile.value?.name ?? 'School Admin';
  String get schoolAddress => profile.value?.address ?? '';
  String get schoolPincode => profile.value?.pincode ?? '';
  String get schoolImageUrl => profile.value?.imageUrl ?? '';
  String get schoolEmail => profile.value?.email ?? '';
  String get schoolMobile => profile.value?.mobile ?? '';

  // Loading state
  final RxBool isLoading = false.obs;
  final RxBool isLoadingProfile = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadProfileData();
  }

  @override
  void onClose() {
    schoolNameController.dispose();
    locationController.dispose();
    pinCodeController.dispose();
    super.onClose();
  }

  // Load existing profile data from cache
  void _loadProfileData() {
    _loadCachedProfile();
  }

  // Load profile from cache
  Future<void> _loadCachedProfile() async {
    try {
      final cachedResponse = await _profileRepository.getCachedProfile();
      if (cachedResponse != null && cachedResponse.success) {
        // Update profile data from cache
        profile.value = cachedResponse.data;
        
        // Update form controllers
        schoolNameController.text = cachedResponse.data.name;
        locationController.text = cachedResponse.data.address;
        pinCodeController.text = cachedResponse.data.pincode;
        
        // Update avatar path if image URL exists
        if (cachedResponse.data.imageUrl != null && cachedResponse.data.imageUrl!.isNotEmpty) {
          avatarPath.value = cachedResponse.data.imageUrl!;
        }
      }
    } catch (_) {
      // Ignore cache errors
    }
  }

  // Fetch profile from API (checks cache first, then API only if needed)
  Future<void> fetchProfile({bool forceRefresh = false}) async {
    if (isLoadingProfile.value) return;
    
    try {
      isLoadingProfile.value = true;
      
      // Load from cache first if not forcing refresh
      if (!forceRefresh) {
        if (profile.value == null) {
          await _loadCachedProfile();
        }
        
        // If we have cached data and not forcing refresh, skip API call
        if (profile.value != null) {
          isLoadingProfile.value = false;
          return;
        }
      }
      
      // Fetch from API only if no cached data exists or forceRefresh is true
      final response = await _profileRepository.getProfile();
      
      if (response.success) {
        // Update profile data
        profile.value = response.data;
        
        // Update form controllers
        schoolNameController.text = response.data.name;
        locationController.text = response.data.address;
        pinCodeController.text = response.data.pincode;
        
        // Update avatar path if image URL exists
        if (response.data.imageUrl != null && response.data.imageUrl!.isNotEmpty) {
          avatarPath.value = response.data.imageUrl!;
        }
      }
    } catch (e) {
      // If API fails and we don't have cached data, show error
      if (profile.value == null) {
        print('Failed to fetch profile: $e');
      }
      // Otherwise, silently fail - cached data will be used
    } finally {
      isLoadingProfile.value = false;
    }
  }

  // Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        selectedAvatarImage.value = File(image.path);
        avatarPath.value = image.path;
      }
    } catch (e) {
      AppUtils.showGetSnackbar('Error', 'Failed to pick image: $e');
    }
  }

  // Pick image from camera
  Future<void> pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        selectedAvatarImage.value = File(image.path);
        avatarPath.value = image.path;
      }
    } catch (e) {
      AppUtils.showGetSnackbar('Error', 'Failed to capture image: $e');
    }
  }

  // Show image source selection dialog
  Future<void> showImageSourceDialog() async {
    return CustomGlassDialog.show(
      context: Get.context!,
      title: 'Select Image Source',
      options: [
        DialogOption(
          icon: Icons.photo_library,
          title: 'Gallery',
          subtitle: 'Choose from your photos',
          color: const Color(0xFF6BC1FF),
          onTap: pickImageFromGallery,
        ),
        DialogOption(
          icon: Icons.camera_alt,
          title: 'Camera',
          subtitle: 'Take a new photo',
          color: const Color(0xFF6BF1A0),
          onTap: pickImageFromCamera,
        ),
      ],
    );
  }

  // Update profile
  Future<void> updateProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      isLoading.value = true;

      await _profileRepository.updateProfile(
        name: schoolNameController.text.trim(),
        address: locationController.text.trim(),
        pincode: pinCodeController.text.trim(),
        schoolImage: selectedAvatarImage.value,
      );

      // Refresh profile from API to get updated data including image URL
      await fetchProfile(forceRefresh: true);
      Get.back();
      AppUtils.showGetSnackbar(
        'Success',
        'Profile updated successfully',
      );
    } catch (e) {
      AppUtils.showGetSnackbar(
        'Error',
        'Failed to update profile: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Get profile data as map (for API calls)
  Map<String, dynamic> getProfileData() {
    return {
      'schoolName': schoolNameController.text.trim(),
      'location': locationController.text.trim(),
      'pinCode': pinCodeController.text.trim(),
      'avatarPath': selectedAvatarImage.value?.path ?? avatarPath.value,
    };
  }
}

