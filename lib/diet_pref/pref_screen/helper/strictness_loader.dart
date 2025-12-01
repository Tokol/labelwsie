import 'package:material_symbols_icons/symbols.dart';

import '../../rules/buddhist_rule.dart';
import '../../rules/christian_rule.dart';
import '../../rules/hindu_rules.dart';
import '../../rules/jains_rules.dart';
import '../../rules/jew_kosher_rule.dart';
import '../../rules/muslim_rules.dart';
import '../../rules/sikh_rules.dart';
import '../../strickness.dart';

List<StrictnessLevel> loadStrictness(String religionId) {
  switch (religionId) {
    case 'muslim':
      return [
        StrictnessLevel(
          id: 'basic',
          title: 'Basic guidelines',
          subtitle: 'Avoids pork, alcohol, and blood products.',
          icon: Symbols.sentiment_satisfied_rounded,
          isRecommended: false,
          rules: muslimBasic,
        ),
        StrictnessLevel(
          id: 'standard',
          title: 'Standard',
          subtitle: 'Most commonly followed halal requirements.',
          icon: Symbols.recommend_rounded,
          isRecommended: true,
          rules: muslimStandard,
        ),
        StrictnessLevel(
          id: 'strict',
          title: 'Strict (Zabiha only)',
          subtitle: 'Full halal rules with Zabiha requirement.',
          icon: Symbols.shield_rounded,
          isRecommended: false,
          rules: muslimStrict,
        ),
      ];

    case 'hindu':
      return [
        StrictnessLevel(
          id: 'basic',
          title: 'Basic guidelines',
          subtitle: 'Avoids beef and blood products.',
          icon: Symbols.sentiment_satisfied_rounded,
          isRecommended: true,
          rules: hinduBasic,
        ),
        StrictnessLevel(
          id: 'standard',
          title: 'Standard',
          subtitle: 'Hindu vegetarian-style rules.',
          icon: Symbols.recommend_rounded,
          isRecommended: false,
          rules: hinduStandard,
        ),
        StrictnessLevel(
          id: 'strict',
          title: 'Strict (Sattvic)',
          subtitle: 'Strict vegetarian + no onion & garlic.',
          icon: Symbols.shield_rounded,
          isRecommended: false,
          rules: hinduStrict,
        ),
      ];

    case 'buddhist':
      return [
        StrictnessLevel(
          id: 'basic',
          title: 'Basic',
          subtitle: 'No restrictions, general awareness.',
          icon: Symbols.sentiment_satisfied_rounded,
          isRecommended: true,
          rules: buddhistBasic,
          overrideLabel: "Awareness notes",
        ),
        StrictnessLevel(
          id: 'standard',
          title: 'Standard',
          subtitle: 'Avoids meat, seafood, and strong alliums.',
          icon: Symbols.recommend_rounded,
          isRecommended: false,
          rules: buddhistStandard,
        ),
        StrictnessLevel(
          id: 'strict',
          title: 'Strict',
          subtitle: 'Fully vegetarian + avoids allium.',
          icon: Symbols.shield_rounded,
          isRecommended: false,
          rules: buddhistStrict,
        ),
      ];

    case 'sikh':
      return [
        StrictnessLevel(
          id: 'basic',
          title: 'Basic',
          subtitle: 'Avoids only kutha meat.',
          icon: Symbols.sentiment_satisfied_rounded,
          isRecommended: true,
          rules: sikhBasic,
        ),
        StrictnessLevel(
          id: 'standard',
          title: 'Standard',
          subtitle: 'Mostly vegetarian, avoids meat/seafood.',
          icon: Symbols.recommend_rounded,
          isRecommended: false,
          rules: sikhStandard,
        ),
        StrictnessLevel(
          id: 'strict',
          title: 'Strict',
          subtitle: 'Fully vegetarian (Langar style) + no eggs.',
          icon: Symbols.shield_rounded,
          isRecommended: false,
          rules: sikhStrict,
        ),
      ];

    case 'jain':
      return [
        StrictnessLevel(
          id: 'basic',
          title: 'Basic Jain',
          subtitle: 'No meat, eggs, fish, onion or garlic.',
          icon: Symbols.sentiment_satisfied_rounded,
          isRecommended: false,
          rules: jainBasic,
        ),
        StrictnessLevel(
          id: 'standard',
          title: 'Standard Jain',
          subtitle: 'No root vegetables or honey.',
          icon: Symbols.recommend_rounded,
          isRecommended: true,
          rules: jainStandard,
        ),
        StrictnessLevel(
          id: 'strict',
          title: 'Strict Jain',
          subtitle:
          'Avoids fermentation, mushrooms, and microbe-rich foods.',
          icon: Symbols.shield_rounded,
          isRecommended: false,
          rules: jainStrict,
        ),
      ];

    case 'jewish':
      return [
        StrictnessLevel(
          id: 'basic',
          title: 'Basic Kosher',
          subtitle: 'Avoids pork and non-kosher seafood.',
          icon: Symbols.sentiment_satisfied_rounded,
          isRecommended: false,
          rules: kosherBasic,
        ),
        StrictnessLevel(
          id: 'standard',
          title: 'Standard Kosher',
          subtitle: 'No meat+dairy, requires certification.',
          icon: Symbols.recommend_rounded,
          isRecommended: true,
          rules: kosherStandard,
        ),
        StrictnessLevel(
          id: 'strict',
          title: 'Strict Kosher',
          subtitle: 'Only certified kosher products.',
          icon: Symbols.shield_rounded,
          isRecommended: false,
          rules: kosherStrict,
        ),
      ];

    case 'christian':
      return [

        StrictnessLevel(
          id: 'standard',
          title: 'Lent Mode',
          subtitle: 'Avoids meat and alcohol during Lent.',
          isRecommended: false,
          icon: Symbols.recommend_rounded,
          rules: christianStandard,
        ),
        StrictnessLevel(
          id: 'strict',
          title: 'Orthodox Fasting',
          subtitle: 'Vegan-style fasting. No meat, dairy, eggs, fish, or alcohol.',
          isRecommended: false,
          icon: Symbols.shield_rounded,
          rules: christianStrict,
        ),
      ];

    default:
      return [
        StrictnessLevel(
          id: 'basic',
          title: 'Basic',
          subtitle: 'Light restrictions.',
          icon: Symbols.sentiment_satisfied_rounded,
          isRecommended: false,
          rules: ['Avoids a few items'],
        ),
        StrictnessLevel(
          id: 'strict',
          title: 'Strict',
          subtitle: 'Full restrictions.',
          icon: Symbols.shield_rounded,
          isRecommended: false,
          rules: ['Avoids many items'],
        ),
      ];
  }
}
