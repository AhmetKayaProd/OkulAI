import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kresai/app.dart'; // For TEST_LAB_MODE
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kresai/models/homework.dart';
import 'package:kresai/models/homework_submission.dart';
import 'package:kresai/models/homework_report.dart';
import 'package:kresai/services/homework_ai_service.dart';
import 'package:kresai/services/submission_store.dart';
import 'package:kresai/theme/tokens.dart';

class HomeworkSubmissionScreen extends StatefulWidget {
  final Homework homework;
  final HomeworkSubmission? existingSubmission;
  
  const HomeworkSubmissionScreen({
    super.key,
    required this.homework,
    this.existingSubmission,
  });

  @override
  State<HomeworkSubmissionScreen> createState() => _HomeworkSubmissionScreenState();
}

class _HomeworkSubmissionScreenState extends State<HomeworkSubmissionScreen> {

  final _textController = TextEditingController();
  final _aiService = HomeworkAIService();
  final _submissionStore = SubmissionStore();
  final _imagePicker = ImagePicker();
  final String? _currentUserId = TEST_LAB_MODE ? 'mock_parent_id' : FirebaseAuth.instance.currentUser?.uid;

  List<XFile> _selectedPhotos = []; // Use XFile for cross-platform support
  bool _isReviewing = false;
  bool _isSaving = false;
  AIReview? _aiReview;
  int _reviewCount = 0;
  String? _currentSubmissionId; // Track existing submission

  @override
  void initState() {
    super.initState();
    if (widget.existingSubmission != null) {
      _textController.text = widget.existingSubmission!.textContent ?? '';
      _aiReview = widget.existingSubmission!.aiReview;
      _reviewCount = widget.existingSubmission!.reviewCount;
      _currentSubmissionId = widget.existingSubmission!.id;
      // Note: Cannot restore local File objects from URLs
    }
  }

  Future<void> _pickImage() async {
    if (_selectedPhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimum 3 fotoğraf ekleyebilirsiniz')),
      );
      return;
    }

