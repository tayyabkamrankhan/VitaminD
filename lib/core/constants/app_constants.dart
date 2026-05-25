class AppConstants {
  AppConstants._();

  // Vitamin D IU thresholds (WHO + PMDC)
  static const double targetIUAdult    = 600.0;
  static const double targetIUChild    = 400.0;
  static const double targetIUElderly  = 800.0;
  static const double toxicThreshold   = 4000.0;
  static const double normalMinRatio   = 0.75; // 75% of target = Normal
  static const double insuffMinRatio   = 0.40; // 40–74% = Insufficient

  // Fitzpatrick skin tone factors
  // South Asian (IV–VI) need significantly more UV for same synthesis
  static const Map<int, double> skinToneFactors = {
    1: 1.00,
    2: 0.85,
    3: 0.70,
    4: 0.55,
    5: 0.40,
    6: 0.30,
  };

  // Global city UV profiles (average annual peak UV index)
  static const Map<String, double> cityUVProfile = {
    // Asia (High UV)
    'Karachi, PK':    5.6, 'Lahore, PK':     4.8, 'Islamabad, PK':  4.5,
    'Peshawar, PK':   4.2, 'Quetta, PK':     5.4, 'Mumbai, IN':     6.1,
    'Delhi, IN':      5.3, 'Tokyo, JP':      4.1, 'Manila, PH':     7.5,
    'Bangkok, TH':    7.2, 'Riyadh, SA':     6.5,
    // North America (Varied)
    'New York, USA':  3.8, 'Los Angeles, USA': 5.2, 'Miami, USA':     6.0,
    'Chicago, USA':   3.5, 'Toronto, CA':    3.2, 'Mexico City, MX': 7.1,
    // Europe (Low UV)
    'London, UK':     2.8, 'Paris, FR':      3.1, 'Berlin, DE':     2.9,
    'Rome, IT':       4.3, 'Madrid, ES':     4.7, 'Oslo, NO':       2.0,
    // South America (High UV)
    'Sao Paulo, BR':  6.5, 'Buenos Aires, AR': 4.5, 'Bogota, CO':     8.2, 'Lima, PE':       6.8,
    // Africa (Very High UV)
    'Cairo, EG':      6.2, 'Lagos, NG':      7.8, 'Cape Town, ZA':  5.1, 'Nairobi, KE':    8.5,
    // Oceania
    'Sydney, AU':     5.5, 'Melbourne, AU':  4.8, 'Auckland, NZ':   4.5,
  };

  // Low-UV months per city (Northern Hemisphere: Nov-Feb | Southern Hemisphere: May-Aug)
  static const Map<String, List<int>> lowUVMonths = {
    // Asia
    'Karachi, PK':    [12, 1], 'Lahore, PK':     [11, 12, 1, 2],
    'Islamabad, PK':  [11, 12, 1, 2], 'Peshawar, PK':   [10, 11, 12, 1, 2],
    'Quetta, PK':     [10, 11, 12, 1, 2, 3], 'Mumbai, IN':     [12, 1],
    'Delhi, IN':      [11, 12, 1, 2], 'Tokyo, JP':      [11, 12, 1, 2],
    'Manila, PH':     [], 'Bangkok, TH':    [], 'Riyadh, SA':     [12, 1],
    // North America
    'New York, USA':  [11, 12, 1, 2, 3], 'Los Angeles, USA': [12, 1],
    'Miami, USA':     [12, 1], 'Chicago, USA':   [10, 11, 12, 1, 2, 3],
    'Toronto, CA':    [10, 11, 12, 1, 2, 3], 'Mexico City, MX':[12, 1],
    // Europe
    'London, UK':     [10, 11, 12, 1, 2, 3, 4], 'Paris, FR':      [10, 11, 12, 1, 2, 3],
    'Berlin, DE':     [10, 11, 12, 1, 2, 3], 'Rome, IT':       [11, 12, 1, 2],
    'Madrid, ES':     [11, 12, 1, 2], 'Oslo, NO':       [9, 10, 11, 12, 1, 2, 3, 4],
    // South America
    'Sao Paulo, BR':  [6, 7], 'Buenos Aires, AR': [5, 6, 7, 8],
    'Bogota, CO':     [], 'Lima, PE':       [6, 7],
    // Africa
    'Cairo, EG':      [12, 1, 2], 'Lagos, NG':      [],
    'Cape Town, ZA':  [5, 6, 7, 8], 'Nairobi, KE':    [],
    // Oceania
    'Sydney, AU':     [5, 6, 7, 8], 'Melbourne, AU':  [5, 6, 7, 8], 'Auckland, NZ':   [5, 6, 7, 8],
  };

  // Clothing exposure fractions
  static const double clothingFull    = 1.00; // arms + legs fully exposed
  static const double clothingHalf    = 0.50; // arms only
  static const double clothingMinimal = 0.20; // face + hands only

  // USB Serial
  static const int usbBaudRate   = 9600;
  static const int usbPacketSize = 7; // [uvH, uvL, r, g, b, tempH, tempL]

  // Hive box names
  static const String hiveBoxUV          = 'uv_readings';
  static const String hiveBoxProfiles    = 'user_profiles';
  static const String hiveBoxSupplements = 'supplement_logs';

  // Weather API
  static const String weatherBaseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String weatherApiKey  = 'e632b4a72a5a11b0697511a5d1d47bbd';

  // Firestore collections
  static const String colUsers       = 'users';
  static const String colUVReadings  = 'uvReadings';
  static const String colSupplements = 'supplementLogs';
  static const String colSymptoms    = 'symptomLogs';
  static const String colFamily      = 'familyMembers';
}
