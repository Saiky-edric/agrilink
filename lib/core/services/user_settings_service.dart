import '../config/environment.dart';
import 'supabase_service.dart';

class UserSettingsModel {
  final String id;
  final String userId;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool darkMode;
  final String language;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserSettingsModel({
    required this.id,
    required this.userId,
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.smsNotifications = false,
    this.darkMode = false,
    this.language = 'en',
    required this.createdAt,
    this.updatedAt,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      pushNotifications: json['push_notifications'] ?? true,
      emailNotifications: json['email_notifications'] ?? true,
      smsNotifications: json['sms_notifications'] ?? false,
      darkMode: json['dark_mode'] ?? false,
      language: json['language'] as String? ?? 'en',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'push_notifications': pushNotifications,
      'email_notifications': emailNotifications,
      'sms_notifications': smsNotifications,
      'dark_mode': darkMode,
      'language': language,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserSettingsModel copyWith({
    String? id,
    String? userId,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? darkMode,
    String? language,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettingsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserSettingsService {
  final SupabaseService _supabase = SupabaseService.instance;

  // Get user settings
  Future<UserSettingsModel?> getUserSettings(String userId) async {
    try {
      final response = await _supabase.userSettings
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Create default settings if none exist
        return await createDefaultSettings(userId);
      }

      return UserSettingsModel.fromJson(response);
    } catch (e) {
      EnvironmentConfig.logError('Error getting user settings', e);
      return null;
    }
  }

  // Create default settings for new user
  Future<UserSettingsModel> createDefaultSettings(String userId) async {
    try {
      final response = await _supabase.userSettings.insert({
        'user_id': userId,
        'push_notifications': true,
        'email_notifications': true,
        'sms_notifications': false,
        'dark_mode': false,
        'language': 'en',
      }).select().single();

      return UserSettingsModel.fromJson(response);
    } catch (e) {
      EnvironmentConfig.logError('Error creating default user settings', e);
      rethrow;
    }
  }

  // Update user settings
  Future<UserSettingsModel> updateUserSettings({
    required String userId,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? darkMode,
    String? language,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (pushNotifications != null) {
        updateData['push_notifications'] = pushNotifications;
      }
      if (emailNotifications != null) {
        updateData['email_notifications'] = emailNotifications;
      }
      if (smsNotifications != null) {
        updateData['sms_notifications'] = smsNotifications;
      }
      if (darkMode != null) {
        updateData['dark_mode'] = darkMode;
      }
      if (language != null) {
        updateData['language'] = language;
      }

      final response = await _supabase.userSettings
          .update(updateData)
          .eq('user_id', userId)
          .select()
          .single();

      return UserSettingsModel.fromJson(response);
    } catch (e) {
      EnvironmentConfig.logError('Error updating user settings', e);
      rethrow;
    }
  }

  // Toggle notification settings
  Future<UserSettingsModel> togglePushNotifications(String userId) async {
    final settings = await getUserSettings(userId);
    if (settings == null) throw Exception('User settings not found');
    
    return await updateUserSettings(
      userId: userId,
      pushNotifications: !settings.pushNotifications,
    );
  }

  Future<UserSettingsModel> toggleEmailNotifications(String userId) async {
    final settings = await getUserSettings(userId);
    if (settings == null) throw Exception('User settings not found');
    
    return await updateUserSettings(
      userId: userId,
      emailNotifications: !settings.emailNotifications,
    );
  }

  Future<UserSettingsModel> toggleDarkMode(String userId) async {
    final settings = await getUserSettings(userId);
    if (settings == null) throw Exception('User settings not found');
    
    return await updateUserSettings(
      userId: userId,
      darkMode: !settings.darkMode,
    );
  }

  // Delete user settings (for account deletion)
  Future<void> deleteUserSettings(String userId) async {
    try {
      await _supabase.userSettings.delete().eq('user_id', userId);
    } catch (e) {
      EnvironmentConfig.logError('Error deleting user settings', e);
      rethrow;
    }
  }
}