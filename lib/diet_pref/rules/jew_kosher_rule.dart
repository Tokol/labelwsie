const List<String> kosherBasic = [
  "contains_pork",
  "contains_shellfish_crustaceans",
  "contains_non_kosher_seafood",
];

const List<String> kosherStandard = [
  ...kosherBasic,
  "contains_mixture_meat_and_dairy",
  "contains_gelatin",
  "contains_animal_enzymes",
  "contains_animal_fats_unspecified",
  "contains_ambiguous_flavorings",
  "requires_kosher_certification",
];

const List<String> kosherStrict = [
  ...kosherStandard,
  "contains_non_vegetarian_additives",
  "contains_l_cysteine",
  "contains_ethanol_carrier",
  "contains_fish_gelatin",
  "contains_risky_e_numbers",
  "contains_unspecified_meat",
];