    if (TEST_LAB_MODE) {
      // Mock image selection for automation testing
      setState(() {
        // Use a dummy network image or asset path that works with Image.network
        _selectedPhotos.add(XFile('https://via.placeholder.com/300')); 
      });
      return;
    }

    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedPhotos.add(image);
      });
    }
  }

  Future<void> _submitForReview() async {
    if (_textController.text.trim().isEmpty && _selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen metin veya fotoğraf ekleyin')),
      );
      return;
    }

    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen giriş yapın')),
      );
      return;
    }

    setState(() {
      _isReviewing = true;
      _aiReview = null;
    });

    try {
      // Create/update submission in Firestore first (without AI review)
      final now = DateTime.now();
      final submission = HomeworkSubmission(
        id: _currentSubmissionId ?? '', // Firestore generates if empty
        homeworkId: widget.homework.id,
        studentId: _currentUserId!,
        parentId: _currentUserId!,
        submissionType: _selectedPhotos.isNotEmpty ? 'photo' : 'text',
        textContent: _textController.text.trim().isNotEmpty ? _textController.text.trim() : null,
        photoUrls: _selectedPhotos.isNotEmpty ? _selectedPhotos.map((f) => f.path).toList() : null,
        submittedAt: now,
        reviewCount: _reviewCount,
        sentToTeacher: false,
      );

      // Save to Firestore
      if (_currentSubmissionId == null || _currentSubmissionId!.isEmpty) {
        final newSubmission = await _submissionStore.createSubmissionFromObject(submission);
        _currentSubmissionId = newSubmission.id;
      } else {
        await _submissionStore.updateSubmission(submission);
      }

      // Now get AI review
      final review = await _aiService.reviewSubmission(
        submission: submission.copyWith(id: _currentSubmissionId!),
        homework: widget.homework.option,
      );

      // Update submission with AI review
      final reviewedSubmission = submission.copyWith(
        id: _currentSubmissionId!,
        aiReview: review,
        reviewCount: _reviewCount + 1,
      );
      await _submissionStore.updateSubmission(reviewedSubmission);

      if (mounted) {
        setState(() {
          _aiReview = review;
          _reviewCount++;
          _isReviewing = false;
        });

        // Show review result
        _showReviewDialog(review);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isReviewing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppTokens.errorLight,
          ),
        );
      }
    }
  }

  Future<void> _sendToTeacher() async {
    if (_currentSubmissionId == null || _currentUserId == null || _aiReview == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Mark as sent to teacher
      final submission = HomeworkSubmission(
        id: _currentSubmissionId!,
        homeworkId: widget.homework.id,
        studentId: _currentUserId!,
        parentId: _currentUserId!,
        submissionType: _selectedPhotos.isNotEmpty ? 'photo' : 'text',
        textContent: _textController.text.trim().isNotEmpty ? _textController.text.trim() : null,
        photoUrls: _selectedPhotos.isNotEmpty ? _selectedPhotos.map((f) => f.path).toList() : null,
        submittedAt: DateTime.now(),
        reviewCount: _reviewCount,
        sentToTeacher: true,
        aiReview: _aiReview,
      );

      await _submissionStore.updateSubmission(submission);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Öğretmene gönderildi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppTokens.errorLight,
          ),
        );
      }
    }
  }

  void _showReviewDialog(AIReview review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getVerdictIcon(review.verdict),
              color: _getVerdictColor(review.verdict),
            ),
            const SizedBox(width: 8),
            Text(review.verdict.label),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Confidence
              if (review.confidence < 0.7)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'AI güveni düşük, öğretmene danışabilirsiniz',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: AppTokens.spacing16),
              
              // Good points
              if (review.feedbackToParent.whatIsGood.isNotEmpty) ...[
                const Text(
                  'İyi Yapılanlar:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                ...review.feedbackToParent.whatIsGood.map((good) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check, size: 16, color: AppTokens.successLight),
                        const SizedBox(width: 4),
                        Expanded(child: Text(good, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  );
                }),
              ],
              
              const SizedBox(height: AppTokens.spacing12),
              
              // Improvements
              if (review.feedbackToParent.whatToImprove.isNotEmpty) ...[
                const Text(
                  'Geliştirilecekler:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                ...review.feedbackToParent.whatToImprove.map((improve) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16)),
                        Expanded(child: Text(improve, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  );
                }),
              ],
              
              const SizedBox(height: AppTokens.spacing12),
              
              // Hints
              if (review.feedbackToParent.hintsWithoutSolution.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(AppTokens.spacing12),
                  decoration: BoxDecoration(
                    color: AppTokens.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: AppTokens.primaryLight, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'İpuçları:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...review.feedbackToParent.hintsWithoutSolution.map((hint) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('💡 $hint', style: const TextStyle(fontSize: 12)),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.homework.option.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        children: [
          // Homework Instructions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assignment, color: AppTokens.primaryLight),
                      const SizedBox(width: 8),
                      const Text(
                        'Ödev Talimatları',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spacing12),
                  
                  // Goal
                  Text(
                    'Hedef:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTokens.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(widget.homework.option.goal),
                  
                  const SizedBox(height: AppTokens.spacing12),
                  
                  // Student Instructions
                  Text(
                    'Yapılacaklar:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTokens.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...widget.homework.option.studentInstructions.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${e.key + 1}. ${e.value}'),
                    );
                  }),
                  
                  // Materials
                  if (widget.homework.option.materials.isNotEmpty) ...[
                    const SizedBox(height: AppTokens.spacing12),
                    Text(
                      'Gerekli Malzemeler:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTokens.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...widget.homework.option.materials.map((m) => Text('• $m')),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTokens.spacing16),
          
          // Parent Guidance
          Card(
            color: AppTokens.primaryLight.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.family_restroom, color: AppTokens.primaryLight),
                      const SizedBox(width: 8),
                      const Text(
                        'Veliye Notlar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spacing8),
                  ...widget.homework.option.parentGuidance.map((guidance) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('💡 $guidance', style: const TextStyle(fontSize: 13)),
                    );
                  }),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTokens.spacing24),
          
          // Submission Area
          Text(
            'Ödevinizi Gönderin',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTokens.spacing12),
          
          // Text input
          if (widget.homework.option.submissionType == SubmissionType.text ||
              widget.homework.option.submissionType == SubmissionType.interactive)
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Cevabınız',
                hintText: 'Ödevinizi buraya yazın...',
                border: OutlineInputBorder(),
              ),
            ),
          
          const SizedBox(height: AppTokens.spacing12),
          
          // Photo upload
          if (widget.homework.option.submissionType == SubmissionType.photo) ...[
            if (_selectedPhotos.isEmpty)
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Fotoğraf Çek'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedPhotos.asMap().entries.map((entry) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                          ? Image.network(
                              entry.value.path,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image),
                              ),
                            )
                          : Image.file(
                              File(entry.value.path),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPhotos.removeAt(entry.key);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              if (_selectedPhotos.length < 3)
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Daha Fazla Ekle'),
                ),
            ],
          ],
          
          const SizedBox(height: AppTokens.spacing24),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isReviewing ? null : _submitForReview,
              icon: _isReviewing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isReviewing ? 'AI inceliyor...' : 'AI İncelemesi Al'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          // AI Review Result
          if (_aiReview != null) ...[
            const SizedBox(height: AppTokens.spacing24),
            Card(
              color: _getVerdictColor(_aiReview!.verdict).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getVerdictIcon(_aiReview!.verdict),
                          color: _getVerdictColor(_aiReview!.verdict),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getVerdictMessage(_aiReview!.verdict),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.spacing16),
                    
                    // Parent Choices
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _sendToTeacher,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(_isSaving ? 'Gönderiliyor...' : 'Öğretmene Gönder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTokens.successLight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Reset for revision
                          setState(() {
                            _aiReview = null;
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Düzeltip Tekrar Gönder'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          // TODO: Ask teacher with note
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Öğretmene danışma notu eklendi')),
                          );
                        },
                        icon: const Icon(Icons.help),
                        label: const Text('Öğretmene Danış (Not ile)'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          if (_reviewCount > 0) ...[
            const SizedBox(height: AppTokens.spacing16),
            Text(
              'İnceleme sayısı: $_reviewCount',
              style: TextStyle(
                fontSize: 12,
                color: AppTokens.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  IconData _getVerdictIcon(SubmissionVerdict verdict) {
    switch (verdict) {
      case SubmissionVerdict.readyToSend:
        return Icons.check_circle;
      case SubmissionVerdict.needsRevision:
        return Icons.edit;
      case SubmissionVerdict.uncertain:
        return Icons.help;
    }
  }

  Color _getVerdictColor(SubmissionVerdict verdict) {
    switch (verdict) {
      case SubmissionVerdict.readyToSend:
        return AppTokens.successLight;
      case SubmissionVerdict.needsRevision:
        return Colors.orange;
      case SubmissionVerdict.uncertain:
        return AppTokens.errorLight;
    }
  }

  String _getVerdictMessage(SubmissionVerdict verdict) {
    switch (verdict) {
      case SubmissionVerdict.readyToSend:
        return 'Harika! Öğretmene gönderebilirsiniz';
      case SubmissionVerdict.needsRevision:
        return 'Biraz daha geliştirilebilir';
      case SubmissionVerdict.uncertain:
        return 'Tam emin olamadım, yeniden deneyin veya öğretmene sorun';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
