// ============================================================
// words.js — Word Data for Word Search Explorer
// ============================================================
// 30 Levels per mode, 10 words per level, 100% unique words
// ============================================================

const WORD_DATA = {

  totalLevels: 30,

  // ── English Mode: 30 Levels, 10 words each (300 unique words) ──
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
  ],

  // ── Master Mode: 30 Levels, 10 pairs each (300 unique pairs) ──
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
  ],

  // ── Hindi Mode: 30 Levels, 10 words each (300 unique words) ──
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
