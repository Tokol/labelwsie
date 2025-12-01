import 'package:material_symbols_icons/symbols.dart';

import '../../ethical_choice_screen.dart';
import 'package:flutter/material.dart';

import '../../rules/ethical_rules.dart';
class EthicalChoice {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> rules;

  const EthicalChoice({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.rules,
  });
}

  final List<EthicalChoice> choices = [
  EthicalChoice(
    id: "vegan",
    title: "Vegan",
    subtitle: "No animal products at all.",
    icon: Symbols.no_food_rounded,
    rules: veganRules,
  ),
  EthicalChoice(
    id: "vegetarian",
    title: "Vegetarian",
    subtitle: "No meat or seafood.",
    icon: Symbols.eco_rounded,
    rules: vegetarianRules,
  ),
  EthicalChoice(
    id: "pescatarian",
    title: "Pescatarian",
    subtitle: "Vegetarian + fish.",
    icon: Symbols.set_meal_rounded,
    rules: pescatarianRules,
  ),
  EthicalChoice(
    id: "pollo",
    title: "Pollo-vegetarian",
    subtitle: "Chicken allowed.",
    icon: Symbols.restaurant_menu_rounded,
    rules: polloVegetarianRules,
  ),
  EthicalChoice(
    id: "wfpb",
    title: "Whole-food",
    subtitle: "Plant-based + minimal processing.",
    icon: Symbols.energy_program_saving_rounded,
    rules: wholeFoodPlantBasedRules,
  ),
  EthicalChoice(
    id: "clean_eating",
    title: "Clean eating",
    subtitle: "Avoids additives & refined sugar.",
    icon: Symbols.health_and_safety_rounded,
    rules: cleanEatingRules,
  ),
  EthicalChoice(
    id: "eco",
    title: "Eco-friendly",
    subtitle: "Low-impact ingredients.",
    icon: Symbols.public_rounded,
    rules: ecoFriendlyRules,
  ),
  EthicalChoice(
    id: "raw_vegan",
    title: "Raw vegan",
    subtitle: "Uncooked plant foods.",
    icon: Symbols.spa_rounded,
    rules: rawVeganRules,
  ),
  EthicalChoice(
    id: "dairy_free",
    title: "Dairy-free",
    subtitle: "No milk products.",
    icon: Symbols.icecream_rounded,
    rules: dairyFreeRules,
  ),
  EthicalChoice(
    id: "honey_free",
    title: "Honey-free",
    subtitle: "No bee products.",
    icon: Symbols.bug_report_rounded,
    rules: honeyFreeRules,
  ),
  EthicalChoice(
    id: "cruelty_free",
    title: "Cruelty-free",
    subtitle: "No hidden animal additives.",
    icon: Symbols.pets_rounded,
    rules: crueltyFreeRules,
  ),
];