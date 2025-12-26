import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import '../theme/app_colors.dart';

/// Maps emoji strings to HeroIcon pairs (outline, solid) with associated colors.
/// This replaces all emoji usage throughout the app with HeroIcons.
class ChallengeIcons {
  /// Icon data containing outline and solid variants
  static final Map<String, ({IconData outline, IconData solid, Color defaultColor})> emojiToIcon = {
    // Breathing/Wind related
    '🌬️': (outline: HeroiconsOutline.cloud, solid: HeroiconsSolid.cloud, defaultColor: AppColors.info),
    
    // Relaxation/Calm
    '😌': (outline: HeroiconsOutline.faceSmile, solid: HeroiconsSolid.faceSmile, defaultColor: AppColors.secondary),
    
    // Cleaning/Organization
    '🧹': (outline: HeroiconsOutline.sparkles, solid: HeroiconsSolid.sparkles, defaultColor: AppColors.warning),
    
    // Yoga/Meditation
    '🧘': (outline: HeroiconsOutline.heart, solid: HeroiconsSolid.heart, defaultColor: AppColors.secondary),
    '🧘‍♀️': (outline: HeroiconsOutline.heart, solid: HeroiconsSolid.heart, defaultColor: AppColors.secondary),
    
    // Water/Hydration
    '💧': (outline: HeroiconsOutline.beaker, solid: HeroiconsSolid.beaker, defaultColor: AppColors.info),
    
    // Energy/Lightning
    '⚡': (outline: HeroiconsOutline.bolt, solid: HeroiconsSolid.bolt, defaultColor: AppColors.warning),
    
    // Running/Movement
    '🏃': (outline: HeroiconsOutline.arrowTrendingUp, solid: HeroiconsSolid.arrowTrendingUp, defaultColor: AppColors.success),
    
    // Sunset/Evening
    '🌇': (outline: HeroiconsOutline.sun, solid: HeroiconsSolid.sun, defaultColor: AppColors.warning),
    
    // Journal/Writing
    '📓': (outline: HeroiconsOutline.bookOpen, solid: HeroiconsSolid.bookOpen, defaultColor: AppColors.primary),
    
    // Rotation/Twist
    '🔄': (outline: HeroiconsOutline.arrowPath, solid: HeroiconsSolid.arrowPath, defaultColor: AppColors.info),
    
    // Fitness/Weights
    '🏋️': (outline: HeroiconsOutline.trophy, solid: HeroiconsSolid.trophy, defaultColor: AppColors.error),
    
    // Strength/Muscle
    '💪': (outline: HeroiconsOutline.handRaised, solid: HeroiconsSolid.handRaised, defaultColor: AppColors.error),
    
    // Tea/Drink
    '🍵': (outline: HeroiconsOutline.beaker, solid: HeroiconsSolid.beaker, defaultColor: AppColors.success),
    
    // Apple/Food
    '🍏': (outline: HeroiconsOutline.heart, solid: HeroiconsSolid.heart, defaultColor: AppColors.success),
    
    // Trash/Clean
    '🗑️': (outline: HeroiconsOutline.trash, solid: HeroiconsSolid.trash, defaultColor: AppColors.gray500),
    
    // Phone/Message
    '📱': (outline: HeroiconsOutline.devicePhoneMobile, solid: HeroiconsSolid.devicePhoneMobile, defaultColor: AppColors.info),
    
    // Coffee/Social
    '☕': (outline: HeroiconsOutline.chatBubbleLeftRight, solid: HeroiconsSolid.chatBubbleLeftRight, defaultColor: AppColors.warning),
    
    // High Five/Hand
    '✋': (outline: HeroiconsOutline.handRaised, solid: HeroiconsSolid.handRaised, defaultColor: AppColors.warning),
    
    // Eye/Vision
    '👀': (outline: HeroiconsOutline.eye, solid: HeroiconsSolid.eye, defaultColor: AppColors.info),
    
    // Stretch/Person
    '🙆': (outline: HeroiconsOutline.user, solid: HeroiconsSolid.user, defaultColor: AppColors.secondary),
    
    // Brain/Mind
    '🧠': (outline: HeroiconsOutline.lightBulb, solid: HeroiconsSolid.lightBulb, defaultColor: AppColors.primary),
    
    // Lightbulb/Idea
    '💡': (outline: HeroiconsOutline.lightBulb, solid: HeroiconsSolid.lightBulb, defaultColor: AppColors.warning),
    
    // Default fallback
    'default': (outline: HeroiconsOutline.star, solid: HeroiconsSolid.star, defaultColor: AppColors.primary),
  };

  /// Get icon data for an emoji string
  static ({IconData outline, IconData solid, Color defaultColor}) getIconForEmoji(String emoji) {
    return emojiToIcon[emoji] ?? emojiToIcon['default']!;
  }

  /// Get outline icon for an emoji
  static IconData getOutlineIcon(String emoji) {
    return getIconForEmoji(emoji).outline;
  }

  /// Get solid icon for an emoji
  static IconData getSolidIcon(String emoji) {
    return getIconForEmoji(emoji).solid;
  }

  /// Get default color for an emoji
  static Color getDefaultColor(String emoji) {
    return getIconForEmoji(emoji).defaultColor;
  }

  /// Icon mappings for mood tip icons
  static final Map<String, ({IconData outline, IconData solid})> moodTipIcons = {
    'sparkles': (outline: HeroiconsOutline.sparkles, solid: HeroiconsSolid.sparkles),
    'wave': (outline: HeroiconsOutline.arrowTrendingUp, solid: HeroiconsSolid.arrowTrendingUp),
    'seedling': (outline: HeroiconsOutline.arrowUp, solid: HeroiconsSolid.arrowUp),
    'leaf': (outline: HeroiconsOutline.cloud, solid: HeroiconsSolid.cloud),
    'heart': (outline: HeroiconsOutline.heart, solid: HeroiconsSolid.heart),
  };

  /// Get mood tip icon data
  static ({IconData outline, IconData solid}) getMoodTipIcon(String iconKey) {
    return moodTipIcons[iconKey] ?? (outline: HeroiconsOutline.star, solid: HeroiconsSolid.star);
  }
}
