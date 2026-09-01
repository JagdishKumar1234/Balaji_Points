import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/core/models/greeting_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform, File;

import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';

class SendGreetingPage extends StatefulWidget {
  const SendGreetingPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<SendGreetingPage> createState() => _SendGreetingPageState();
}

class _SendGreetingPageState extends State<SendGreetingPage> {
  final _messageController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _imagePicker = ImagePicker();
  final _session = SessionService();

  bool _showInApp = true;
  bool _sendWhatsapp = false;
  bool _sendSms = false;
  bool _isLoading = false;
  List<CarpenterInfo> _carpenters = [];
  bool _fetchedCarpenters = false;
  File? _selectedImageFile;

  @override
  void dispose() {
    _messageController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchCarpenters() async {
    if (_fetchedCarpenters) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isNotEqualTo: 'admin')
          .get();

      final carpenters = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return CarpenterInfo(
              id: doc.id,
              name: data['displayName'] ?? 'Unknown',
              phone: data['phone'] as String? ?? '',
            );
          })
          .where((c) => c.phone.isNotEmpty)
          .toList();

      setState(() {
        _carpenters = carpenters;
        _fetchedCarpenters = true;
      });
    } catch (e) {
      AppLogger.error('Failed to fetch carpenters', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch carpenters: $e'),
            backgroundColor: context.themeError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          _imageUrlController.clear();
        });
      }
    } catch (e) {
      AppLogger.error('Failed to pick image', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: context.themeError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          _imageUrlController.clear();
        });
      }
    } catch (e) {
      AppLogger.error('Failed to capture image', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: context.themeError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImageFile = null;
      _imageUrlController.clear();
    });
  }

  Future<String?> _uploadImageToStorage(File imageFile) async {
    try {
      final fileName = 'greeting_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('greeting_images/$fileName');

      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      AppLogger.error('Failed to upload image to storage', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: context.themeError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _sendGreetingNotificationToCarpenters(
      String message, String greetingId) async {
    try {
      // Fetch all carpenters with FCM tokens
      final snapshot = await _firestore
          .collection('users')
          .where('role', isNotEqualTo: 'admin')
          .get();

      int notificationCount = 0;

      // Send notification to each carpenter via notification_queue
      for (final userDoc in snapshot.docs) {
        final userData = userDoc.data();
        final fcmToken = userData['fcmToken'] as String?;
        final userId = userDoc.id;

        if (fcmToken != null && fcmToken.isNotEmpty) {
          try {
            // Queue notification for Cloud Function to send
            await _firestore.collection('notification_queue').add({
              'userId': userId,
              'fcmToken': fcmToken,
              'type': 'greeting',
              'title': '📢 New Announcement',
              'body': message.length > 100
                  ? message.substring(0, 100) + '...'
                  : message,
              'status': 'pending',
              'createdAt': Timestamp.now(),
              'data': {
                'greetingId': greetingId,
                'screen': '/home', // Deep link to home screen
              }
            });
            notificationCount++;
          } catch (e) {
            AppLogger.warning('Failed to queue notification for user $userId: $e');
          }
        }
      }

      AppLogger.info(
          '✅ Greeting notifications queued for $notificationCount carpenters');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification sent to $notificationCount carpenters'),
            backgroundColor: context.themePrimary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to send greeting notifications', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notifications: $e'),
            backgroundColor: context.themeError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sendGreeting() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_showInApp && !_sendWhatsapp && !_sendSms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one channel'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current admin user ID from session
      final currentUserId = await _session.getUserId();
      if (currentUserId == null) throw Exception('Not authenticated');

      // Handle image: upload file or use URL
      String? finalImageUrl;
      if (_selectedImageFile != null) {
        // Upload file to storage
        finalImageUrl = await _uploadImageToStorage(_selectedImageFile!);
        if (finalImageUrl == null && mounted) return; // Upload failed
      } else if (_imageUrlController.text.trim().isNotEmpty) {
        // Use provided URL
        finalImageUrl = _imageUrlController.text.trim();
      }

      // Always save greeting to Firestore (regardless of channels selected)
      // This is the core storage - channels are just delivery methods
      String? greetingId;
      {
        // Set previous active greeting to false
        final previousActive = await _firestore
            .collection('greetings')
            .where('active', isEqualTo: true)
            .get();

        final batch = _firestore.batch();

        for (final doc in previousActive.docs) {
          batch.update(doc.reference, {'active': false});
        }

        // Create new greeting
        final newGreeting = GreetingItem(
          id: '',
          message: message,
          createdAt: DateTime.now(),
          createdBy: currentUserId,
          active: _showInApp, // Only active if "Show in App" is checked
          expiresAt: null,
          imageUrl: finalImageUrl,
        );

        final greetingRef = _firestore.collection('greetings').doc();
        greetingId = greetingRef.id;
        batch.set(greetingRef, {
          'message': newGreeting.message,
          'createdAt': Timestamp.now(),
          'createdBy': currentUserId,
          'active': _showInApp, // Only active if "Show in App" is checked
          'expiresAt': null,
          'imageUrl': finalImageUrl,
        });

        await batch.commit();
        AppLogger.info('✅ Greeting saved to Firestore');
      }

      // Send FCM notification to all carpenters (if In-App is enabled)
      if (_showInApp) {
        await _sendGreetingNotificationToCarpenters(message, greetingId);
      }

      // WhatsApp/SMS: show confirmation list
      if (_sendWhatsapp || _sendSms) {
        await _fetchCarpenters();

        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GreetingConfirmationScreen(
                message: message,
                carpenters: _carpenters,
                sendWhatsapp: _sendWhatsapp,
                sendSms: _sendSms,
              ),
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Greeting sent successfully!'),
            backgroundColor: context.themePrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _messageController.clear();
        _imageUrlController.clear();
        setState(() {
          _selectedImageFile = null;
          _showInApp = true;
          _sendWhatsapp = false;
          _sendSms = false;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to send greeting', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: context.themeError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Greeting'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: context.themePrimary.withValues(alpha: 0.1),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Sending greeting...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.h4('Compose Message'),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _messageController,
                    maxLines: 6,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Enter greeting message for all carpenters',
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.md12,
                      ),
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppText.h4('Image (Optional)'),
                  const SizedBox(height: AppSpacing.md),
                  // Image upload/URL options
                  if (_selectedImageFile == null && _imageUrlController.text.isEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Pick from Gallery',
                            onPressed: _pickImageFromGallery,
                            variant: AppButtonVariant.secondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppButton(
                            label: 'Take Photo',
                            onPressed: _pickImageFromCamera,
                            variant: AppButtonVariant.secondary,
                          ),
                        ),
                      ],
                    ),
                  // Show preview if file selected
                  if (_selectedImageFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: AppRadius.md12,
                            child: Image.file(
                              _selectedImageFile!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white),
                              ),
                              onPressed: _clearImage,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppText.label('Or enter image URL:', color: context.themeTextSecondary),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _imageUrlController,
                      maxLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Enter image URL (JPG/PNG)',
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.md12,
                        ),
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                      ),
                      onChanged: (val) => setState(() {}),
                    ),
                    if (_imageUrlController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: ClipRRect(
                          borderRadius: AppRadius.md12,
                          child: Image.network(
                            _imageUrlController.text,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey.withValues(alpha: 0.2),
                                child: const Center(
                                  child: Text('Invalid image URL'),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AppText.h4('Select Channels'),
                  const SizedBox(height: AppSpacing.md),
                  _buildChannelCheckbox(
                    label: 'Show in App (Home Banner)',
                    value: _showInApp,
                    onChanged: (val) => setState(() => _showInApp = val ?? false),
                    description: 'Banner on carpenter home screen',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildChannelCheckbox(
                    label: 'WhatsApp',
                    value: _sendWhatsapp,
                    onChanged: (val) => setState(() => _sendWhatsapp = val ?? false),
                    description: 'Manual send via WhatsApp app',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildChannelCheckbox(
                    label: 'SMS',
                    value: _sendSms,
                    onChanged: (val) => setState(() => _sendSms = val ?? false),
                    description: 'Manual send via SMS app',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Send Greeting',
                    onPressed: _sendGreeting,
                    fullWidth: true,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Note: WhatsApp and SMS use device-assisted flow. Admin must confirm each message in the native app.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildChannelCheckbox({
    required String label,
    required bool value,
    required Function(bool?) onChanged,
    required String description,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.md12),
      child: CheckboxListTile(
        title: AppText.body(label),
        subtitle: Text(description, style: Theme.of(context).textTheme.bodySmall),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}

class CarpenterInfo {
  final String id;
  final String name;
  final String phone;

  CarpenterInfo({required this.id, required this.name, required this.phone});
}

class GreetingConfirmationScreen extends StatefulWidget {
  final String message;
  final List<CarpenterInfo> carpenters;
  final bool sendWhatsapp;
  final bool sendSms;

  const GreetingConfirmationScreen({
    super.key,
    required this.message,
    required this.carpenters,
    required this.sendWhatsapp,
    required this.sendSms,
  });

  @override
  State<GreetingConfirmationScreen> createState() =>
      _GreetingConfirmationScreenState();
}

class _GreetingConfirmationScreenState extends State<GreetingConfirmationScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  int _sentCount = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatPhone(String phone) {
    if (phone.length == 10) {
      return '91$phone';
    }
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<void> _sendWhatsapp(CarpenterInfo carpenter) async {
    try {
      final phoneFormatted = _formatPhone(carpenter.phone);
      final message = Uri.encodeComponent(widget.message);
      final url = 'https://wa.me/$phoneFormatted?text=$message';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        setState(() => _sentCount++);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('WhatsApp not available for ${carpenter.name}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('WhatsApp launch failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _sendSms(CarpenterInfo carpenter) async {
    try {
      final phoneFormatted = _formatPhone(carpenter.phone);
      final message = Uri.encodeComponent(widget.message);

      final separator = Platform.isIOS ? '&' : '?';
      final url = 'sms:$phoneFormatted$separator body=$message';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        setState(() => _sentCount++);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('SMS not available for ${carpenter.name}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('SMS launch failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _sendAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: const Text('Send to All?'),
        content: Text(
          'This will open ${widget.sendWhatsapp ? 'WhatsApp' : 'SMS'} for each carpenter.\n\nYou must manually tap Send in each app.\n\nContinue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Continue',
            onPressed: () => Navigator.pop(context, true),
            fullWidth: false,
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    for (int i = 0; i < widget.carpenters.length; i++) {
      if (!mounted) break;

      final carpenter = widget.carpenters[i];

      if (widget.sendWhatsapp) {
        await _sendWhatsapp(carpenter);
      } else if (widget.sendSms) {
        await _sendSms(carpenter);
      }

      // Small delay between opens
      await Future.delayed(const Duration(milliseconds: 500));

      // Show progress
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
          title: Text('Progress: ${i + 1}/${widget.carpenters.length}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Opened: ${carpenter.name}\n${carpenter.phone}',
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('Tap Send in the app, then tap OK here to continue.'),
            ],
          ),
          actions: [
            AppButton(
              label: 'Next',
              onPressed: () => Navigator.pop(context),
              fullWidth: false,
            ),
          ],
        ),
      );

      await Future.delayed(const Duration(seconds: 3));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sent to all $_sentCount carpenters'),
          backgroundColor: context.themePrimary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.carpenters.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirm Send')),
        body: const Center(
          child: Text('No carpenters found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.sendWhatsapp ? "WhatsApp" : "SMS"} - Carpenter ${_currentIndex + 1}/${widget.carpenters.length}'),
        centerTitle: true,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemCount: widget.carpenters.length,
        itemBuilder: (context, index) {
          final carpenter = widget.carpenters[index];
          return _buildCarpenterCard(carpenter);
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Send All',
                  onPressed: _sendAll,
                  variant: AppButtonVariant.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarpenterCard(CarpenterInfo carpenter) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: context.themePrimary.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: context.themePrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppText.h3(carpenter.name),
                  const SizedBox(height: AppSpacing.sm),
                  AppText.body(carpenter.phone, color: context.themeTextSecondary),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.themeBackground,
                      borderRadius: AppRadius.md12,
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: widget.sendWhatsapp ? 'Send via WhatsApp' : 'Send via SMS',
                    onPressed: () async {
                      if (widget.sendWhatsapp) {
                        await _sendWhatsapp(carpenter);
                      } else {
                        await _sendSms(carpenter);
                      }
                    },
                    fullWidth: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppButton(
                label: 'Previous',
                onPressed: _currentIndex > 0
                    ? () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                    : null,
                variant: AppButtonVariant.secondary,
              ),
              AppButton(
                label: 'Next',
                onPressed: _currentIndex < widget.carpenters.length - 1
                    ? () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                    : null,
                variant: AppButtonVariant.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
