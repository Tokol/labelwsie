import 'package:label_wise/diet_pref/rules/buddhist_rule.dart';
import 'package:label_wise/diet_pref/rules/christian_rule.dart';
import 'package:label_wise/diet_pref/rules/hindu_rules.dart';
import 'package:label_wise/diet_pref/rules/jains_rules.dart';
import 'package:label_wise/diet_pref/rules/jew_kosher_rule.dart';
import 'package:label_wise/diet_pref/rules/muslim_rules.dart';
import 'package:label_wise/diet_pref/rules/sikh_rules.dart';


const religionRuleMap = {
  "muslim": {
    "basic": muslimBasic,
    "standard": muslimStandard,
    "strict": muslimStrict,
  },
  "hindu":{
    "basic": hinduBasic,
    "standard": hinduStandard,
    "strict": hinduStrict,
  },
  "buddhist":{
    "basic": buddhistBasic,
    "standard": buddhistStandard,
    "strict": buddhistStrict,
  },

  "sikh":{
    "basic": sikhBasic,
    "standard": sikhStandard,
    "strict": sikhStrict,

  },

  "jain":{
    "basic": jainBasic,
    "standard":jainStandard,
    "strict":jainStrict,
  },

  "jewish":{
    "basic": kosherBasic,
    "standard": kosherStandard,
    "strict": kosherStrict,
  },

  "christian":{
    "basic": christianBasic,
    "standard": christianStandard,
    "strict": christianStrict,
  },

  // Hindu, Jewish, etc. will come later
};
