// ============================================================
// words.js — Word Data for Word Search Explorer
// ============================================================
// 50 Levels per mode, 10 words per level, 100% unique words
// ============================================================

const WORD_DATA = {

  totalLevels: 50,

  // ── English Mode: 50 Levels, 10 words each (500 unique words) ──
  english: [
    { level: 1,  words: ['CAT', 'DOG', 'BIRD', 'FISH', 'FROG', 'DUCK', 'DEER', 'BEAR', 'WOLF', 'LION'] },
    { level: 2,  words: ['BED', 'DOOR', 'LAMP', 'DESK', 'CHAIR', 'TABLE', 'CLOCK', 'SOFA', 'SHELF', 'RUG'] },
    { level: 3,  words: ['APPLE', 'PEACH', 'BERRY', 'MANGO', 'LEMON', 'GRAPE', 'MELON', 'PLUM', 'BREAD', 'HONEY'] },
    { level: 4,  words: ['SUN', 'RAIN', 'WIND', 'SNOW', 'STAR', 'MOON', 'CLOUD', 'STORM', 'FROST', 'LIGHT'] },
    { level: 5,  words: ['RED', 'BLUE', 'GOLD', 'PINK', 'CYAN', 'GREEN', 'WHITE', 'BLACK', 'BROWN', 'PAINT'] },
    { level: 6,  words: ['HAT', 'SHOE', 'BOOT', 'COAT', 'BELT', 'SHIRT', 'SCARF', 'JEANS', 'RING', 'WATCH'] },
    { level: 7,  words: ['CUP', 'FORK', 'SPOON', 'KNIFE', 'PLATE', 'BOWL', 'PAN', 'OVEN', 'STOVE', 'SPICE'] },
    { level: 8,  words: ['BOOK', 'PEN', 'PAPER', 'RULER', 'CHALK', 'CLASS', 'STUDY', 'LEARN', 'WRITE', 'READ'] },
    { level: 9,  words: ['SONG', 'NOTE', 'DRUM', 'PIANO', 'FLUTE', 'BELL', 'VOICE', 'SOUND', 'BEAT', 'CHORD'] },
    { level: 10, words: ['BALL', 'GOAL', 'SWIM', 'JUMP', 'RACE', 'SKATE', 'SURF', 'CATCH', 'SCORE', 'GAME'] },
    { level: 11, words: ['TREE', 'ROOT', 'LEAF', 'SEED', 'ROSE', 'TULIP', 'GRASS', 'BLOOM', 'BRANCH', 'BUSH'] },
    { level: 12, words: ['LAKE', 'POND', 'RIVER', 'OCEAN', 'WAVE', 'TIDE', 'SHORE', 'BEACH', 'CORAL', 'SHELL'] },
    { level: 13, words: ['BABY', 'GIRL', 'BOY', 'TWIN', 'UNCLE', 'AUNT', 'NIECE', 'COUSIN', 'PARENT', 'FRIEND'] },
    { level: 14, words: ['SHOP', 'BANK', 'HOTEL', 'TOWER', 'MUSEUM', 'PARK', 'BRIDGE', 'CASTLE', 'HARBOR', 'STREET'] },
    { level: 15, words: ['ORBIT', 'COMET', 'SOLAR', 'LUNAR', 'PLANET', 'ROCKET', 'NEBULA', 'GALAXY', 'METEOR', 'COSMOS'] },
    { level: 16, words: ['PINE', 'FERN', 'MOSS', 'TRAIL', 'CEDAR', 'BIRCH', 'WOODS', 'GROVE', 'TIMBER', 'JUNGLE'] },
    { level: 17, words: ['DAWN', 'NOON', 'DUSK', 'NIGHT', 'MONTH', 'SPRING', 'SUMMER', 'AUTUMN', 'WINTER', 'DECADE'] },
    { level: 18, words: ['LINE', 'CONE', 'CUBE', 'OVAL', 'CIRCLE', 'SQUARE', 'SPHERE', 'PRISM', 'SPIRAL', 'VERTEX'] },
    { level: 19, words: ['GEAR', 'WIRE', 'BOLT', 'NAIL', 'LEVER', 'DRILL', 'MOTOR', 'ROBOT', 'SCREEN', 'SENSOR'] },
    { level: 20, words: ['HIKE', 'CAMP', 'TREK', 'FLOAT', 'SAIL', 'ROAM', 'VOYAGE', 'ISLAND', 'CANYON', 'SAFARI'] },
    { level: 21, words: ['RUBY', 'JADE', 'OPAL', 'PEARL', 'AMBER', 'QUARTZ', 'COPPER', 'SILVER', 'BRONZE', 'TOPAZ'] },
    { level: 22, words: ['HOPE', 'CALM', 'BRAVE', 'PEACE', 'SMILE', 'CHEER', 'DREAM', 'WONDER', 'JOYFUL', 'WISDOM'] },
    { level: 23, words: ['BARN', 'COW', 'PIG', 'GOAT', 'SHEEP', 'HORSE', 'GRAIN', 'WHEAT', 'CORN', 'PLOW'] },
    { level: 24, words: ['SEAL', 'CRAB', 'SQUID', 'SHARK', 'WHALE', 'OTTER', 'WALRUS', 'DOLPHIN', 'RAY', 'TURTLE'] },
    { level: 25, words: ['MYTH', 'FAIRY', 'ELFIN', 'SPELL', 'WAND', 'MAGIC', 'DRAGON', 'KNIGHT', 'SHIELD', 'THRONE'] },
    { level: 26, words: ['WING', 'GLIDE', 'PILOT', 'RADAR', 'HOVER', 'SOAR', 'FLIGHT', 'LAUNCH', 'PROPEL', 'SPEED'] },
    { level: 27, words: ['SAND', 'OASIS', 'DUNE', 'CAMEL', 'ARID', 'HEAT', 'MIRAGE', 'CACTUS', 'NOMAD', 'VALLEY'] },
    { level: 28, words: ['COLD', 'CHILL', 'SLEET', 'HAIL', 'GLACIER', 'ICEBERG', 'ARCTIC', 'TUNDRA', 'POLAR', 'BLIZZARD'] },
    { level: 29, words: ['CROWN', 'SCEPTER', 'REALM', 'PRINCE', 'BARON', 'DUCHESS', 'DYNASTY', 'EMPIRE', 'PALACE', 'REGAL'] },
    { level: 30, words: ['AURA', 'STELLAR', 'ZENITH', 'ETERNAL', 'RADIANT', 'INFINITY', 'ECLIPSE', 'HORIZON', 'CRYSTAL', 'DIVINE'] },
    { level: 31, words: ['EAGLE', 'HAWK', 'FALCON', 'SWAN', 'HERON', 'RAVEN', 'OWL', 'PARROT', 'DOVE', 'ROBIN'] },
    { level: 32, words: ['BEE', 'WASP', 'ANT', 'BEETLE', 'MOTH', 'CRICKET', 'SPIDER', 'MANTIS', 'CICADA', 'HORNET'] },
    { level: 33, words: ['OAK', 'MAPLE', 'WILLOW', 'BAMBOO', 'PALM', 'BONSAI', 'IVY', 'CLOVER', 'VINE', 'ORCHID'] },
    { level: 34, words: ['CHEF', 'RECIPE', 'ROAST', 'GRILL', 'TOAST', 'BAKE', 'BOIL', 'SAUCE', 'SALAD', 'SOUP'] },
    { level: 35, words: ['CHERRY', 'PAPAYA', 'GUAVA', 'FIG', 'DATE', 'OLIVE', 'CARROT', 'ONION', 'RADISH', 'GARLIC'] },
    { level: 36, words: ['TRAIN', 'TRUCK', 'BOAT', 'YACHT', 'TRAM', 'METRO', 'CANOE', 'KAYAK', 'FERRY', 'GLIDER'] },
    { level: 37, words: ['BREEZE', 'MIST', 'FOG', 'THUNDER', 'GALE', 'HUMID', 'CLIMATE', 'DEW', 'VAPOR', 'TYPHOON'] },
    { level: 38, words: ['NOVEL', 'POEM', 'DRAMA', 'STAGE', 'ACTOR', 'CANVAS', 'ESSAY', 'VERSE', 'PROSE', 'THEATER'] },
    { level: 39, words: ['ATOM', 'CELL', 'ENERGY', 'FORCE', 'MASS', 'ACID', 'OPTICS', 'LASER', 'PLASMA', 'MAGNET'] },
    { level: 40, words: ['REEF', 'TRENCH', 'SPONGE', 'KELP', 'ANEMONE', 'LOBSTER', 'CLAM', 'OYSTER', 'SHRIMP', 'URCHIN'] },
    { level: 41, words: ['HEART', 'LUNG', 'BRAIN', 'BONE', 'MUSCLE', 'SPINE', 'BLOOD', 'NERVE', 'JOINT', 'TISSUE'] },
    { level: 42, words: ['JAZZ', 'BLUES', 'OPERA', 'BALLET', 'WALTZ', 'TANGO', 'TEMPO', 'RHYTHM', 'VIOLIN', 'GUITAR'] },
    { level: 43, words: ['PULSAR', 'QUASAR', 'COSMIC', 'ASTEROID', 'GRAVITY', 'HUBBLE', 'TITAN', 'PROBE', 'AURORA', 'NEUTRINO'] },
    { level: 44, words: ['TIGER', 'LEOPARD', 'CHEETAH', 'JAGUAR', 'HYENA', 'PANDA', 'ZEBRA', 'GIRAFFE', 'MONKEY', 'RHINO'] },
    { level: 45, words: ['ARCH', 'PILLAR', 'DOME', 'VAULT', 'ARENA', 'TEMPLE', 'SHRINE', 'PLAZA', 'CABIN', 'VILLA'] },
    { level: 46, words: ['CLIFF', 'GORGE', 'CRATER', 'MEADOW', 'PLAINS', 'SWAMP', 'MARSH', 'PLATEAU', 'RIDGE', 'PEAK'] },
    { level: 47, words: ['WIZARD', 'ELF', 'GOBLIN', 'GIANT', 'HERO', 'QUEST', 'TALISMAN', 'MYTHIC', 'RELIC', 'SWORD'] },
    { level: 48, words: ['PLATINUM', 'TITANIUM', 'ZINC', 'NICKEL', 'COBALT', 'LEAD', 'IRON', 'STEEL', 'EMERALD', 'SAPPHIRE'] },
    { level: 49, words: ['NOBLE', 'HONEST', 'LOYAL', 'HUMBLE', 'KIND', 'PATIENT', 'FOCUS', 'GRACE', 'VALOR', 'COURAGE'] },
    { level: 50, words: ['VICTORY', 'TRIUMPH', 'SUMMIT', 'DESTINY', 'LEGEND', 'APEX', 'ELITE', 'PRIME', 'GRAND', 'HEROIC'] },
  ],

  // ── Master Mode: 50 Levels, 10 pairs each (500 unique pairs) ──
  master: [
    {
      level: 1,
      pairs: [
        { hindi: 'पानी', english: 'WATER' },
        { hindi: 'किताब', english: 'BOOK' },
        { hindi: 'घर', english: 'HOME' },
        { hindi: 'खुशी', english: 'HAPPY' },
        { hindi: 'मित्र', english: 'FRIEND' },
        { hindi: 'विद्यालय', english: 'SCHOOL' },
        { hindi: 'सूरज', english: 'SUN' },
        { hindi: 'वृक्ष', english: 'TREE' },
        { hindi: 'तारा', english: 'STAR' },
        { hindi: 'चाँद', english: 'MOON' },
      ]
    },
    {
      level: 2,
      pairs: [
        { hindi: 'आसमान', english: 'SKY' },
        { hindi: 'भोजन', english: 'FOOD' },
        { hindi: 'फूल', english: 'FLOWER' },
        { hindi: 'समय', english: 'TIME' },
        { hindi: 'दुनिया', english: 'WORLD' },
        { hindi: 'नदी', english: 'RIVER' },
        { hindi: 'पहाड़', english: 'HILL' },
        { hindi: 'वर्षा', english: 'RAIN' },
        { hindi: 'सागर', english: 'OCEAN' },
        { hindi: 'रास्ता', english: 'ROAD' },
      ]
    },
    {
      level: 3,
      pairs: [
        { hindi: 'दूरभाष', english: 'PHONE' },
        { hindi: 'संगणक', english: 'COMPUTER' },
        { hindi: 'संगीत', english: 'MUSIC' },
        { hindi: 'नृत्य', english: 'DANCE' },
        { hindi: 'हंसी', english: 'SMILE' },
        { hindi: 'सपना', english: 'DREAM' },
        { hindi: 'रात्रि', english: 'NIGHT' },
        { hindi: 'दिन', english: 'DAY' },
        { hindi: 'धरती', english: 'EARTH' },
        { hindi: 'अग्नि', english: 'FIRE' },
      ]
    },
    {
      level: 4,
      pairs: [
        { hindi: 'सेब', english: 'APPLE' },
        { hindi: 'केला', english: 'BANANA' },
        { hindi: 'अंगूर', english: 'GRAPE' },
        { hindi: 'आम', english: 'MANGO' },
        { hindi: 'संतरा', english: 'ORANGE' },
        { hindi: 'नींबू', english: 'LEMON' },
        { hindi: 'अनानास', english: 'PINEAPPLE' },
        { hindi: 'तरबूज', english: 'MELON' },
        { hindi: 'अंजीर', english: 'FIG' },
        { hindi: 'नाशपाती', english: 'PEAR' },
      ]
    },
    {
      level: 5,
      pairs: [
        { hindi: 'बिल्ली', english: 'CAT' },
        { hindi: 'कुत्ता', english: 'DOG' },
        { hindi: 'पक्षी', english: 'BIRD' },
        { hindi: 'मत्स्य', english: 'FISH' },
        { hindi: 'सिंह', english: 'LION' },
        { hindi: 'गज', english: 'ELEPHANT' },
        { hindi: 'अश्व', english: 'HORSE' },
        { hindi: 'शशक', english: 'RABBIT' },
        { hindi: 'व्याघ्र', english: 'TIGER' },
        { hindi: 'वानर', english: 'MONKEY' },
      ]
    },
    {
      level: 6,
      pairs: [
        { hindi: 'रक्त वर्ण', english: 'RED' },
        { hindi: 'नील वर्ण', english: 'BLUE' },
        { hindi: 'हरित वर्ण', english: 'GREEN' },
        { hindi: 'पीत वर्ण', english: 'YELLOW' },
        { hindi: 'श्वेत वर्ण', english: 'WHITE' },
        { hindi: 'श्याम वर्ण', english: 'BLACK' },
        { hindi: 'गुलाब वर्ण', english: 'PINK' },
        { hindi: 'धूम्र वर्ण', english: 'GRAY' },
        { hindi: 'काष्ठ वर्ण', english: 'BROWN' },
        { hindi: 'स्वर्ण वर्ण', english: 'GOLD' },
      ]
    },
    {
      level: 7,
      pairs: [
        { hindi: 'जननी', english: 'MOTHER' },
        { hindi: 'जनक', english: 'FATHER' },
        { hindi: 'भ्राता', english: 'BROTHER' },
        { hindi: 'भगिनी', english: 'SISTER' },
        { hindi: 'पुत्र', english: 'SON' },
        { hindi: 'पुत्री', english: 'DAUGHTER' },
        { hindi: 'पितामह', english: 'GRANDFATHER' },
        { hindi: 'पितामही', english: 'GRANDMOTHER' },
        { hindi: 'पितृव्य', english: 'UNCLE' },
        { hindi: 'मातुल', english: 'AUNT' },
      ]
    },
    {
      level: 8,
      pairs: [
        { hindi: 'सोमवार', english: 'MONDAY' },
        { hindi: 'मंगलवार', english: 'TUESDAY' },
        { hindi: 'बुधवार', english: 'WEDNESDAY' },
        { hindi: 'गुरुवार', english: 'THURSDAY' },
        { hindi: 'शुक्रवार', english: 'FRIDAY' },
        { hindi: 'शनिवार', english: 'SATURDAY' },
        { hindi: 'रविवार', english: 'SUNDAY' },
        { hindi: 'हफ्ता', english: 'WEEK' },
        { hindi: 'महीना', english: 'MONTH' },
        { hindi: 'साल', english: 'YEAR' },
      ]
    },
    {
      level: 9,
      pairs: [
        { hindi: 'ग्रीष्म', english: 'SUMMER' },
        { hindi: 'शीत', english: 'WINTER' },
        { hindi: 'वसंत', english: 'SPRING' },
        { hindi: 'शरद', english: 'AUTUMN' },
        { hindi: 'हिम', english: 'SNOW' },
        { hindi: 'मेघ', english: 'CLOUD' },
        { hindi: 'चक्रवात', english: 'STORM' },
        { hindi: 'इंद्रधनुष', english: 'RAINBOW' },
        { hindi: 'वायु', english: 'AIR' },
        { hindi: 'प्रकाश', english: 'LIGHT' },
      ]
    },
    {
      level: 10,
      pairs: [
        { hindi: 'वैद्य', english: 'DOCTOR' },
        { hindi: 'अध्यापक', english: 'TEACHER' },
        { hindi: 'कृषक', english: 'FARMER' },
        { hindi: 'जवान', english: 'SOLDIER' },
        { hindi: 'चालक', english: 'DRIVER' },
        { hindi: 'परिचारिका', english: 'NURSE' },
        { hindi: 'पाचक', english: 'CHEF' },
        { hindi: 'शिल्पी', english: 'ARTIST' },
        { hindi: 'अधिवक्ता', english: 'LAWYER' },
        { hindi: 'रक्षक', english: 'GUARD' },
      ]
    },
    {
      level: 11,
      pairs: [
        { hindi: 'आसन', english: 'CHAIR' },
        { hindi: 'मेज', english: 'TABLE' },
        { hindi: 'शय्या', english: 'BED' },
        { hindi: 'कपाट', english: 'DOOR' },
        { hindi: 'वातायन', english: 'WINDOW' },
        { hindi: 'भित्ति', english: 'WALL' },
        { hindi: 'छत', english: 'ROOF' },
        { hindi: 'फर्श', english: 'FLOOR' },
        { hindi: 'दीप', english: 'LAMP' },
        { hindi: 'घड़ा', english: 'POT' },
      ]
    },
    {
      level: 12,
      pairs: [
        { hindi: 'गीत', english: 'SONG' },
        { hindi: 'चित्रकला', english: 'PAINT' },
        { hindi: 'पद्य', english: 'POEM' },
        { hindi: 'कथा', english: 'STORY' },
        { hindi: 'ढोल', english: 'DRUM' },
        { hindi: 'मुरली', english: 'FLUTE' },
        { hindi: 'घंट', english: 'BELL' },
        { hindi: 'ध्वनि', english: 'SOUND' },
        { hindi: 'सुर', english: 'VOICE' },
        { hindi: 'ताल', english: 'RHYTHM' },
      ]
    },
    {
      level: 13,
      pairs: [
        { hindi: 'रेलगाड़ी', english: 'TRAIN' },
        { hindi: 'मोटर', english: 'BUS' },
        { hindi: 'गाड़ी', english: 'CAR' },
        { hindi: 'द्विचक्र', english: 'CYCLE' },
        { hindi: 'विमान', english: 'PLANE' },
        { hindi: 'नौका', english: 'BOAT' },
        { hindi: 'पोत', english: 'SHIP' },
        { hindi: 'तिपहिया', english: 'RICKSHAW' },
        { hindi: 'हेलिकॉप्टर', english: 'CHOPPER' },
        { hindi: 'ट्रक', english: 'LORRY' },
      ]
    },
    {
      level: 14,
      pairs: [
        { hindi: 'अंकगणित', english: 'MATH' },
        { hindi: 'भौतिकी', english: 'SCIENCE' },
        { hindi: 'पुरातत्व', english: 'HISTORY' },
        { hindi: 'भूगोल', english: 'LAND' },
        { hindi: 'आंग्ल', english: 'ENGLISH' },
        { hindi: 'संस्कृत', english: 'HINDI' },
        { hindi: 'क्रीड़ा', english: 'SPORT' },
        { hindi: 'वाचन', english: 'READ' },
        { hindi: 'लेख', english: 'WRITE' },
        { hindi: 'परीक्षा', english: 'EXAM' },
      ]
    },
    {
      level: 15,
      pairs: [
        { hindi: 'मस्तक', english: 'HEAD' },
        { hindi: 'कर', english: 'HAND' },
        { hindi: 'पाद', english: 'FOOT' },
        { hindi: 'नेत्र', english: 'EYE' },
        { hindi: 'कर्ण', english: 'EAR' },
        { hindi: 'नासिका', english: 'NOSE' },
        { hindi: 'मुख', english: 'MOUTH' },
        { hindi: 'हृदय', english: 'HEART' },
        { hindi: 'दंत', english: 'TOOTH' },
        { hindi: 'रसना', english: 'TONGUE' },
      ]
    },
    {
      level: 16,
      pairs: [
        { hindi: 'ओदन', english: 'RICE' },
        { hindi: 'चपाती', english: 'BREAD' },
        { hindi: 'दुग्ध', english: 'MILK' },
        { hindi: 'पेय', english: 'TEA' },
        { hindi: 'दधि', english: 'CHEESE' },
        { hindi: 'नवनीत', english: 'BUTTER' },
        { hindi: 'शर्करा', english: 'SUGAR' },
        { hindi: 'लवण', english: 'SALT' },
        { hindi: 'मिष्टान्न', english: 'SWEET' },
        { hindi: 'जलपान', english: 'SNACK' },
      ]
    },
    {
      level: 17,
      pairs: [
        { hindi: 'नृप', english: 'KING' },
        { hindi: 'महिषी', english: 'QUEEN' },
        { hindi: 'राजपुत्र', english: 'PRINCE' },
        { hindi: 'राजभवन', english: 'PALACE' },
        { hindi: 'दुर्ग', english: 'FORT' },
        { hindi: 'कृपाण', english: 'SWORD' },
        { hindi: 'किरीट', english: 'CROWN' },
        { hindi: 'राजगद्दी', english: 'THRONE' },
        { hindi: 'साम्राज्य', english: 'EMPIRE' },
        { hindi: 'सेनापति', english: 'GENERAL' },
      ]
    },
    {
      level: 18,
      pairs: [
        { hindi: 'दूरदर्शन', english: 'SCREEN' },
        { hindi: 'छायाचित्र', english: 'CAMERA' },
        { hindi: 'घटी', english: 'CLOCK' },
        { hindi: 'विद्युत दीप', english: 'BULB' },
        { hindi: 'व्यजन', english: 'FAN' },
        { hindi: 'आकाशवाणी', english: 'RADIO' },
        { hindi: 'तार', english: 'CABLE' },
        { hindi: 'कुंजी', english: 'KEY' },
        { hindi: 'तालक', english: 'LOCK' },
        { hindi: 'दर्पण', english: 'MIRROR' },
      ]
    },
    {
      level: 19,
      pairs: [
        { hindi: 'अहिंसा', english: 'PEACE' },
        { hindi: 'प्रेम', english: 'LOVE' },
        { hindi: 'उम्मीद', english: 'HOPE' },
        { hindi: 'यकीन', english: 'FAITH' },
        { hindi: 'हिम्मत', english: 'BRAVE' },
        { hindi: 'प्रज्ञा', english: 'WISDOM' },
        { hindi: 'सच्चाई', english: 'TRUTH' },
        { hindi: 'करुणा', english: 'MERCY' },
        { hindi: 'शालीनता', english: 'GRACE' },
        { hindi: 'सम्मान', english: 'HONOR' },
      ]
    },
    {
      level: 20,
      pairs: [
        { hindi: 'जलधि', english: 'SEA' },
        { hindi: 'शैल', english: 'MOUNTAIN' },
        { hindi: 'अरण्य', english: 'FOREST' },
        { hindi: 'मरुस्थल', english: 'DESERT' },
        { hindi: 'सरोवर', english: 'LAKE' },
        { hindi: 'कंदरा', english: 'CAVE' },
        { hindi: 'टापू', english: 'ISLAND' },
        { hindi: 'प्रांतर', english: 'FIELD' },
        { hindi: 'द्रोणी', english: 'VALLEY' },
        { hindi: 'तट', english: 'COAST' },
      ]
    },
    {
      level: 21,
      pairs: [
        { hindi: 'रत्न', english: 'JEWEL' },
        { hindi: 'माणिक्य', english: 'RUBY' },
        { hindi: 'मरकत', english: 'EMERALD' },
        { hindi: 'वज्र', english: 'DIAMOND' },
        { hindi: 'मुक्ता', english: 'PEARL' },
        { hindi: 'कंचन', english: 'GOLDEN' },
        { hindi: 'रजत', english: 'SILVER' },
        { hindi: 'ताम्र', english: 'COPPER' },
        { hindi: 'अयस', english: 'IRON' },
        { hindi: 'मणिक', english: 'CRYSTAL' },
      ]
    },
    {
      level: 22,
      pairs: [
        { hindi: 'अंडज', english: 'EGG' },
        { hindi: 'शावक', english: 'CUB' },
        { hindi: 'मृग', english: 'DEER' },
        { hindi: 'वृक', english: 'WOLF' },
        { hindi: 'ऋक्ष', english: 'BEAR' },
        { hindi: 'लोमड़ी', english: 'FOX' },
        { hindi: 'उष्ट्र', english: 'CAMEL' },
        { hindi: 'धूसर', english: 'DONKEY' },
        { hindi: 'वृषभ', english: 'BULL' },
        { hindi: 'गो', english: 'COW' },
      ]
    },
    {
      level: 23,
      pairs: [
        { hindi: 'कंदुक', english: 'BALL' },
        { hindi: 'लक्ष्य', english: 'GOAL' },
        { hindi: 'तरण', english: 'SWIM' },
        { hindi: 'कूद', english: 'JUMP' },
        { hindi: 'प्रतिस्पर्धा', english: 'RACE' },
        { hindi: 'विजेता', english: 'WINNER' },
        { hindi: 'उपहार', english: 'PRIZE' },
        { hindi: 'दौड़', english: 'SPRINT' },
        { hindi: 'खिलाड़ी', english: 'PLAYER' },
        { hindi: 'अंक', english: 'SCORE' },
      ]
    },
    {
      level: 24,
      pairs: [
        { hindi: 'वस्त्र', english: 'CLOTHES' },
        { hindi: 'शिरस्त्राण', english: 'HAT' },
        { hindi: 'पादत्राण', english: 'SHOE' },
        { hindi: 'उत्तरीय', english: 'COAT' },
        { hindi: 'कटिबंध', english: 'BELT' },
        { hindi: 'अंगवस्त्र', english: 'SHIRT' },
        { hindi: 'गुलूबंद', english: 'SCARF' },
        { hindi: 'अंगूठी', english: 'RING' },
        { hindi: 'हार', english: 'CHAIN' },
        { hindi: 'कंगन', english: 'BANGLE' },
      ]
    },
    {
      level: 25,
      pairs: [
        { hindi: 'पात्र', english: 'CUP' },
        { hindi: 'कांटा', english: 'FORK' },
        { hindi: 'चमच', english: 'SPOON' },
        { hindi: 'छुरी', english: 'KNIFE' },
        { hindi: 'थाल', english: 'PLATE' },
        { hindi: 'कटोरी', english: 'BOWL' },
        { hindi: 'कड़ाही', english: 'PAN' },
        { hindi: 'चूल्हा', english: 'STOVE' },
        { hindi: 'पेटी', english: 'BOX' },
        { hindi: 'थैला', english: 'BAG' },
      ]
    },
    {
      level: 26,
      pairs: [
        { hindi: 'उपवन', english: 'GARDEN' },
        { hindi: 'मूल', english: 'ROOT' },
        { hindi: 'पर्ण', english: 'LEAF' },
        { hindi: 'बीज', english: 'SEED' },
        { hindi: 'गुलाब', english: 'ROSE' },
        { hindi: 'कुमुद', english: 'LILY' },
        { hindi: 'तृण', english: 'GRASS' },
        { hindi: 'प्रस्फुटन', english: 'BLOOM' },
        { hindi: 'विटप', english: 'BRANCH' },
        { hindi: 'गुल्म', english: 'BUSH' },
      ]
    },
    {
      level: 27,
      pairs: [
        { hindi: 'शिशु', english: 'BABY' },
        { hindi: 'बालिका', english: 'GIRL' },
        { hindi: 'बालक', english: 'BOY' },
        { hindi: 'यमल', english: 'TWIN' },
        { hindi: 'मातृव्य', english: 'COUSIN' },
        { hindi: 'अभिभावक', english: 'PARENT' },
        { hindi: 'सखा', english: 'BUDDY' },
        { hindi: 'नागरिक', english: 'CITIZEN' },
        { hindi: 'मानव', english: 'HUMAN' },
        { hindi: 'जन', english: 'PEOPLE' },
      ]
    },
    {
      level: 28,
      pairs: [
        { hindi: 'हाट', english: 'MARKET' },
        { hindi: 'कोष', english: 'BANK' },
        { hindi: 'विश्रामगृह', english: 'HOTEL' },
        { hindi: 'मीनार', english: 'TOWER' },
        { hindi: 'संग्रहालय', english: 'MUSEUM' },
        { hindi: 'विहार', english: 'PARK' },
        { hindi: 'सेतु', english: 'BRIDGE' },
        { hindi: 'पतन', english: 'HARBOR' },
        { hindi: 'वीथी', english: 'STREET' },
        { hindi: 'नगर', english: 'CITY' },
      ]
    },
    {
      level: 29,
      pairs: [
        { hindi: 'परिक्रमा', english: 'ORBIT' },
        { hindi: 'पुच्छल तारा', english: 'COMET' },
        { hindi: 'सौर', english: 'SOLAR' },
        { hindi: 'चांद्र', english: 'LUNAR' },
        { hindi: 'पिंड', english: 'PLANET' },
        { hindi: 'बाण', english: 'ROCKET' },
        { hindi: 'नीहारिका', english: 'NEBULA' },
        { hindi: 'तारासमूह', english: 'GALAXY' },
        { hindi: 'अशनि', english: 'METEOR' },
        { hindi: 'अंतरिक्ष', english: 'SPACE' },
      ]
    },
    {
      level: 30,
      pairs: [
        { hindi: 'देवदार', english: 'CEDAR' },
        { hindi: 'भूर्ज', english: 'BIRCH' },
        { hindi: 'काष्ठ', english: 'TIMBER' },
        { hindi: 'विपिन', english: 'WOODS' },
        { hindi: 'गहन वन', english: 'JUNGLE' },
        { hindi: 'पगडंडी', english: 'TRAIL' },
        { hindi: 'शैलमाला', english: 'RANGE' },
        { hindi: 'हिमखंड', english: 'ICEBERG' },
        { hindi: 'प्रपात', english: 'FALLS' },
        { hindi: 'शिखर', english: 'PEAK' },
      ]
    },
    {
      level: 31,
      pairs: [
        { hindi: 'हंस', english: 'SWAN' },
        { hindi: 'चील', english: 'EAGLE' },
        { hindi: 'उल्लू', english: 'OWL' },
        { hindi: 'तोता', english: 'PARROT' },
        { hindi: 'मधुमक्खी', english: 'BEE' },
        { hindi: 'चींटी', english: 'ANT' },
        { hindi: 'पतंग', english: 'MOTH' },
        { hindi: 'मकड़ी', english: 'SPIDER' },
        { hindi: 'बत्तख', english: 'DUCK' },
        { hindi: 'कौवा', english: 'CROW' },
      ]
    },
    {
      level: 32,
      pairs: [
        { hindi: 'वटवृक्ष', english: 'BANYAN' },
        { hindi: 'ताड़', english: 'PALM' },
        { hindi: 'बांस', english: 'BAMBOO' },
        { hindi: 'बांज', english: 'OAK' },
        { hindi: 'कचनार', english: 'ORCHID' },
        { hindi: 'लता', english: 'VINE' },
        { hindi: 'चिनार', english: 'MAPLE' },
        { hindi: 'कमल', english: 'LOTUS' },
        { hindi: 'तुलसी', english: 'BASIL' },
        { hindi: 'चमेली', english: 'JASMINE' },
      ]
    },
    {
      level: 33,
      pairs: [
        { hindi: 'व्हेल', english: 'WHALE' },
        { hindi: 'शार्क', english: 'SHARK' },
        { hindi: 'केकड़ा', english: 'CRAB' },
        { hindi: 'कछुआ', english: 'TURTLE' },
        { hindi: 'झींगा', english: 'SHRIMP' },
        { hindi: 'डॉल्फ़िन', english: 'DOLPHIN' },
        { hindi: 'सीप', english: 'OYSTER' },
        { hindi: 'मूंगा', english: 'CORAL' },
        { hindi: 'प्रवाल', english: 'REEF' },
        { hindi: 'शैवाल', english: 'KELP' },
      ]
    },
    {
      level: 34,
      pairs: [
        { hindi: 'गाजर', english: 'CARROT' },
        { hindi: 'प्याज', english: 'ONION' },
        { hindi: 'लहसुन', english: 'GARLIC' },
        { hindi: 'अदरक', english: 'GINGER' },
        { hindi: 'हल्दी', english: 'TURMERIC' },
        { hindi: 'मिर्च', english: 'CHILI' },
        { hindi: 'लौंग', english: 'CLOVE' },
        { hindi: 'जीरा', english: 'CUMIN' },
        { hindi: 'पुदीना', english: 'MINT' },
        { hindi: 'पालक', english: 'SPINACH' },
      ]
    },
    {
      level: 35,
      pairs: [
        { hindi: 'रसोइया', english: 'COOK' },
        { hindi: 'तंदूर', english: 'OVEN' },
        { hindi: 'प्याला', english: 'MUG' },
        { hindi: 'चिमटा', english: 'TONGS' },
        { hindi: 'बेलन', english: 'ROLLER' },
        { hindi: 'ढक्कन', english: 'LID' },
        { hindi: 'मथानी', english: 'WHISK' },
        { hindi: 'छलनी', english: 'SIEVE' },
        { hindi: 'भट्टी', english: 'KILN' },
        { hindi: 'व्यंजन', english: 'RECIPE' },
      ]
    },
    {
      level: 36,
      pairs: [
        { hindi: 'मेट्रो', english: 'METRO' },
        { hindi: 'ग्लाइडर', english: 'GLIDER' },
        { hindi: 'नौकायन', english: 'YACHT' },
        { hindi: 'बजरा', english: 'BARGE' },
        { hindi: 'डोंगी', english: 'CANOE' },
        { hindi: 'कयाक', english: 'KAYAK' },
        { hindi: 'फेरी', english: 'FERRY' },
        { hindi: 'ट्राम', english: 'TRAM' },
        { hindi: 'स्कूटर', english: 'SCOOTER' },
        { hindi: 'पनडुब्बी', english: 'SUB' },
      ]
    },
    {
      level: 37,
      pairs: [
        { hindi: 'समीर', english: 'BREEZE' },
        { hindi: 'कोहरा', english: 'FOG' },
        { hindi: 'धुंध', english: 'MIST' },
        { hindi: 'ओस', english: 'DEW' },
        { hindi: 'गर्जन', english: 'THUNDER' },
        { hindi: 'आंधी', english: 'GALE' },
        { hindi: 'वाष्प', english: 'VAPOR' },
        { hindi: 'बवंडर', english: 'TORNADO' },
        { hindi: 'ओला', english: 'HAIL' },
        { hindi: 'पाला', english: 'FROST' },
      ]
    },
    {
      level: 38,
      pairs: [
        { hindi: 'हथौड़ा', english: 'HAMMER' },
        { hindi: 'आरी', english: 'SAW' },
        { hindi: 'कैंची', english: 'SHEARS' },
        { hindi: 'पेंचकस', english: 'SCREW' },
        { hindi: 'कुल्हाड़ी', english: 'AXE' },
        { hindi: 'तराजू', english: 'SCALE' },
        { hindi: 'सुई', english: 'NEEDLE' },
        { hindi: 'धागा', english: 'THREAD' },
        { hindi: 'कील', english: 'NAIL' },
        { hindi: 'संड़ासी', english: 'PLIERS' },
      ]
    },
    {
      level: 39,
      pairs: [
        { hindi: 'यकृत', english: 'LIVER' },
        { hindi: 'फेफड़ा', english: 'LUNG' },
        { hindi: 'मस्तिष्क', english: 'BRAIN' },
        { hindi: 'अस्थि', english: 'BONE' },
        { hindi: 'पेशी', english: 'MUSCLE' },
        { hindi: 'मेरुदंड', english: 'SPINE' },
        { hindi: 'रुधिर', english: 'BLOOD' },
        { hindi: 'धमनी', english: 'ARTERY' },
        { hindi: 'शिरा', english: 'VEIN' },
        { hindi: 'त्वचा', english: 'SKIN' },
      ]
    },
    {
      level: 40,
      pairs: [
        { hindi: 'कुर्ता', english: 'TUNIC' },
        { hindi: 'पगड़ी', english: 'TURBAN' },
        { hindi: 'शॉल', english: 'SHAWL' },
        { hindi: 'मोजा', english: 'SOCK' },
        { hindi: 'दस्ताना', english: 'GLOVE' },
        { hindi: 'पाजामा', english: 'PANTS' },
        { hindi: 'केंचुल', english: 'VEST' },
        { hindi: 'घाघरा', english: 'SKIRT' },
        { hindi: 'जामा', english: 'ROBE' },
        { hindi: 'चादर', english: 'SHEET' },
      ]
    },
    {
      level: 41,
      pairs: [
        { hindi: 'परमाणु', english: 'ATOM' },
        { hindi: 'कोशिका', english: 'CELL' },
        { hindi: 'ऊर्जा', english: 'ENERGY' },
        { hindi: 'बल', english: 'FORCE' },
        { hindi: 'द्रव्यमान', english: 'MASS' },
        { hindi: 'अम्ल', english: 'ACID' },
        { hindi: 'चुंबक', english: 'MAGNET' },
        { hindi: 'प्रकाशिकी', english: 'OPTICS' },
        { hindi: 'किरणपुंज', english: 'LASER' },
        { hindi: 'कण', english: 'PARTICLE' },
      ]
    },
    {
      level: 42,
      pairs: [
        { hindi: 'वायलिन', english: 'VIOLIN' },
        { hindi: 'गिटार', english: 'GUITAR' },
        { hindi: 'पियानो', english: 'PIANO' },
        { hindi: 'लय', english: 'TEMPO' },
        { hindi: 'स्वरसंगति', english: 'CHORD' },
        { hindi: 'गायन', english: 'VOCAL' },
        { hindi: 'मधुरिमा', english: 'MELODY' },
        { hindi: 'नृत्यनाट्य', english: 'BALLET' },
        { hindi: 'गीतिनाट्य', english: 'OPERA' },
        { hindi: 'जैज', english: 'JAZZ' },
      ]
    },
    {
      level: 43,
      pairs: [
        { hindi: 'क्षुद्रग्रह', english: 'ASTEROID' },
        { hindi: 'क्रेटर', english: 'CRATER' },
        { hindi: 'गुरुत्वाकर्षण', english: 'GRAVITY' },
        { hindi: 'पल्सर', english: 'PULSAR' },
        { hindi: 'क्वासर', english: 'QUASAR' },
        { hindi: 'टाइटन', english: 'TITAN' },
        { hindi: 'रोवर', english: 'ROVER' },
        { hindi: 'अन्वेषक', english: 'PROBE' },
        { hindi: 'ज्वाला', english: 'FLARE' },
        { hindi: 'ब्रह्मांडीय', english: 'COSMIC' },
      ]
    },
    {
      level: 44,
      pairs: [
        { hindi: 'तेंदुआ', english: 'LEOPARD' },
        { hindi: 'चीता', english: 'CHEETAH' },
        { hindi: 'जगुआर', english: 'JAGUAR' },
        { hindi: 'लकड़बग्घा', english: 'HYENA' },
        { hindi: 'पांडा', english: 'PANDA' },
        { hindi: 'ज़ेबरा', english: 'ZEBRA' },
        { hindi: 'जिराफ़', english: 'GIRAFFE' },
        { hindi: 'गैंडा', english: 'RHINO' },
        { hindi: 'ऊदबिलाव', english: 'OTTER' },
        { hindi: 'वालरस', english: 'WALRUS' },
      ]
    },
    {
      level: 45,
      pairs: [
        { hindi: 'मेहराब', english: 'ARCH' },
        { hindi: 'स्तंभ', english: 'PILLAR' },
        { hindi: 'गुंबद', english: 'DOME' },
        { hindi: 'तिजोरी', english: 'VAULT' },
        { hindi: 'अखाड़ा', english: 'ARENA' },
        { hindi: 'मंदिर', english: 'TEMPLE' },
        { hindi: 'दरगाह', english: 'SHRINE' },
        { hindi: 'चौक', english: 'PLAZA' },
        { hindi: 'कुटिया', english: 'CABIN' },
        { hindi: 'कोठी', english: 'VILLA' },
      ]
    },
    {
      level: 46,
      pairs: [
        { hindi: 'चट्टान', english: 'CLIFF' },
        { hindi: 'खड्ड', english: 'GORGE' },
        { hindi: 'चारागाह', english: 'MEADOW' },
        { hindi: 'मैदानी भाग', english: 'PLAINS' },
        { hindi: 'कच्छ', english: 'SWAMP' },
        { hindi: 'दलदल', english: 'MARSH' },
        { hindi: 'पठार', english: 'PLATEAU' },
        { hindi: 'कटक', english: 'RIDGE' },
        { hindi: 'महाखड्ड', english: 'CANYON' },
        { hindi: 'झरना', english: 'WATERFALL' },
      ]
    },
    {
      level: 47,
      pairs: [
        { hindi: 'जादूगर', english: 'WIZARD' },
        { hindi: 'बौना', english: 'GNOME' },
        { hindi: 'दैत्य', english: 'GIANT' },
        { hindi: 'दानव', english: 'GOBLIN' },
        { hindi: 'योद्धा नायक', english: 'HERO' },
        { hindi: 'खोज यात्रा', english: 'QUEST' },
        { hindi: 'ताबीज', english: 'TALISMAN' },
        { hindi: 'पौराणिक', english: 'MYTHIC' },
        { hindi: 'अवशेष', english: 'RELIC' },
        { hindi: 'मंत्र', english: 'SPELL' },
      ]
    },
    {
      level: 48,
      pairs: [
        { hindi: 'प्लैटिनम', english: 'PLATINUM' },
        { hindi: 'टाइटेनियम', english: 'TITANIUM' },
        { hindi: 'जस्ता', english: 'ZINC' },
        { hindi: 'निकेल', english: 'NICKEL' },
        { hindi: 'कोबाल्ट', english: 'COBALT' },
        { hindi: 'सीसा', english: 'LEAD' },
        { hindi: 'इस्पात', english: 'STEEL' },
        { hindi: 'नीलम', english: 'SAPPHIRE' },
        { hindi: 'पुखराज', english: 'TOPAZ' },
        { hindi: 'गोमेद', english: 'OPAL' },
      ]
    },
    {
      level: 49,
      pairs: [
        { hindi: 'कुलीन', english: 'NOBLE' },
        { hindi: 'ईमानदार', english: 'HONEST' },
        { hindi: 'निष्ठावान', english: 'LOYAL' },
        { hindi: 'विनम्र', english: 'HUMBLE' },
        { hindi: 'दयालु', english: 'KIND' },
        { hindi: 'धैर्यवान', english: 'PATIENT' },
        { hindi: 'एकाग्रता', english: 'FOCUS' },
        { hindi: 'शूरता', english: 'VALOR' },
        { hindi: 'साहसिकता', english: 'COURAGE' },
        { hindi: 'सदाचार', english: 'VIRTUE' },
      ]
    },
    {
      level: 50,
      pairs: [
        { hindi: 'विजय', english: 'VICTORY' },
        { hindi: 'जयघोष', english: 'TRIUMPH' },
        { hindi: 'शीर्ष', english: 'SUMMIT' },
        { hindi: 'नियति', english: 'DESTINY' },
        { hindi: 'आख्यान', english: 'LEGEND' },
        { hindi: 'सर्वोच्च', english: 'APEX' },
        { hindi: 'विशिष्ट', english: 'ELITE' },
        { hindi: 'प्रधान', english: 'PRIME' },
        { hindi: 'भव्य', english: 'GRAND' },
        { hindi: 'वीरतापूर्ण', english: 'HEROIC' },
      ]
    },
  ],

  // ── Hindi Mode: 50 Levels, 10 words each (500 unique words) ──
  hindi: [
    { level: 1,  words: ['पानी', 'किताब', 'घर', 'सूरज', 'पेड़', 'फूल', 'नदी', 'बादल', 'रात', 'हवा'] },
    { level: 2,  words: ['बिल्ली', 'कुत्ता', 'मछली', 'चिड़िया', 'शेर', 'हाथी', 'घोड़ा', 'मोर', 'बंदर', 'भालू'] },
    { level: 3,  words: ['सेब', 'केला', 'आम', 'अंगूर', 'संतरा', 'नींबू', 'अनार', 'पपीता', 'चावल', 'गेहूं'] },
    { level: 4,  words: ['लाल', 'नीला', 'हरा', 'पीला', 'सफेद', 'काला', 'गुलाबी', 'नारंगी', 'बैंगनी', 'भूरा'] },
    { level: 5,  words: ['माता', 'पिता', 'भाई', 'बहन', 'दादा', 'दादी', 'चाचा', 'चाची', 'बेटा', 'बेटी'] },
    { level: 6,  words: ['कुर्सी', 'मेज', 'दरवाजा', 'खिड़की', 'दीवार', 'छत', 'बिस्तर', 'अलमारी', 'घंटी', 'दर्पण'] },
    { level: 7,  words: ['ट्रेन', 'बस', 'कार', 'नाव', 'साइकिल', 'रिक्शा', 'जहाज', 'स्कूटर', 'ट्रक', 'विमान'] },
    { level: 8,  words: ['गणित', 'विज्ञान', 'हिन्दी', 'कला', 'खेल', 'संगीत', 'नृत्य', 'चित्र', 'काव्य', 'लेखन'] },
    { level: 9,  words: ['रोटी', 'दूध', 'चाय', 'पनीर', 'मक्खन', 'चीनी', 'नमक', 'दाल', 'खीर', 'शहद'] },
    { level: 10, words: ['राजा', 'रानी', 'महल', 'किला', 'तलवार', 'ताज', 'सेना', 'योद्धा', 'सिंहासन', 'मुकुट'] },
    { level: 11, words: ['सपना', 'दिन', 'तारा', 'चाँद', 'धरती', 'आग', 'झरना', 'सवेरा', 'संध्या', 'गगन'] },
    { level: 12, words: ['डॉक्टर', 'शिक्षक', 'किसान', 'सैनिक', 'नर्स', 'कलाकार', 'वकील', 'पुलिस', 'दर्जी', 'कुम्हार'] },
    { level: 13, words: ['गाना', 'कविता', 'कहानी', 'ड्रम', 'बांसुरी', 'सितार', 'तबला', 'वीणा', 'राग', 'तान'] },
    { level: 14, words: ['सिर', 'हाथ', 'पैर', 'आँख', 'कान', 'नाक', 'मुँह', 'दिल', 'बाल', 'कमर'] },
    { level: 15, words: ['गर्मी', 'सर्दी', 'बसंत', 'बारिश', 'बर्फ', 'तूफान', 'धूप', 'ओस', 'कोहरा', 'पतझड़'] },
    { level: 16, words: ['शांति', 'प्यार', 'आशा', 'साहस', 'सत्य', 'दया', 'धर्म', 'कर्म', 'आनंद', 'उमंग'] },
    { level: 17, words: ['कंप्यूटर', 'फोन', 'कैमरा', 'घड़ी', 'बल्ब', 'पंखा', 'रेडियो', 'टीवी', 'तार', 'बटन'] },
    { level: 18, words: ['समुद्र', 'पर्वत', 'जंगल', 'रेगिस्तान', 'झील', 'गुफा', 'द्वीप', 'मैदान', 'घाटी', 'पठार'] },
    { level: 19, words: ['क्रिकेट', 'फुटबॉल', 'हॉकी', 'टेनिस', 'बैडमिंटन', 'तैराकी', 'कुश्ती', 'दौड़', 'निशाना', 'तीरंदाजी'] },
    { level: 20, words: ['ब्रह्मांड', 'आकाशगंगा', 'ग्रह', 'उपग्रह', 'तारामंडल', 'धूमकेतु', 'उल्का', 'नक्षत्र', 'छाया', 'रोशनी'] },
    { level: 21, words: ['आलू', 'टमाटर', 'प्याज', 'मटर', 'गाजर', 'मूली', 'पालक', 'खीरा', 'बैंगन', 'अदरक'] },
    { level: 22, words: ['कछुआ', 'मेंढक', 'मगरमच्छ', 'केकड़ा', 'बगुला', 'हंस', 'घोंघा', 'शंख', 'मूंगा', 'व्हेल'] },
    { level: 23, words: ['कमल', 'गुलाब', 'गेंदा', 'चमेली', 'सूरजमुखी', 'पारिजात', 'चंपा', 'मोगरा', 'केवड़ा', 'पराग'] },
    { level: 24, words: ['सोना', 'चांदी', 'तांबा', 'लोहा', 'हीरा', 'मोती', 'पन्ना', 'माणिक', 'पीतल', 'कांस्य'] },
    { level: 25, words: ['सोमवार', 'मंगलवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार', 'सप्ताह', 'माह', 'वर्ष'] },
    { level: 26, words: ['हर्ष', 'क्रोध', 'उत्साह', 'धैर्य', 'विश्वास', 'स्नेह', 'भक्ति', 'स्मृति', 'ध्यान', 'चेतना'] },
    { level: 27, words: ['नीम', 'पीपल', 'बरगद', 'तुलसी', 'शीशम', 'देवदार', 'अशोक', 'चंदन', 'लता', 'शाखा'] },
    { level: 28, words: ['सफर', 'मार्ग', 'मंजिल', 'राही', 'दिशा', 'नाविक', 'पड़ाव', 'शिखर', 'सड़क', 'मोड़'] },
    { level: 29, words: ['विजय', 'वीर', 'शौर्य', 'पराक्रम', 'गरिमा', 'सम्मान', 'कीर्ति', 'यश', 'तेज', 'बल'] },
    { level: 30, words: ['अमृत', 'ज्ञान', 'विद्या', 'सुख', 'सौभाग्य', 'उजाला', 'संसार', 'सृष्टि', 'जीवन', 'मंगल'] },
    { level: 31, words: ['तोता', 'कोयल', 'चील', 'बाज', 'उल्लू', 'कौवा', 'कबूतर', 'मैना', 'बत्तख', 'तीतर'] },
    { level: 32, words: ['तितली', 'चींटी', 'भौंरा', 'मकड़ी', 'टिड्डा', 'जुगनू', 'मच्छर', 'पतंगा', 'दीमक', 'मधुमक्खी'] },
    { level: 33, words: ['हल्दी', 'मिर्च', 'जीरा', 'धनिया', 'लौंग', 'इलायची', 'सौंफ', 'मेथी', 'हींग', 'तेजपत्ता'] },
    { level: 34, words: ['लड्डू', 'पेड़ा', 'जलेबी', 'बर्फी', 'रसगुल्ला', 'हलवा', 'समोसा', 'कचौड़ी', 'पापड़', 'पूरी'] },
    { level: 35, words: ['साड़ी', 'कुर्ता', 'धोती', 'पगड़ी', 'शॉल', 'पाजेब', 'कंगन', 'झुमका', 'अंगूठी', 'माला'] },
    { level: 36, words: ['पुदीना', 'गिलोय', 'ब्राह्मी', 'आंवला', 'हरड़', 'बहेड़ा', 'जामुन', 'बेल', 'गुड़हल', 'अजवाइन'] },
    { level: 37, words: ['दर्रा', 'खाड़ी', 'टापू', 'वन', 'चोटी', 'हिमनद', 'चरागाह', 'दलदल', 'तट', 'प्रपात'] },
    { level: 38, words: ['ममता', 'करुणा', 'क्षमा', 'विनय', 'सरलता', 'निष्ठा', 'समर्पण', 'विवेक', 'संतोष', 'सद्भाव'] },
    { level: 39, words: ['समीर', 'बयार', 'ओला', 'घटा', 'फुहार', 'पावस', 'शरद', 'शिशिर', 'हेमंत', 'पवन'] },
    { level: 40, words: ['हथौड़ा', 'पेंचकस', 'कुल्हाड़ी', 'आरी', 'कैंची', 'तराजू', 'सुई', 'धागा', 'कील', 'रंदा'] },
    { level: 41, words: ['गला', 'पेट', 'कंधा', 'उंगली', 'घुटना', 'गर्दन', 'जीभ', 'होंठ', 'गाल', 'माथा'] },
    { level: 42, words: ['गुरु', 'शिष्य', 'पड़ोसी', 'मेहमान', 'बालक', 'बालिका', 'सहेली', 'बंधु', 'कुटुंब', 'साथी'] },
    { level: 43, words: ['अंतरिक्ष', 'प्रभात', 'निशा', 'तिमिर', 'किरण', 'ज्योति', 'क्षितिज', 'अनंत', 'वितान', 'नीहारिका'] },
    { level: 44, words: ['इस्पात', 'जस्ता', 'रांगा', 'गंधक', 'कोयला', 'संगमरमर', 'अभ्रक', 'स्फटिक', 'ग्रेनाइट', 'चूना'] },
    { level: 45, words: ['चीता', 'तेंदुआ', 'भेड़िया', 'लोमड़ी', 'लकड़बग्घा', 'बारहसिंगा', 'नीलगाय', 'जंगली', 'लंगूर', 'सांभर'] },
    { level: 46, words: ['पुस्तक', 'ग्रंथ', 'निबंध', 'पद', 'छंद', 'अलंकार', 'मुहावरा', 'भाषा', 'व्याकरण', 'शब्द'] },
    { level: 47, words: ['ग्राम', 'चौपाल', 'कुआं', 'बावड़ी', 'आश्रम', 'देवालय', 'बाजार', 'फाटक', 'मीनार', 'चौराहा'] },
    { level: 48, words: ['दीवाली', 'होली', 'रक्षाबंधन', 'दशहरा', 'पोंगल', 'ओणम', 'बैसाखी', 'छठ', 'लोहड़ी', 'संक्रांति'] },
    { level: 49, words: ['मूर्तिकला', 'चित्रकला', 'वास्तुकला', 'बुनाई', 'कढ़ाई', 'कुंभकला', 'अभिनय', 'गायन', 'वादन', 'नाट्य'] },
    { level: 50, words: ['स्वाभिमान', 'राष्ट्र', 'ध्वज', 'तिरंगा', 'स्वतंत्रता', 'बलिदान', 'अमर', 'प्रेरणा', 'उत्कर्ष', 'वैभव'] },
  ],

  // ── Grid configuration per level range ─────────────────────
  getGridSize(level) {
    if (level <= 10) return { rows: 9, cols: 9 };
    return { rows: 10, cols: 10 };
  },

  // ── Get words for a specific mode and level ────────────────
  getWordsForLevel(mode, level) {
    if (mode === 'english') {
      const data = this.english.find(l => l.level === level);
      return data ? data.words : [];
    }
    if (mode === 'master') {
      const data = this.master.find(l => l.level === level);
      return data ? data.pairs : [];
    }
    if (mode === 'hindi') {
      const data = this.hindi.find(l => l.level === level);
      return data ? data.words : [];
    }
    return [];
  },

  // ── Get the grid words (what goes INTO the grid) ───────────
  getGridWords(mode, level) {
    if (mode === 'master') {
      const pairs = this.getWordsForLevel(mode, level);
      return pairs.map(p => p.english);
    }
    return this.getWordsForLevel(mode, level);
  },

  // ── Get display clues (shown above the grid) ──────────────
  getClues(mode, level) {
    if (mode === 'master') {
      const pairs = this.getWordsForLevel(mode, level);
      return pairs.map(p => ({
        display: p.hindi,
        answer: p.english,
        hint: `${p.hindi} → ${p.english}`
      }));
    }
    if (mode === 'english') {
      const words = this.getWordsForLevel(mode, level);
      return words.map(w => ({
        display: w,
        answer: w,
        hint: w
      }));
    }
    if (mode === 'hindi') {
      const words = this.getWordsForLevel(mode, level);
      return words.map(w => ({
        display: w,
        answer: w,
        hint: w
      }));
    }
    return [];
  }
};
