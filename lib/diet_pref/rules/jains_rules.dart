const List<String> jainBasic = [
  "contains_meat_general",
  "contains_fish_or_seafood",
  "contains_shellfish_crustaceans",
  "contains_eggs",
  "contains_alliums",   // onion, garlic, leek, chive
];

const List<String> jainStandard = [
  ...jainBasic,
  "contains_root_vegetables",           // potato, carrot, beet, ginger, etc.
  "contains_honey",                     // many Jains avoid honey
  "contains_insect_derived_ingredients" // carmine, shellac, etc.
];

const List<String> jainStrict = [
  ...jainStandard,
  "contains_mushrooms",                 // fungi & high-microbe foods
  "contains_microbe_heavy_food",        // yeast, vinegar, kombucha, fermented batter
  "contains_non_vegetarian_additives",  // E-numbers like E471/E472 from animals
  "contains_l_cysteine",                // often from feathers/hair
  "contains_gelatin",                   // animal gelatin
  "contains_fish_gelatin",
];