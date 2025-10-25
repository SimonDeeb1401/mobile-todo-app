import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/task_provider.dart';

class EditTaskScreen extends StatefulWidget {
  const EditTaskScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
    required this.taskDescription,
    required this.taskDeadline,
    required this.taskPriority,
    required this.taskCollaborators,
  });

  final String taskId;
  final String taskTitle;
  final String taskDescription;
  final DateTime taskDeadline;
  final String taskPriority;
  final List<String> taskCollaborators;

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen>{
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _collaboratorController = TextEditingController();
  DateTime? _selectedDeadline;
  String _selectedPriority = 'Medium';
  List<String> _selectedCollaborators = [];
  Map<String, dynamic>? _participants = {};
  bool _collabsInitialized = false;
  bool _isLoading = false;

  final List<String> _priorities = ['Low', 'Medium', 'High'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _collaboratorController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current task values
    _titleController.text = widget.taskTitle;
    _descriptionController.text = widget.taskDescription;
    //_collaboratorController.text = widget.taskCollaborators.join(', ');
    _selectedDeadline = widget.taskDeadline;
    // Capitalize first letter to match dropdown items
    _selectedPriority = widget.taskPriority[0].toUpperCase() + widget.taskPriority.substring(1).toLowerCase();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      // Try to read a cached snapshot synchronously
      final snapshot = taskProvider.getCollaboratorsSnapshot(widget.taskId);
      if (snapshot != null) {
        _participants = snapshot;
        _initializeCollaboratorsFromParticipants();
        print("Initialized collaborators for task ${widget.taskId}: $_selectedCollaborators");
      } else {
        // Ensure provider is subscribed so it will populate the snapshot and notify listeners
        taskProvider.subscribeToCollaboratorsStream(widget.taskId);
        // If provider later notifies, build() can read the snapshot. For now we leave _selectedCollaborators as-is.
      }
    });
  }

  void _initializeCollaboratorsFromParticipants() {
    if (_collabsInitialized) return;
    final dynamic collaboratorsData = _participants?['collaborators'];
    if (collaboratorsData is Map) {
      _selectedCollaborators.addAll(collaboratorsData.values
          .where((c) => c is Map && c['email'] != null)
          .map<String>((c) => (c['email'] as String).toLowerCase())
          .toList());
      _selectedCollaborators = _selectedCollaborators.toSet().toList();
    } else if (collaboratorsData is List) {
      _selectedCollaborators.addAll(collaboratorsData
          .where((c) => c is Map && c['email'] != null)
          .map<String>((c) => (c['email'] as String).toLowerCase())
          .toList());
      _selectedCollaborators = _selectedCollaborators.toSet().toList();
    }
    _collabsInitialized = true;
    if (mounted) setState(() {});

  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  Future<void> _editTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final success = await taskProvider.editTask(
        taskId: widget.taskId,
        title: _titleController.text,
        description: _descriptionController.text,
        deadline: _selectedDeadline,
        priority: _selectedPriority.toLowerCase(),
        collaborators: _selectedCollaborators,
      );

      if(success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
            ),
          ),
        );
        // update provider cache so other screens reflect the change immediately
        taskProvider.updateCachedCollaborators(widget.taskId, _selectedCollaborators);
        Navigator.of(context).pop(_selectedCollaborators);
      }
    } catch (error) {
      _showErrorSnackBar(error.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    //_selectedCollaborators = widget.taskCollaborators;
    // final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    // final participants = taskProvider.getCollaboratorsData(widget.taskId);
    // final user = _participants?["user"];
    // final dynamic collaboratorsData = _participants?["collaborators"];
    // print("Userrrrrrr: $user");
    // print("Collaboratorssssssssss: $collaboratorsData");
    // if (collaboratorsData is Map) {
    //   setState(() {
    //     _selectedCollaborators.addAll(collaboratorsData.values
    //       .where((c) => c is Map && c['email'] != null)
    //       .map<String>((c) => (c['email'] as String).toLowerCase())
    //       .toList());
        
    //     _selectedCollaborators = _selectedCollaborators.toSet().toList();
    //   });
      
    // } else if (collaboratorsData is List) {
    //   setState(() {
    //     _selectedCollaborators.addAll(collaboratorsData
    //         .where((c) => c is Map && c['email'] != null)
    //         .map<String>((c) => c['email'] as String)
    //         .toList());

    //     _selectedCollaborators = _selectedCollaborators.toSet().toList();
    //   });
    // }
    // else {
    //   _selectedCollaborators = [];
    // }

    print("Selected collaborators: $_selectedCollaborators");

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingSmall),
            decoration: AppDecorations.iconContainerDecoration,
            child: Icon(
              Icons.arrow_back,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          'Edit Task',
          style: AppTextStyles.heading3,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section with icon
              Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.only(bottom: AppDimensions.paddingXLarge),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: AppDecorations.iconContainerDecoration,
                  child: Icon(
                    Icons.edit_note,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),

              // Task Title Field
              _buildInputField(
                controller: _titleController,
                label: 'Task Title',
                hint: 'Enter task title',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a task title';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppDimensions.paddingLarge),

              // Task Description Field
              _buildInputField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                hint: 'Enter task description',
                icon: Icons.description,
                maxLines: 4,
                validator: null,
              ),

              const SizedBox(height: AppDimensions.paddingLarge),

              // Priority Selector
              _buildPrioritySelector(),

              const SizedBox(height: AppDimensions.paddingLarge),

              // Deadline Selector
              _buildDeadlineSelector(),

              const SizedBox(height: AppDimensions.paddingXLarge),

              // Collaborators Section
              _buildCollaboratorsSection(),

              const SizedBox(height: AppDimensions.paddingXLarge),

              // Save Task Button
              _buildSaveButton(),

              const SizedBox(height: AppDimensions.paddingMedium),

              // Cancel Button
              _buildCancelButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Container(
          decoration: AppDecorations.inputFieldDecoration,
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: validator,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.primary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppDimensions.paddingMedium),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deadline (Optional)',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        InkWell(
          onTap: _selectDeadline,
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: AppDecorations.inputFieldDecoration,
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                Expanded(
                  child: Text(
                    _selectedDeadline != null
                        ? '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}'
                        : 'Select deadline',
                    style: _selectedDeadline != null
                        ? AppTextStyles.bodyLarge
                        : AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textHint,
                          ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
          decoration: AppDecorations.inputFieldDecoration,
          child: DropdownButtonFormField<String>(
            value: _selectedPriority,
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.flag,
                color: _getPriorityColor(_selectedPriority),
              ),
            ),
            style: AppTextStyles.bodyLarge,
            dropdownColor: AppColors.surface,
            items: _priorities.map((String priority) {
              return DropdownMenuItem<String>(
                value: priority,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priority),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    Text(priority),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedPriority = newValue!;
              });
            },
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildCollaboratorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Collaborators',
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),

        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: AppDecorations.inputFieldDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chips
              if (_selectedCollaborators.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedCollaborators.map((c) {
                      return Chip(
                        label: Text(c, style: AppTextStyles.bodySmall),
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            _selectedCollaborators.remove(c);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),

              // Text field for email entry
              Row(
                children: [
                  Icon(Icons.person_add_alt_1, color: AppColors.primary),
                  const SizedBox(width: AppDimensions.paddingMedium),
                  Expanded(
                    child: TextField(
                      controller: _collaboratorController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      style: AppTextStyles.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Type email and press Enter',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addCollaboratorFromInput(),
                    ),
                  ),
                  // Optional Add button
                  TextButton(
                    onPressed: _addCollaboratorFromInput,
                    child: Text('Add', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _addCollaboratorFromInput() {
    final raw = _collaboratorController.text.trim();
    if (raw.isEmpty) return;

    if (!_isValidEmail(raw)) {
      _showErrorSnackBar('Please enter a valid email address.');
      return;
    }
    if (_selectedCollaborators.contains(raw.toLowerCase())) {
      _showErrorSnackBar('This collaborator is already added.');
      return;
    }

    setState(() {
      _selectedCollaborators.add(raw.toLowerCase());
      _collaboratorController.clear();
    });
  }

  bool _isValidEmail(String email) {
    final r = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return r.hasMatch(email);
  }

  Widget _buildSaveButton() {
    return Container(
      height: 56,
      decoration: AppDecorations.buttonDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _editTask,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.save,
                        color: Colors.white,
                      ),
                      const SizedBox(width: AppDimensions.paddingSmall),
                      Text(
                        'Save Changes',
                        style: AppTextStyles.button,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(
          color: AppColors.textHint,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          child: Center(
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}