import '../models/challenge.dart';
import '../models/energy_level.dart';
import 'dart:math';

class ChallengeService {
  // Complete challenge database ported from React app
  static final Map<String, Map<EnergyLevel, List<GeneratedChallenge>>> _database = {
    'stress_reduction': {
      EnergyLevel.low: [
        const GeneratedChallenge(
          title: '4-7-8 Breathing',
          description: 'Inhale quietly for 4s, hold for 7s, exhale forcibly for 8s. Repeat 4 times.',
          duration: '2 mins',
          emoji: '🌬️',
          funFact: 'This pattern acts as a natural tranquilizer for the nervous system.',
        ),
        const GeneratedChallenge(
          title: 'Shoulder Drop',
          description: 'Close your eyes. Inhale and raise shoulders to ears. Exhale and drop them suddenly.',
          duration: '1 min',
          emoji: '😌',
          funFact: 'We carry 60% of our stress tension in our trapezius muscles.',
        ),
      ],
      EnergyLevel.medium: [
        const GeneratedChallenge(
          title: 'Desk Declutter',
          description: 'Spend 2 minutes organizing just the immediate space in front of you.',
          duration: '2 mins',
          emoji: '🧹',
          funFact: 'Visual clutter competes for your attention, increasing cognitive load.',
        ),
      ],
      EnergyLevel.high: [
        const GeneratedChallenge(
          title: 'Progressive Relaxation',
          description: 'Tense every muscle in your body for 5s, then release instantly. Feel the rush.',
          duration: '2 mins',
          emoji: '🧘',
          funFact: 'Contrast relaxation helps you identify tension you didn\'t know you had.',
        ),
      ],
    },
    'increased_energy': {
      EnergyLevel.low: [
        const GeneratedChallenge(
          title: 'Hydration Boost',
          description: 'Drink a full glass of cold water immediately. Sit upright.',
          duration: '1 min',
          emoji: '💧',
          funFact: 'Even 1% dehydration causes a significant drop in focus and energy.',
        ),
      ],
      EnergyLevel.medium: [
        const GeneratedChallenge(
          title: 'Desk Jumping Jacks',
          description: 'Stand up. Do 20 jumping jacks right next to your desk.',
          duration: '1 min',
          emoji: '⚡',
          funFact: 'Short bursts of cardio increase blood flow to the brain immediately.',
        ),
      ],
      EnergyLevel.high: [
        const GeneratedChallenge(
          title: 'Stair Sprint',
          description: 'Walk briskly up and down a flight of stairs (or walk the hallway) twice.',
          duration: '3 mins',
          emoji: '🏃',
          funFact: 'Stair climbing expends 8-9 times more energy than sitting.',
        ),
      ],
    },
    'better_sleep': {
      EnergyLevel.low: [
        const GeneratedChallenge(
          title: 'Digital Sunset',
          description: 'Adjust your screen brightness to the lowest setting or turn on \'Night Shift\' mode.',
          duration: '30 secs',
          emoji: '🌇',
          funFact: 'Blue light suppresses melatonin, the hormone that signals sleep.',
        ),
      ],
      EnergyLevel.medium: [
        const GeneratedChallenge(
          title: 'Worry Journaling',
          description: 'Write down 3 things stressing you out so you don\'t carry them home.',
          duration: '3 mins',
          emoji: '📓',
          funFact: 'Offloading thoughts to paper reduces pre-sleep cognitive arousal.',
        ),
      ],
      EnergyLevel.high: [
        const GeneratedChallenge(
          title: 'Forward Fold',
          description: 'Stand up, feet apart. Hinge at hips and let your head hang heavy towards toes.',
          duration: '1 min',
          emoji: '🧘‍♀️',
          funFact: 'Inversions activate the parasympathetic nervous system.',
        ),
      ],
    },
    'physical_fitness': {
      EnergyLevel.low: [
        const GeneratedChallenge(
          title: 'Seated Spinal Twist',
          description: 'Sit tall. Twist torso to the right, holding chair back. Hold 15s. Switch.',
          duration: '1 min',
          emoji: '🔄',
          funFact: 'Twisting compresses and releases digestive organs, aiding detox.',
        ),
      ],
      EnergyLevel.medium: [
        const GeneratedChallenge(
          title: 'Chair Squats',
          description: 'Stand in front of chair. Lower hips to touch seat, then stand back up. Do 15.',
          duration: '2 mins',
          emoji: '🏋️',
          funFact: 'Squats engage the largest muscle groups, burning more calories.',
        ),
      ],
      EnergyLevel.high: [
        const GeneratedChallenge(
          title: 'Desk Pushups',
          description: 'Place hands on desk edge. Step back. Lower chest to desk and push up. Do 15.',
          duration: '2 mins',
          emoji: '💪',
          funFact: 'Compound movements build functional strength for posture.',
        ),
      ],
    },
    'healthy_eating': {
      EnergyLevel.low: [
        const GeneratedChallenge(
          title: 'Mindful Sip',
          description: 'Take a sip of tea or water. Hold it in your mouth for 5s, notice the temp.',
          duration: '30 secs',
          emoji: '🍵',
          funFact: 'Mindfulness slows consumption, aiding digestion signals.',
        ),
      ],
      EnergyLevel.medium: [
        const GeneratedChallenge(
          title: 'Green Snack Plan',
          description: 'Plan a healthy snack for your next break (fruit, nuts, or yogurt).',
          duration: '2 mins',
          emoji: '🍏',
          funFact: 'Protein and fiber combinations provide sustained energy release.',
        ),
      ],
      EnergyLevel.high: [
        const GeneratedChallenge(
          title: 'Pantry Audit',
          description: 'Check your immediate surroundings. Throw away one empty wrapper or junk item.',
          duration: '1 min',
          emoji: '🗑️',
          funFact: 'Environment design is the strongest predictor of habit success.',
        ),
      ],
    },
    'social_connection': {
      EnergyLevel.low: [
        const GeneratedChallenge(
          title: 'Gratitude Text',
          description: 'Send a quick text or Slack message to a colleague saying \'Thanks for your help\'.',
          duration: '1 min',
          emoji: '📱',
          funFact: 'Expressing gratitude boosts dopamine for both sender and receiver.',
        ),
      ],
      EnergyLevel.medium: [
        const GeneratedChallenge(
          title: 'Coffee Chat Request',
          description: 'Invite a coworker you haven\'t spoken to lately for a 5-min chat.',
          duration: '2 mins',
          emoji: '☕',
          funFact: 'Weak ties (acquaintances) are crucial for innovation and belonging.',
        ),
      ],
      EnergyLevel.high: [
        const GeneratedChallenge(
          title: 'Team High Five',
          description: 'Physically or virtually high-five a teammate for a recent win.',
          duration: '30 secs',
          emoji: '✋',
          funFact: 'Physical touch (even a fist bump) builds trust and cooperation.',
        ),
      ],
    },
  };
  
