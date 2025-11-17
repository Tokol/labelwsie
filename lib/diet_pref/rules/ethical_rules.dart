const List<String> veganRules = [
  "contains_any_animal_ingredient",
  "contains_dairy",
  "contains_eggs",
  "contains_honey",
  "contains_meat_general",
  "contains_fish_or_seafood",
  "contains_shellfish_crustaceans",
  "contains_gelatin",
  "contains_fish_gelatin",
  "contains_insect_derived_ingredients",
  "contains_animal_enzymes",
  "contains_non_vegetarian_additives",
  "contains_animal_fats_unspecified",
];

const List<String> vegetarianRules = [
  "contains_meat_general",
  "contains_fish_or_seafood",
  "contains_shellfish_crustaceans",
  "contains_animal_fats_unspecified",
  "contains_gelatin",
  "contains_fish_gelatin",
  "contains_insect_derived_ingredients",
];

const List<String> pescatarianRules = [
  "contains_meat_general",
  "contains_shellfish_crustaceans",
];


const List<String> polloVegetarianRules = [
  "contains_beef",
  "contains_pork",
  "contains_fish_or_seafood",
  "contains_shellfish_crustaceans",
  "contains_gelatin",
  "contains_fish_gelatin",
  "contains_animal_fats_unspecified",
];

const List<String> wholeFoodPlantBasedRules = [
  // vegan restrictions
  "contains_any_animal_ingredient",
  "contains_dairy",
  "contains_eggs",
  "contains_honey",
  "contains_meat_general",
  "contains_fish_or_seafood",
  "contains_shellfish_crustaceans",
  "contains_gelatin",
  "contains_fish_gelatin",
  "contains_insect_derived_ingredients",
  "contains_animal_enzymes",
  "contains_non_vegetarian_additives",
  "contains_animal_fats_unspecified",

  // minimal-processing rules
  "contains_ambiguous_flavorings",
  "contains_risky_e_numbers",
  "contains_ultra_processed",
  "contains_refined_sugar",
  "contains_artificial_sweeteners",
];

const List<String> cleanEatingRules = [
  "contains_ambiguous_flavorings",
  "contains_risky_e_numbers",
  "contains_non_vegetarian_additives",
  "contains_artificial_sweeteners",
  "contains_ultra_processed",
  "contains_refined_sugar",
  "contains_animal_fats_unspecified",
];
const List<String> ecoFriendlyRules = [
  "contains_beef",
  "contains_pork",
  "contains_palm_oil",
  "contains_high_saturated_fat",
  "contains_ambiguous_flavorings",
  "contains_risky_e_numbers",
];

const List<String> rawVeganRules = [
  // vegan exclusions
  "contains_any_animal_ingredient",
  "contains_dairy",
  "contains_eggs",
  "contains_honey",
  "contains_meat_general",
  "contains_fish_or_seafood",
  "contains_shellfish_crustaceans",
  "contains_gelatin",
  "contains_fish_gelatin",
  "contains_insect_derived_ingredients",
  "contains_animal_enzymes",
  "contains_non_vegetarian_additives",
  "contains_animal_fats_unspecified",

  // avoid processing
  "contains_ambiguous_flavorings",
  "contains_risky_e_numbers",
  "contains_ultra_processed",
];

const List<String> dairyFreeRules = [
  "contains_dairy",
];

const List<String> honeyFreeRules = [
  "contains_honey",
];

const List<String> crueltyFreeRules = [
  "contains_gelatin",
  "contains_fish_gelatin",
  "contains_insect_derived_ingredients",
  "contains_animal_enzymes",
  "contains_non_vegetarian_additives",
  "contains_animal_fats_unspecified",
];


