
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Core model: one reusable restriction that can be used by any religion / culture.
class RestrictionDefinition {
  /// Stable ID used in rules and by the LLM, e.g. "contains_pork".
  final String id;

  /// Short label suitable for UI display.
  final String title;

  /// Instruction-like description explaining what to flag / how to interpret.
  final String description;

  /// Example keywords or phrases that typically match this restriction.
  /// These are hints for the LLM and for debugging, not a complete list.
  final List<String> examples;

  /// Suggested icon for UI representation.
  final IconData icon;

  const RestrictionDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.examples,
    required this.icon,
  });
}

/// Global dictionary of all restriction types the system understands.
/// Religions / strictness levels will ONLY reference these by ID.
const Map<String, RestrictionDefinition> restrictionDefinitions = {
  // ---------------------------------------------------------------------------
  // MEAT & ANIMAL SOURCES
  // ---------------------------------------------------------------------------

  "contains_pork": RestrictionDefinition(
    id: "contains_pork",
    title: "Pork ingredients",
    description:
        "Flag if the ingredient list includes pork or pork-derived ingredients. "
        "This covers obvious and cured forms of pork. "
        "Treat any term that clearly indicates pork as non-compliant when pork is not allowed.",
    examples: <String>[
      "pork",
      "bacon",
      "ham",
      "lard",
      "pork fat",
      "pork gelatin",
      "porcine",
      "pancetta",
      "speck",
      "prosciutto",
      "salami",
      "chorizo",
      "guanciale",
      "char siu",
      "jamon",
      "jamón",
      "lap yuk",
      "sow",
      "hog",
      "porc",
      "porco",
      "porchetta",
      "jamón serrano",
      "jamon serrano",
      "pepperoni",
      "mortadella",
      "salumi"
    ],
    icon: Symbols.block_rounded,
  ),

  "contains_beef": RestrictionDefinition(
    id: "contains_beef",
    title: "Beef ingredients",
    description:
        "Flag if the ingredient list includes beef, cow meat or beef-derived ingredients. "
        "This includes beef fat, extracts and bovine terms. "
        "Use this when beef is not allowed for cultural or religious reasons.",
    examples: <String>[
      "beef",
      "beef fat",
      "beef extract",
      "bovine",
      "bovine gelatin",
      "bovine extract",
      "cow",
      "cow meat",
      "cow fat",
      "ox",
      "ox meat",
      "ox fat",
      "beef stock",
      "beef bouillon",
      "tallow",
      "jerky",
      "bovino",
      "beef tallow",
      "bovine collagen",
      "suet",
      "bouillon de boeuf",
      "extract de boeuf",
      "köttbuljong",
      "naudanlihaliemi"
    ],
    icon: Symbols.restaurant_menu_rounded,
  ),

  "contains_meat_general": RestrictionDefinition(
    id: "contains_meat_general",
    title: "Meat ingredients",
    description:
        "Flag if the ingredient list includes any kind of meat or meat-derived ingredient. "
        "This includes red meat, poultry and generic meat terms, as well as stocks and extracts made from meat.",
    examples: <String>[
      "meat",
      "meat extract",
      "meat concentrate",
      "meat powder",
      "meat flavour",
      "meat flavor",
      "animal protein",
      "chicken",
      "chicken extract",
      "chicken powder",
      "turkey",
      "duck",
      "lamb",
      "lamb extract",
      "stock",
      "broth",
      "animal extract",
      "liha",
      "lihaproteiini",
      "fleisch",
      "carnes",
      "bouillon",
      "meat stock",
      "meat broth"
    ],
    icon: Symbols.dinner_dining_rounded,
  ),

  "contains_fish_or_seafood": RestrictionDefinition(
    id: "contains_fish_or_seafood",
    title: "Fish and seafood",
    description:
        "Flag if the ingredient list includes fish or generic seafood. "
        "This includes named fish, fish sauces and fish-based flavourings.",
    examples: <String>[
      "fish",
      "tuna",
      "salmon",
      "cod",
      "hake",
      "pollock",
      "whitefish",
      "anchovy",
      "anchovy paste",
      "fish sauce",
      "fish broth",
      "fish collagen",
      "seafood",
      "seafood flavor",
      "surimi",
      "bonito",
      "bonito flakes",
      "dashi",
      "tuna oil",
      "tilapia",
      "pangasius",
      "saithe",
      "fish extract",
      "seafood stock",
      "seafood broth"

    ],
    icon: Symbols.set_meal_rounded,
  ),

  "contains_shellfish_crustaceans": RestrictionDefinition(
    id: "contains_shellfish_crustaceans",
    title: "Shellfish and crustaceans",
    description:
        "Flag if the ingredient list includes shellfish or crustaceans. "
        "This is relevant for shellfish allergies and some religious diets. "
        "Includes shrimp, prawns, crab, lobster and similar seafood.",
    examples: <String>[
      "shrimp",
      "prawn",
      "prawn paste",
      "crab",
      "lobster",
      "crayfish",
      "mussels",
      "clams",
      "oysters",
      "krill",
      "scampi",
      "seafood mix",
      "langoustine",
      "ebi",
      "cockle",
      "whelk",
      "clam extract",
      "shrimp extract",
      "seafood extract"
    ],
    icon: Symbols.set_meal_rounded,
  ),

  "contains_blood_products": RestrictionDefinition(
    id: "contains_blood_products",
    title: "Blood products",
    description:
        "Flag if the ingredient list includes blood or blood-derived products. "
        "This includes blood powder, blood plasma and traditional blood sausages. "
        "Many religious and vegetarian diets avoid blood products entirely.",
    examples: <String>[
      "blood",
      "blood powder",
      "blood plasma",
      "hemoglobin",
      "haemoglobin",
      "pork blood",
      "beef blood",
      "duck blood",
      "black pudding",
      "blood sausage",
      "mustamakkara",
    ],
    icon: Symbols.bloodtype_rounded,
  ),

  // ---------------------------------------------------------------------------
  // COMMON ANIMAL PRODUCTS
  // ---------------------------------------------------------------------------

  "contains_eggs": RestrictionDefinition(
    id: "contains_eggs",
    title: "Eggs and egg products",
    description:
        "Flag if the ingredient list includes eggs or egg-derived ingredients. "
        "This is relevant for egg allergies and some vegetarian or religious diets.",
    examples: <String>[
      "egg",
      "eggs",
      "egg white",
      "egg yolk",
      "albumen",
      "whole egg powder",
      "egg powder",
      "lysozyme",
      "ovalbumin",
      "ovomucoid",
      "omelette powder",
    ],
    icon: Symbols.egg_alt_rounded,
  ),

  "contains_dairy": RestrictionDefinition(
    id: "contains_dairy",
    title: "Milk and dairy",
    description:
        "Flag if the ingredient list includes milk or dairy ingredients. "
        "This includes milk, cheese, cream, whey, casein and other dairy-derived components.",
    examples: <String>[
      "milk",
      "skimmed milk",
      "whole milk",
      "milk powder",
      "milk solids",
      "cream",
      "butter",
      "clarified butter",
      "ghee",
      "cheese",
      "cheddar",
      "ricotta",
      "cream cheese",
      "paneer",
      "kefir",
      "curd",
      "yogurt",
      "whey",
      "whey powder",
      "casein",
      "caseinate",
      "lactose",
      "lactalbumin",
      "laktoosi",
      "laktos",
      "buter",
      "mlk",
      "milkfat / milk fat",
      "butter fat",
      "lactoserum"
    ],
    icon: Symbols.icecream_rounded,
  ),

  "contains_honey": RestrictionDefinition(
    id: "contains_honey",
    title: "Honey and bee products",
    description:
        "Flag if the ingredient list includes honey or bee-derived products. "
        "Some strict vegetarian or Jain diets avoid honey and related ingredients.",
    examples: <String>[
      "honey",
      "honey powder",
      "bee pollen",
      "royal jelly",
      "propolis",
      "manuka"
    ],
    icon: Symbols.bakery_dining_rounded,
  ),

  "contains_insect_derived_ingredients": RestrictionDefinition(
    id: "contains_insect_derived_ingredients",
    title: "Insect-derived ingredients",
    description:
        "Flag if the ingredient list includes insect-derived ingredients. "
        "This is relevant for vegan, vegetarian, Jain and some religious diets.",
    examples: <String>[
      "carmine",
      "cochineal",
      "cochineal extract",
      "e120",
      "shellac",
      "e904",
      "lac",
      "insect protein",
      "insect flour",
      "mealworm",
      "mealworm powder",
      "black soldier fly",
    ],
    icon: Symbols.bug_report_rounded,
  ),

  // ---------------------------------------------------------------------------
  // HALAL / KOSHER RELEVANT
  // ---------------------------------------------------------------------------

  "contains_alcohol": RestrictionDefinition(
    id: "contains_alcohol",
    title: "Alcohol",
    description:
        "Flag if the ingredient list includes alcohol or alcohol-based ingredients. "
        "This includes clear alcoholic drinks and alcohol used in flavourings or extracts.",
    examples: <String>[
      "alcohol",
      "ethanol",
      "ethyl alcohol",
      "wine",
      "beer",
      "cider",
      "rum",
      "brandy",
      "whisky",
      "whiskey",
      "liqueur",
      "mirin",
      "soju",
      "sake",
      "bourbon",
      "cognac",
      "rum extract",
      "sherry extract",
      "aroma (alcohol)",
      "alcohol-based flavouring",
      "spirit vinegar",

    ],
    icon: Symbols.no_drinks_rounded,
  ),

  "contains_gelatin": RestrictionDefinition(
    id: "contains_gelatin",
    title: "Gelatin",
    description:
        "Flag if the ingredient list includes gelatin or collagen-based gelling agents. "
        "Unless it is explicitly plant-based or clearly suitable for the user's diet, "
        "treat gelatin and collagen as potentially animal-derived.",
    examples: <String>[
      "gelatin",
      "gelatine",
      "bovine gelatin",
      "pork gelatin",
      "hydrolyzed collagen",
      "collagen peptides",
      "isenglass",
      "gummi base",
      "marshmallow base",
      "jelly agent",
      "E441",
      "gelatin hydrolysate"
    ],
    icon: Symbols.science_rounded,
  ),

  "contains_animal_enzymes": RestrictionDefinition(
    id: "contains_animal_enzymes",
    title: "Animal enzymes and rennet",
    description:
        "Flag if the ingredient list includes enzymes or rennet that are animal-derived or unspecified. "
        "If the origin is not clearly plant-based or microbial, treat as potentially animal-derived.",
    examples: <String>[
      "rennet",
      "animal rennet",
      "rennin",
      "lipase",
      "enzymes",
      "enzyme blend",
      "pepsin",
      "chymosin",
      "starter culture",
      "animal culture",
    ],
    icon: Symbols.biotech_rounded,
  ),

  "contains_animal_fats_unspecified": RestrictionDefinition(
    id: "contains_animal_fats_unspecified",
    title: "Unspecified animal fats",
    description:
        "Flag if fats or shortening are listed without a clearly plant-based or suitable origin. "
        "If the label only says 'fat' or 'shortening' without specifying that it is vegetable or plant-based, "
        "treat it as potentially animal-derived.",
    examples: <String>[
      "shortening",
      "shortening powder",
      "fat",
      "animal fat",
      "dripping",
      "tallow",
      "lard",
      "rendered fat",
      "stearic acid",
      "mono glycerides",
      "diglycerides",
      "shortening (animal)",
      "animal shortening"
    ],
    icon: Symbols.warning_rounded,
  ),

  "contains_haram_processing_aids": RestrictionDefinition(
    id: "contains_haram_processing_aids",
    title: "Alcohol or pork in processing",
    description:
        "Flag if the ingredient list clearly mentions that a component is prepared or carried in alcohol or pork-derived "
        "substances. This includes flavourings or extracts where alcohol is used as a carrier, Even if alcohol evaporates during manufacturing, still treat as not suitable.",
    examples: <String>[
      "extract in alcohol",
      "flavouring in alcohol",
      "flavoring in alcohol",
      "wine marinade",
      "rum flavour in alcohol",
      "rum flavor in alcohol",
      "vanilla extract",
      "ethanol extract",
      "liqueur flavor",
      "liqueur flavour",
      "caramel colour (alcohol)",
      "caramel color iv",
      "e150d"
    ],
    icon: Symbols.local_fire_department_rounded,
  ),

  "contains_risky_e_numbers": RestrictionDefinition(
    id: "contains_risky_e_numbers",
    title: "Potentially animal-derived E-numbers",
    description:
        "Flag if the ingredient list includes E-numbers that are often animal-derived or ambiguous for halal, kosher or "
        "vegetarian diets. These require additional checking or certification.",
    examples: <String>[
      "e120",
      "e124",
      "e441",
      "e471",
      "e472",
      "e542",
      "e904",
      "e913",
      "e920",
      "e921",
      "e631",
      "e627",
      "e1105",
      "e270",
      "e470",
      "e472 (mixed variants)"
    ],
    icon: Symbols.calculate_rounded,
  ),

  "contains_ambiguous_flavorings": RestrictionDefinition(
    id: "contains_ambiguous_flavorings",
    title: "Ambiguous flavours and spices",
    description:
        "Flag if the ingredient list includes very generic flavour or spice terms without clear origin. "
        "These may hide animal-based or alcohol-based carriers and often require extra checking.",
    examples: <String>[
      "natural flavour",
      "natural flavor",
      "natural flavours",
      "natural flavors",
      "artificial flavour",
      "artificial flavor",
      "artificial flavours",
      "artificial flavors",
      "flavouring substances",
      "flavoring substances",
      "spices",
      "mixed spices",
      "seasoning",
      "seasoning blend",
      "aroma",
      "umami flavor",
      "masala mix",
      "flavour",
      "aromas",
      "flavourings",
      "aromi",
      "arome",
      "flavor enhancers",
      "seasoning (unspecified)"

    ],
    icon: Symbols.help_center_rounded,
  ),

  "contains_non_kosher_seafood": RestrictionDefinition(
    id: "contains_non_kosher_seafood",
    title: "Non-kosher seafood",
    description:
        "For kosher diets, flag if the ingredient list includes seafood that is typically not kosher. "
        "This usually includes shellfish and some other non-finned or non-scaled seafood.",
    examples: <String>[
      "shrimp",
      "prawn",
      "crab",
      "lobster",
      "mussels",
      "clams",
      "oysters",
      "krill",
      "scampi",
      "calamari",
      "squid",
      "octopus",
      "eel",
    ],
    icon: Symbols.block_rounded,
  ),

  "contains_mixture_meat_and_dairy": RestrictionDefinition(
    id: "contains_mixture_meat_and_dairy",
    title: "Meat and dairy together",
    description:
        "For kosher diets, flag if meat and dairy ingredients both appear in the same product. "
        "If both meat (such as beef or chicken) and dairy (such as milk, cheese or whey) are present, "
        "treat the product as not kosher.",
    examples: <String>[
      "cheeseburger",
      "meat and cheese",
      "chicken and cheese",
      "meat lasagna",
      "chicken alfredo",
      "cream sauce with meat",
      "cheese sauce with meat",
    ],
    icon: Symbols.no_food_rounded,
  ),

  // Note: the following 'requires_*' rules usually result in
  // "cannot determine from ingredient list" if not explicitly labeled.

  "requires_halal_certification": RestrictionDefinition(
    id: "requires_halal_certification",
    title: "Halal certification required",
    description:
        "Use when the user requires formal halal certification. "
        "From the ingredient list alone, this cannot be fully verified unless the label clearly shows a halal logo or "
        "statement. If no such label is visible, respond that halal certification cannot be determined.",
    examples: <String>[
      "halal",
      "halal logo",
      "halal certified",
      "halal slaughtered",
    ],
    icon: Symbols.verified_rounded,
  ),

  "requires_zabiha_only": RestrictionDefinition(
    id: "requires_zabiha_only",
    title: "Zabiha slaughter required",
    description:
        "For strict halal diets, meat must come from animals slaughtered according to zabiha (dhabiha) rules. "
        "This cannot be verified from an ingredient list alone unless the packaging clearly states zabiha or a trusted "
        "halal certification. If no such label is visible, respond that this cannot be determined.",
    examples: <String>[
      "zabiha",
      "dhabiha",
    ],
    icon: Symbols.verified_rounded,
  ),

  "requires_kosher_certification": RestrictionDefinition(
    id: "requires_kosher_certification",
    title: "Kosher certification required",
    description:
        "For kosher diets, formal kosher certification is required. "
        "From the ingredient list alone, this cannot be fully verified unless a kosher symbol or clear kosher statement "
        "is present. If no such label is visible, respond that kosher status cannot be determined.",
    examples: <String>[
      "kosher",
      "kashrut",
      "kosher logo",
      "kosher certified",
      "ou",
    ],
    icon: Symbols.verified_user_rounded,
  ),

  // ---------------------------------------------------------------------------
  // PLANT-FOCUSED / JAIN / STRICT VEGETARIAN
  // ---------------------------------------------------------------------------

  "contains_root_vegetables": RestrictionDefinition(
    id: "contains_root_vegetables",
    title: "Root vegetables",
    description:
        "Flag if the ingredient list clearly includes root vegetables that some Jain or other strict diets avoid. "
        "Only flag when the root part is explicitly mentioned, such as potato or carrot.",
    examples: <String>[
      "potato",
      "sweet potato",
      "yam",
      "carrot",
      "beetroot",
      "radish",
      "turnip",
      "parsnip",
      "taro",
      "ginger"


    ],
    icon: Symbols.eco_rounded,
  ),

  "contains_alliums": RestrictionDefinition(
    id: "contains_alliums",
    title: "Onion, garlic and related",
    description:
        "Flag if the ingredient list includes strong allium vegetables such as onion, garlic, leek, chive or shallot, "
        "which some Jain or Buddhist traditions avoid.",
    examples: <String>[
      "onion",
      "garlic",
      "garlic paste",
      "leek",
      "chive",
      "shallot",
      "spring onion",
      "scallion",
      "asafoetida",
      "hing",
      "onion powder",
      "garlic powder"
    ],
    icon: Symbols.eco_rounded,
  ),

  "contains_any_animal_ingredient": RestrictionDefinition(
    id: "contains_any_animal_ingredient",
    title: "Any animal-derived ingredient",
    description:
        "For strict vegetarian or vegan diets, flag if any animal-derived ingredient is present. "
        "This includes meat, fish, seafood, eggs, dairy, honey, gelatin, animal fats, insect-derived ingredients "
        "and similar components.",
    examples: <String>[
      "meat",
      "chicken",
      "beef",
      "pork",
      "fish",
      "seafood",
      "egg",
      "eggs",
      "milk",
      "cheese",
      "butter",
      "cream",
      "yogurt",
      "honey",
      "gelatin",
      "animal fat",
      "lard",
      "tallow",
      "shellac",
      "carmine",
      "cochineal",
      "collagen",
    ],
    icon: Symbols.no_food_rounded,
  ),


  "contains_wine_extract_or_aroma": RestrictionDefinition(
    id: "contains_wine_extract_or_aroma",
    title: "Wine extracts or aromas",
    description:
    "Flag if the ingredient list includes wine-based extracts, wine-derived aromas, or flavourings made with wine. "
        "Even if the alcohol content evaporates during processing, wine-derived ingredients are not suitable for strict halal diets. "
        "This includes red wine extract, white wine extract, cooking wine, and wine aromas.",
    examples: <String>[
      "wine extract",
      "red wine extract",
      "white wine extract",
      "cooking wine",
      "wine aroma",
      "aroma (wine)",
      "wine flavour",
      "wine flavor",
      "wine-based extract",
      "vinho",
      "vinagre de vino",
      "vin blanc / vin rouge",
    ],
    icon: Symbols.no_drinks_rounded,
  ),


  "contains_non_vegetarian_additives": RestrictionDefinition(
    id: "contains_non_vegetarian_additives",
    title: "Non-vegetarian additives",
    description:
    "Flag if the ingredient list includes additives, emulsifiers, or amino acids that are commonly derived from animals "
        "unless explicitly stated as plant-based or microbial. "
        "These ingredients are often problematic for vegetarian, vegan, Jain, or Hindu diets.",
    examples: <String>[
      "l-cysteine",
      "cysteine",
      "l-cystine",
      "stearic acid",
      "mono glycerides",
      "monoglycerides",
      "diglycerides",
      "glycerin",
      "glycerine",
      "lecithin (unspecified)",
      "emulsifier (unspecified)",
      "e920",
      "e921",
      "e542",
      "e441",
      "mono- and diglycerides of fatty acids",
      "emulsifiers (E471, E472)",
      "fatty acid esters"
    ],
    icon: Symbols.warning_rounded,
  ),

  "contains_vinegar_from_wine": RestrictionDefinition(
    id: "contains_vinegar_from_wine",
    title: "Wine-based vinegar",
    description:
    "Flag if the ingredient list includes vinegar that is derived from wine. "
        "Wine vinegar originates from fermented wine and may not be suitable for strict halal diets, "
        "even if the alcohol has mostly evaporated. "
        "This includes red wine vinegar, white wine vinegar, and similar wine-derived vinegars.",
    examples: <String>[
      "wine vinegar",
      "red wine vinegar",
      "white wine vinegar",
      "vinagre de vino",
      "vinaigre de vin",
      "vinagre balsámico (wine-based)",

    ],
    icon: Symbols.no_drinks_rounded,
  ),


  "contains_l_cysteine": RestrictionDefinition(
    id: "contains_l_cysteine",
    title: "L-Cysteine (animal-derived)",
    description:
    "Flag if the ingredient list includes L-Cysteine or related amino acids. "
        "L-Cysteine is often derived from animal sources such as feathers or hair unless stated as plant-based or microbial. "
        "This ingredient is relevant for vegetarian, vegan, and some religious diets.",
    examples: <String>[
      "l-cysteine",
      "cysteine",
      "l-cystine",
      "e920",
      "e921",
    ],
    icon: Symbols.warning_rounded,
  ),

  "contains_unspecified_meat": RestrictionDefinition(
    id: "contains_unspecified_meat",
    title: "Unspecified meat",
    description:
    "Flag if the ingredient list includes meat without specifying the animal source. "
        "This is relevant for halal, kosher, Hindu, vegetarian, and other diets where the type of meat must be known. "
        "Only flag when the word refers to actual meat content, not artificial flavourings.",
    examples: <String>[
      "meat (14%)",
      "meat content",
      "animal meat",
      "mixed meat",
      "processed meat",
      "meat ingredient",
      "meat mixture",
      "animal-derived meat",
      "viande",
      "liha (unspecified)"
    ],
    icon: Symbols.help_center_rounded,
  ),

  "contains_ethanol_carrier": RestrictionDefinition(
    id: "contains_ethanol_carrier",
    title: "Alcohol-based carriers",
    description:
    "Flag if the ingredient list mentions that a flavour, extract, or aroma "
        "is prepared, dissolved, or carried in ethanol or alcohol. "
        "These processing aids are not suitable for strict halal diets even if the alcohol "
        "evaporates during production. Only flag when alcohol is explicitly referenced "
        "as a carrier or solvent.",
    examples: <String>[
      "carrier: ethanol",
      "carrier: ethyl alcohol",
      "solvent: ethanol",
      "solvent: alcohol",
      "ethanol-based extract",
      "extract (ethanol)",
      "extract (in alcohol)",
      "aroma (ethanol)",
      "flavouring in ethanol",
      "flavoring in ethanol",
      "alcohol-based extract",
      "alcohol carrier",
      "ethyl alcohol carrier",
      "extrakt med alkohol",
      "estratto idroalcolico",
      "alcool éthylique comme support"
    ],
    icon: Symbols.local_fire_department_rounded,
  ),

  "contains_fish_gelatin": RestrictionDefinition(
    id: "contains_fish_gelatin",
    title: "Fish-based gelatin",
    description:
    "Flag if the ingredient list includes gelatin derived from fish. "
        "Fish gelatin is common in confectionery, marshmallows, gummies, yogurt, "
        "and desserts. It is not suitable for vegetarian or vegan diets. "
        "For halal diets it may be acceptable depending on source, but the origin "
        "must still be clearly specified. Only flag when the gelatin is explicitly "
        "fish-derived.",
    examples: <String>[
      "fish gelatin",
      "gelatin (fish)",
      "fish-based gelatin",
      "gelatine (fish)",
      "hydrolyzed fish collagen",
      "fish collagen",
      "isenglass (fish gelatin)",
      "halo-halo gelatin (fish)",
      "marine gelatin",
    ],
    icon: Symbols.science_rounded,
  ),

  "contains_ritually_slaughtered_meat": RestrictionDefinition(
    id: "contains_ritually_slaughtered_meat",
    title: "Ritually-slaughtered meat",
    description:
    "Flag if the ingredient list includes meat that is halal-slaughtered, kosher-slaughtered, or produced using any "
        "religious ritual slaughter method. This includes halal, kosher, shechita, dhabiha, or any labelled ritual or "
        "blessed slaughter practices. If the label explicitly mentions these terms, treat the product as not suitable "
        "for Sikh diets that avoid kutha meat.",
    examples: <String>[
      "halal beef",
      "halal chicken",
      "kosher meat",
      "kosher beef",
      "shechita",
      "dhabiha",
      "ritually slaughtered",
      "religious slaughter",
      "sacrificial slaughter",
      "blessed meat",
    ],
    icon: Symbols.no_food_rounded,
  ),

  "contains_mushrooms": RestrictionDefinition(
    id: "contains_mushrooms",
    title: "Mushrooms and fungi",
    description:
    "Flag if the ingredient list includes mushrooms or fungi-based ingredients. "
        "Many strict Jain diets avoid mushrooms because they grow in microbe-rich environments "
        "and are considered to involve higher levels of unseen organisms.",
    examples: <String>[
      "mushroom",
      "button mushroom",
      "shiitake",
      "portobello",
      "oyster mushroom",
      "enoki",
      "chanterelle",
      "porcini",
      "truffle",
      "fungi",
      "fungus extract",
    ],
    icon: Symbols.eco_rounded,
  ),

  "contains_microbe_heavy_food": RestrictionDefinition(
    id: "contains_microbe_heavy_food",
    title: "Fermented or microbe-rich foods",
    description:
    "Flag if the ingredient list includes foods that are fermented or naturally high in microbial activity. "
        "Strict Jain diets avoid items that involve active microbial cultures, fermentation, or environments with dense micro-organisms.",
    examples: <String>[
      "yeast",
      "nutritional yeast",
      "brewer's yeast",
      "vinegar",
      "kombucha",
      "fermented",
      "fermentation",
      "fermented batter",
      "idli batter",
      "dosa batter",
      "sourdough",
      "tempeh",
      "kimchi",
      "sauerkraut",
      "miso",
      "pickled (fermented)",
      "culture",
      "live cultures",
      "active cultures",
    ],
    icon: Symbols.eco_rounded,
  ),


  "contains_palm_oil": RestrictionDefinition(
    id: "contains_palm_oil",
    title: "Palm oil",
    description:
    "Flag if the ingredient list includes palm oil or palm-fat derivatives. "
        "This is relevant for eco-friendly, climate-conscious, and clean-eating diets due to environmental concerns.",
    examples: <String>[
      "palm oil",
      "palm fat",
      "palm kernel oil",
      "palmolein",
      "hydrogenated palm oil",
      "hydrogenated palm fat",
      "vegetable oil (palm)",
      "vegetable fat (palm)",
    ],
    icon: Symbols.eco_rounded,
  ),

  "contains_ultra_processed": RestrictionDefinition(
    id: "contains_ultra_processed",
    title: "Ultra-processed ingredients",
    description:
    "Flag if the ingredient list contains multiple processed additives, stabilizers, colorings, or preservatives. "
        "Used for clean eating or whole-food-focused diets.",
    examples: <String>[
      "preservative",
      "stabilizer",
      "emulsifier",
      "color (E)",
      "artificial flavor",
      "modified starch",
      "hydrogenated oil",
      "maltodextrin",
      "anti-caking agent",
      "acidity regulator",
    ],
    icon: Symbols.warning_rounded,
  ),

  "contains_refined_sugar": RestrictionDefinition(
    id: "contains_refined_sugar",
    title: "Refined sugars",
    description:
    "Flag if the ingredient list includes refined sugars. "
        "Whole-food and clean-eating diets often avoid processed sugars.",
    examples: <String>[
      "sugar",
      "white sugar",
      "cane sugar",
      "glucose",
      "fructose",
      "sucrose",
      "invert sugar",
      "corn syrup",
      "high fructose corn syrup",
      "brown sugar",
    ],
    icon: Symbols.icecream_rounded,
  ),

  "contains_artificial_sweeteners": RestrictionDefinition(
    id: "contains_artificial_sweeteners",
    title: "Artificial sweeteners",
    description:
    "Flag if the ingredient list includes artificial or non-nutritive sweeteners. "
        "Clean-eating diets often avoid these additives.",
    examples: <String>[
      "aspartame",
      "acesulfame K",
      "sucralose",
      "saccharin",
      "cyclamate",
      "neotame",
      "stevia extract",
      "sorbitol",
      "xylitol",
      "erythritol",
      "maltitol",
    ],
    icon: Symbols.science_rounded,
  ),

  "contains_high_sodium": RestrictionDefinition(
    id: "contains_high_sodium",
    title: "High sodium",
    description:
    "Flag if the ingredient list or nutrition table indicates high sodium content. "
        "Useful for low-salt or heart-healthy diets. "
        "Flag only when sodium or salt appears prominently or as a seasoning base.",
    examples: <String>[
      "salt",
      "sodium",
      "monosodium glutamate",
      "sodium bicarbonate",
      "sodium benzoate",
      "soy sauce",
      "seasoning (salt-heavy)",
      "brine",
    ],
    icon: Symbols.health_and_safety_rounded,
  ),


  "contains_high_saturated_fat": RestrictionDefinition(
    id: "contains_high_saturated_fat",
    title: "High saturated fat",
    description:
    "Flag if the ingredient list includes fats and oils known for high saturated fat levels. "
        "Relevant for eco-friendly and heart-healthy diets.",
    examples: <String>[
      "palm oil",
      "coconut oil",
      "coconut fat",
      "butter",
      "ghee",
      "lard",
      "tallow",
      "hydrogenated oils",
    ],
    icon: Symbols.no_food_rounded,
  ),



  "contains_gluten": RestrictionDefinition(
    id: "contains_gluten",
    title: "Gluten and gluten grains",
    description:
    "Flag if the ingredient list includes gluten or gluten-containing grains. "
        "This includes wheat, barley, rye, malt, semolina, spelt, and ingredients derived from these grains. "
        "Use this for celiac disease, gluten intolerance, or gluten-avoidance diets.",
    examples: <String>[
      "wheat",
      "wheat flour",
      "whole wheat",
      "barley",
      "rye",
      "malt",
      "malt extract",
      "malt vinegar",
      "semolina",
      "spelt",
      "triticale",
      "durum",
      "farro",
      "couscous",
      "bulgur",
      "graham flour",
      "gluten",
      "vital wheat gluten",
      "seitan"
    ],
    icon: Symbols.warning_rounded,
  ),

  "contains_fodmap_triggers": RestrictionDefinition(
    id: "contains_fodmap_triggers",
    title: "FODMAP-trigger ingredients",
    description:
    "Flag if the ingredient list includes ingredients known to trigger symptoms in IBS or digestive sensitivity. "
        "This includes high-FODMAP sweeteners, fibers, and fermentable carbohydrates.",
    examples: <String>[
      "inulin",
      "chicory root",
      "chicory fiber",
      "fructo-oligosaccharides",
      "FOS",
      "oligofructose",
      "isomalto-oligosaccharides",
      "IMO",
      "mannitol",
      "sorbitol",
      "xylitol",
      "erythritol",
      "maltitol",
      "lactulose",
      "high fructose corn syrup",
      "HFCS",
      "honey",
      "agave syrup"
    ],
    icon: Symbols.health_and_safety_rounded,
  ),

  "contains_oxalate_risk": RestrictionDefinition(
    id: "contains_oxalate_risk",
    title: "Oxalate-rich ingredients",
    description:
    "Flag if the ingredient list includes ingredients naturally high in oxalates. "
        "Useful for users managing kidney stones or kidney-related dietary concerns. "
        "Only flag when the ingredient is clearly listed.",
    examples: <String>[
      "cocoa powder",
      "dark chocolate",
      "spinach powder",
      "beetroot powder",
      "almond flour",
      "almonds",
      "cashews",
      "soybeans",
      "soy flour",
      "rhubarb",
      "buckwheat"
    ],
    icon: Symbols.warning_rounded,
  ),
  "contains_acid_reflux_triggers": RestrictionDefinition(
    id: "contains_acid_reflux_triggers",
    title: "Acid reflux trigger ingredients",
    description:
    "Flag if the ingredient list includes ingredients known to trigger symptoms for users with acid reflux or GERD. "
        "This includes acidic powders, spices, stimulants, and citrus extracts.",
    examples: <String>[
      "tomato powder",
      "tomato paste",
      "citric acid",
      "lemon powder",
      "lime powder",
      "orange extract",
      "chili",
      "chili powder",
      "black pepper extract",
      "capsaicin",
      "mint",
      "peppermint extract",
      "coffee extract",
      "caffeine"
    ],
    icon: Symbols.no_food_rounded,
  ),


  "contains_caffeine": RestrictionDefinition(
    id: "contains_caffeine",
    title: "Caffeine and stimulants",
    description:
    "Flag if the ingredient list includes caffeine or stimulant-containing ingredients. "
        "Useful for users managing acid reflux, GERD, anxiety, sensitivity to stimulants, or thyroid-related symptoms.",
    examples: <String>[
      "caffeine",
      "coffee extract",
      "coffee powder",
      "tea extract",
      "black tea",
      "green tea extract",
      "yerba mate",
      "guarana",
      "energy drink base"
    ],
    icon: Symbols.flash_on_rounded,
  ),
  "contains_added_sugars": RestrictionDefinition(
    id: "contains_added_sugars",
    title: "Added sugars",
    description:
    "Flag if the ingredient list includes added sugars used for sweetness. "
        "Useful for diabetes, prediabetes, weight management, and heart health.",
    examples: <String>[
      "added sugar",
      "sugar",
      "invert sugar",
      "syrup",
      "glucose syrup",
      "malt syrup",
      "brown sugar",
      "agave syrup",
      "maple syrup",
      "date syrup"
    ],
    icon: Symbols.cake_rounded,
  ),

  "contains_lactose": RestrictionDefinition(
    id: "contains_lactose",
    title: "Lactose",
    description:
    "Flag if the ingredient list includes lactose or lactose-containing dairy components. "
        "Useful for lactose intolerance or digestive sensitivity.",
    examples: <String>[
      "lactose",
      "milk sugar",
      "whey",
      "whey powder",
      "milk solids",
      "milk powder",
    ],
    icon: Symbols.medication_liquid_rounded,
  ),

  "contains_fructose": RestrictionDefinition(
    id: "contains_fructose",
    title: "Fructose and fruit sugars",
    description:
    "Flag if the ingredient list includes fructose or fruit sugar concentrates. "
        "Useful for fructose malabsorption, IBS, and digestive sensitivity.",
    examples: <String>[
      "fructose",
      "high fructose corn syrup",
      "HFCS",
      "fruit concentrate",
      "apple juice concentrate",
      "pear juice concentrate",
      "agave",
    ],
    icon: Symbols.local_florist_rounded,
  ),

  "contains_raw_or_undercooked_risk": RestrictionDefinition(
    id: "contains_raw_or_undercooked_risk",
    title: "Raw or undercooked foods",
    description:
    "Flag if ingredients indicate raw or undercooked foods that may contain harmful bacteria during pregnancy. "
        "Includes raw fish, raw eggs, uncooked meats, or products not heat-treated.",
    examples: [
      "raw egg",
      "raw fish",
      "sushi",
      "sashimi",
      "carpaccio",
      "tartare",
      "unpasteurized",
      "raw milk",
    ],
    icon: Symbols.warning_rounded,
  ),
  "contains_high_mercury_fish": RestrictionDefinition(
    id: "contains_high_mercury_fish",
    title: "High-mercury fish",
    description:
    "Flag fish species high in mercury that should be avoided during pregnancy. "
        "Includes tuna, swordfish, king mackerel, marlin, and shark.",
    examples: [
      "tuna",
      "albacore",
      "bigeye tuna",
      "swordfish",
      "mackerel",
      "shark",
      "marlin",
    ],
    icon: Symbols.set_meal_rounded,
  ),
  "contains_unpasteurized_dairy": RestrictionDefinition(
    id: "contains_unpasteurized_dairy",
    title: "Unpasteurized dairy",
    description:
    "Flag if dairy ingredients are unpasteurized, raw or not heat-treated. "
        "Unpasteurized cheese, milk or cream carries a higher listeria risk.",
    examples: [
      "raw milk",
      "unpasteurized milk",
      "unpasteurised milk",
      "raw cheese",
      "farm cheese",
    ],
    icon: Symbols.icecream_rounded,
  ),

  "contains_soy": RestrictionDefinition(
    id: "contains_soy",
    title: "Soy and soy-derived ingredients",
    description:
    "Flag if the ingredient list includes soy or soy-derived products. "
        "Relevant for soy allergies, thyroid-related diets, hormonal sensitivity, "
        "and some fitness or clean-eating preferences.",
    examples: <String>[
      "soy",
      "soybean",
      "soy flour",
      "soy protein",
      "soy protein isolate",
      "soy protein concentrate",
      "soy lecithin",
      "soy sauce",
      "tofu",
      "tempeh",
      "edamame",
      "miso",
    ],
    icon: Symbols.set_meal_rounded,
  ),

  "contains_nuts_general": RestrictionDefinition(
    id: "contains_nuts_general",
    title: "Nuts and nut-derived ingredients",
    description:
    "Flag if the ingredient list includes nuts or nut-based ingredients. "
        "Useful for nut allergies, calorie-restricted diets, and some clean-eating rules.",
    examples: <String>[
      "almond",
      "walnut",
      "cashew",
      "hazelnut",
      "pistachio",
      "brazil nut",
      "pecan",
      "nut paste",
      "nut butter",
      "nut flour",
    ],
    icon: Symbols.nutrition_rounded, // fallback if icon missing
  ),

  "contains_seed_oils": RestrictionDefinition(
    id: "contains_seed_oils",
    title: "Seed oils and refined vegetable oils",
    description:
    "Flag if the ingredient list includes seed oils or refined vegetable oils. "
        "Relevant for clean eating, low-inflammatory diets, and modern fitness trends "
        "that avoid processed or high-omega-6 oils.",
    examples: <String>[
      "sunflower oil",
      "sunflower seed oil",
      "rapeseed oil",
      "canola oil",
      "soybean oil",
      "corn oil",
      "cottonseed oil",
      "grapeseed oil",
      "vegetable oil (unspecified)",
    ],
    icon: Symbols.oil_barrel_rounded,
  ),

  "contains_trans_fats": RestrictionDefinition(
    id: "contains_trans_fats",
    title: "Trans fats and hydrogenated oils",
    description:
    "Flag if the ingredient list includes trans fats or fully/partially hydrogenated oils. "
        "These are avoided in heart-healthy, weight-loss, and clean-eating diets.",
    examples: <String>[
      "hydrogenated oil",
      "partially hydrogenated oil",
      "hydrogenated vegetable oil",
      "shortening",
      "margarine",
      "trans fat",
      "vegetable shortening",
    ],
    icon: Symbols.warning_rounded,
  ),

  "contains_artificial_additives_general": RestrictionDefinition(
    id: "contains_artificial_additives_general",
    title: "Artificial additives",
    description:
    "Flag if the ingredient list includes artificial additives, colorings, stabilizers, "
        "or preservatives not aligned with whole-food or clean-eating diets.",
    examples: <String>[
      "preservative",
      "stabilizer",
      "color (E)",
      "artificial flavor",
      "artificial colouring",
      "modified starch",
      "anti-caking agent",
      "emulsifier (E472)",
      "E-numbers (synthetic)",
      "artificial sweetener",
    ],
    icon: Symbols.science_rounded,
  ),
  "contains_high_carbohydrate_sources": RestrictionDefinition(
    id: "contains_high_carbohydrate_sources",
    title: "High-carbohydrate ingredients",
    description:
    "Flag if the ingredient list includes carbohydrate-dense grains, starches, flours, "
        "or sugars that significantly increase carb load. "
        "Useful for keto, low-carb, balanced macro, and weight-management diets.",
    examples: <String>[
      "wheat flour",
      "white flour",
      "rice flour",
      "rice",
      "corn",
      "corn flour",
      "starch",
      "modified starch",
      "potato",
      "potato starch",
      "oats",
      "barley",
      "maltodextrin",
      "glucose syrup",
      "tapioca starch",
    ],
    icon: Symbols.bakery_dining_rounded,
  ),

  "contains_peanuts": RestrictionDefinition(
    id: "contains_peanuts",
    title: "Peanuts",
    description:
    "Flag if the ingredient list includes peanuts or peanut-derived ingredients. "
        "Relevant for peanut allergy, one of the most serious food allergens.",
    examples: <String>[
      "peanut",
      "peanuts",
      "groundnut",
      "groundnut oil",
      "peanut oil",
      "peanut flour",
      "peanut butter",
      "arachis oil",
    ],
    icon: Symbols.nutrition_rounded,
  ),
  "contains_treenuts": RestrictionDefinition(
    id: "contains_treenuts",
    title: "Tree nuts",
    description:
    "Flag if the ingredient list includes tree nuts such as almond, walnut, cashew, hazelnut, pecan or pistachio.",
    examples: <String>[
      "almond",
      "walnut",
      "cashew",
      "hazelnut",
      "pistachio",
      "pecan",
      "brazil nut",
      "macadamia",
      "nut paste",
      "nut flour",
    ],
    icon: Symbols.yard_rounded,
  ),
  "contains_sesame": RestrictionDefinition(
    id: "contains_sesame",
    title: "Sesame",
    description:
    "Flag if the ingredient list includes sesame seeds, tahini or sesame oil.",
    examples: <String>[
      "sesame",
      "sesame seeds",
      "tahini",
      "sesame oil",
      "sesamol",
    ],
    icon: Symbols.circle_rounded,
  ),
  "contains_mustard": RestrictionDefinition(
    id: "contains_mustard",
    title: "Mustard",
    description:
    "Flag if the ingredient list includes mustard seeds, mustard flour, mustard powder or mustard-based condiments.",
    examples: <String>[
      "mustard",
      "mustard seeds",
      "mustard flour",
      "mustard powder",
      "mustard paste",
    ],
    icon: Symbols.dinner_dining_rounded,
  ),
  "contains_sulfites": RestrictionDefinition(
    id: "contains_sulfites",
    title: "Sulfites",
    description:
    "Flag if the ingredient list includes sulfites or sulfur dioxide preservatives. "
        "This includes E220–E228 additives.",
    examples: <String>[
      "sulfites",
      "sulphites",
      "E220",
      "E221",
      "E222",
      "E223",
      "E224",
      "E226",
      "E227",
      "E228",
    ],
    icon: Symbols.science_rounded,
  ),
  "contains_celery": RestrictionDefinition(
    id: "contains_celery",
    title: "Celery",
    description:
    "Flag if the ingredient list includes celery stalks, celery seeds, celery root or celery salt.",
    examples: <String>[
      "celery",
      "celery salt",
      "celery seed",
      "celeriac",
    ],
    icon: Symbols.ramen_dining_rounded,
  ),
  "contains_lupin": RestrictionDefinition(
    id: "contains_lupin",
    title: "Lupin",
    description:
    "Flag if the ingredient list includes lupin flour, lupin seeds or lupin protein. "
        "Common in gluten-free baked products.",
    examples: <String>[
      "lupin",
      "lupin flour",
      "lupin protein",
      "lupin seeds",
    ],
    icon: Symbols.local_florist_rounded,
  ),
  "contains_molluscs": RestrictionDefinition(
    id: "contains_molluscs",
    title: "Molluscs",
    description:
    "Flag if the ingredient list includes clams, mussels, squid, octopus or mollusc extracts.",
    examples: <String>[
      "mussels",
      "clams",
      "squid",
      "octopus",
    ],
    icon: Symbols.directions_boat_filled_rounded,
  ),
  "contains_corn": RestrictionDefinition(
    id: "contains_corn",
    title: "Corn / Maize",
    description:
    "Flag if the ingredient list includes corn, maize or corn-derived sweeteners and starches.",
    examples: <String>[
      "corn",
      "maize",
      "corn starch",
      "maize starch",
      "maltodextrin",
      "dextrose",
      "corn syrup",
    ],
    icon: Symbols.grass_rounded,
  ),
  "contains_mango": RestrictionDefinition(
    id: "contains_mango",
    title: "Mango",
    description:
    "Flag if the ingredient list includes mango or mango-derived flavorings. "
        "Useful for fruit allergies.",
    examples: <String>[
      "mango",
      "mango pulp",
      "mango purée",
      "mango flavor",
      "dried mango",
    ],
    icon: Symbols.restaurant_rounded,
  ),


//ethical added here

  "contains_sugar": RestrictionDefinition(
    id: "contains_sugar",
    title: "Sugars (general)",
    description: "Flag if the ingredient list includes any sugar source including refined sugar, cane sugar, glucose, fructose, or sweet syrups.",
    examples: [
      "sugar",
      "sucrose",
      "glucose",
      "fructose",
      "cane sugar",
      "raw sugar",
      "invert sugar",
      "corn syrup",
      "glucose syrup",
      "brown sugar",
    ],
    icon: Symbols.cake_rounded,
  ),


  "contains_wheat": RestrictionDefinition(
    id: "contains_wheat",
    title: "Wheat",
    description: "Flag if wheat or wheat-derived ingredients are present.",
    examples: [
      "wheat",
      "wheat flour",
      "whole wheat",
      "wheat protein",
      "vital wheat gluten",
    ],
    icon: Symbols.grain_rounded,
  ),
  "contains_grains_general": RestrictionDefinition(
    id: "contains_grains_general",
    title: "Grains",
    description: "Flag grain ingredients such as wheat, barley, rye, oats, rice, corn, and grain-based flours.",
    examples: [
      "wheat",
      "barley",
      "rye",
      "oats",
      "rice",
      "corn",
      "maize",
      "semolina",
      "spelt",
    ],
    icon: Symbols.grain_rounded,
  ),
  "contains_starch": RestrictionDefinition(
    id: "contains_starch",
    title: "Starch",
    description: "Flag starches such as corn starch, potato starch, tapioca starch and modified starches.",
    examples: [
      "starch",
      "potato starch",
      "corn starch",
      "tapioca starch",
      "modified starch",
    ],
    icon: Symbols.bakery_dining_rounded,
  ),
  "contains_preservatives_general": RestrictionDefinition(
    id: "contains_preservatives_general",
    title: "Preservatives",
    description: "Flag if the ingredient list includes preservatives such as benzoates, sorbates, nitrates, or E-number preservatives.",
    examples: [
      "preservative",
      "sodium benzoate",
      "potassium sorbate",
      "calcium propionate",
      "nitrates",
      "nitrites",
      "E200",
      "E202",
    ],
    icon: Symbols.science_rounded,
  ),
  "contains_high_fat": RestrictionDefinition(
    id: "contains_high_fat",
    title: "High-fat ingredients",
    description: "Flag butter, oils, cream, cheese, and other high-fat sources.",
    examples: [
      "butter",
      "cream",
      "vegetable oil",
      "cheese",
      "fat",
      "lard",
      "tallow",
    ],
    icon: Symbols.oil_barrel_rounded,
  ),
  "contains_high_calorie_density": RestrictionDefinition(
    id: "contains_high_calorie_density",
    title: "High-calorie ingredients",
    description: "Flag calorie-dense ingredients such as oils, sugars, nuts, and high-carb fillers.",
    examples: [
      "sugar",
      "oil",
      "corn syrup",
      "nut butter",
      "cream",
      "maltodextrin",
    ],
    icon: Symbols.local_fire_department_rounded,
  ),



};
