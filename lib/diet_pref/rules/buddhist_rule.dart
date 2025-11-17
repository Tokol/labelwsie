const List<String> buddhistBasic = [
  "contains_any_animal_ingredient", // informational only
];

const List<String> buddhistStandard = [
  "contains_meat_general",
  "contains_fish_or_seafood",
  "contains_shellfish_crustaceans",
  "contains_alliums", // onion/garlic — common Mahayana restriction
];
const List<String> buddhistStrict = [
  "contains_any_animal_ingredient",
  "contains_alliums",
  "contains_eggs",
  "contains_dairy",
  "contains_honey",
  "contains_insect_derived_ingredients",
  "contains_non_vegetarian_additives",
  "contains_animal_enzymes",
  "contains_gelatin",
  "contains_fish_gelatin",
];