  // Quick challenges (pre-defined shortcuts from homepage)
  static const List<GeneratedChallenge> quickChallenges = [
    GeneratedChallenge(
      title: 'Instant Calm',
      description: 'Box breathing technique: Inhale 4s, Hold 4s, Exhale 4s, Hold 4s.',
      duration: '1 min',
      emoji: '🌬️',
      funFact: 'Box breathing triggers the parasympathetic nervous system.',
    ),
    GeneratedChallenge(
      title: 'Vision Reset',
      description: 'Look at something 20 feet away for 20 seconds. Blink rapidly.',
      duration: '30 sec',
      emoji: '👀',
      funFact: 'Reduces digital eye strain significantly.',
    ),
    GeneratedChallenge(
      title: 'Desk Stretch',
      description: 'Raise shoulders to ears, hold for 5s, drop suddenly. Repeat 3x.',
      duration: '45 sec',
      emoji: '🙆',
      funFact: 'Releases tension trapped in the trapezius muscles.',
    ),
  ];
  
  /// Get a random challenge from the database based on goal and energy level
  GeneratedChallenge getChallengeFromDb(String goalId, EnergyLevel energyLevel) {
    final goalCategory = _database[goalId];
    
    if (goalCategory == null) {
      // Fallback challenge
      return const GeneratedChallenge(
        title: 'Take a Breath',
        description: 'Just breathe deeply for a moment.',
        duration: '1 min',
        emoji: '🧘',
        funFact: 'Simple breathing resets focus.',
      );
    }
    
    final challenges = goalCategory[energyLevel] ?? goalCategory[EnergyLevel.medium] ?? [];
    
    if (challenges.isEmpty) {
      return const GeneratedChallenge(
        title: 'Take a Breath',
        description: 'Just breathe deeply for a moment.',
        duration: '1 min',
        emoji: '🧘',
        funFact: 'Simple breathing resets focus.',
      );
    }
    
    // Return random challenge from matching list
    final randomIndex = Random().nextInt(challenges.length);
    return challenges[randomIndex];
  }
}
