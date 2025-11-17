const List<String> hinduBasic = [
  "contains_beef",
  "contains_blood_products",
  "contains_unspecified_meat",
];

const List<String> hinduStandard = [
  // Basic rules
  "contains_beef",
  "contains_blood_products",
  "contains_unspecified_meat",

  // Common cultural restrictions
  "contains_pork",
  "contains_meat_general",
  "contains_fish_or_seafood",
  "contains_shellfish_crustaceans",
  "contains_eggs",
  "contains_gelatin",
  "contains_animal_fats_unspecified",
  "contains_non_vegetarian_additives",
  "contains_risky_e_numbers",
];

const List<String> hinduStrict = [
  // Standard restrictions
  "contains_beef",
  "contains_blood_products",
  "contains_unspecified_meat",
  "contains_pork",
  "contains_meat_general",
  "contains_fish_or_seafood",
  "contains_shellfish_crustaceans",
  "contains_eggs",
  "contains_gelatin",
  "contains_animal_fats_unspecified",
  "contains_non_vegetarian_additives",
  "contains_risky_e_numbers",

  // Strict vegetarian / sattvic rules
  "contains_any_animal_ingredient",
  "contains_alliums",
  "contains_alcohol",
  "contains_ambiguous_flavorings",
  "contains_l_cysteine",
  "contains_insect_derived_ingredients",
];
