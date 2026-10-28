// ============================================================
// database.js — IndexedDB Local Database (via Dexie.js)
// ============================================================
// Stores: user progress, settings, coin balance
// No server, no login — all local storage
// ============================================================

const GameDB = {

  db: null,

  /**
   * Initialize the database
   */
  async init() {
    this.db = new Dexie('WordSearchExplorer');

    this.db.version(1).stores({
      // Level progress: mode + level is the key
      progress: '[mode+level], mode, level, stars, completed',
      // User settings
      settings: 'key',
      // Coin transactions
      coins: '++id, timestamp',
    });

    // Seed default settings if first run
    const soundSetting = await this.db.settings.get('sound');
    if (!soundSetting) {
      await this.db.settings.bulkPut([
        { key: 'sound', value: true },
        { key: 'theme', value: 'dark' },
        { key: 'totalCoins', value: 120 },
        { key: 'hintsRemaining', value: 3 },
      ]);
    }
  },

  // ── Progress Operations ────────────────────────────────────

  /**
   * Save level completion
   */
  async saveProgress(mode, level, stars, timeTaken, coinsEarned) {
    const existing = await this.db.progress.get([mode, level]);

    // Only update if new stars are better
    const bestStars = existing ? Math.max(existing.stars, stars) : stars;
    const bestTime = existing ? Math.min(existing.bestTime || Infinity, timeTaken) : timeTaken;

    await this.db.progress.put({
      mode,
      level,
      stars: bestStars,
      bestTime,
      completed: true,
      lastPlayed: Date.now(),
    });

    // Add coins
    await this.addCoins(coinsEarned);

    return { bestStars, bestTime };
  },

  /**
   * Get progress for a specific level
   */
  async getProgress(mode, level) {
    return await this.db.progress.get([mode, level]);
  },

  /**
   * Get all progress for a mode
   */
  async getAllProgress(mode) {
    return await this.db.progress.where('mode').equals(mode).toArray();
  },

  /**
   * Check if a level is unlocked
   * Level 1 is always unlocked, others require previous level completed
   */
  async isLevelUnlocked(mode, level) {
    if (level === 1) return true;
    const prevProgress = await this.getProgress(mode, level - 1);
    return prevProgress?.completed === true;
  },

  /**
   * Get the highest unlocked level for a mode
   */
  async getHighestUnlockedLevel(mode) {
    const allProgress = await this.getAllProgress(mode);
    if (allProgress.length === 0) return 1;
    const completedLevels = allProgress
      .filter(p => p.completed)
      .map(p => p.level);
    return completedLevels.length > 0
      ? Math.max(...completedLevels) + 1
      : 1;
  },

  // ── Coins Operations ───────────────────────────────────────
  HINT_COST: 30,

  /**
   * Get total coins (persisted via localStorage and IndexedDB)
   */
  async getCoins() {
    try {
      const local = localStorage.getItem('user_coins');
      if (local !== null) {
        const val = parseInt(local, 10);
        if (!isNaN(val)) return val;
      }
    } catch (_) {}

    try {
      if (this.db) {
        const setting = await this.db.settings.get('totalCoins');
        if (setting && typeof setting.value === 'number') {
          try { localStorage.setItem('user_coins', setting.value); } catch (_) {}
          return setting.value;
        }
      }
    } catch (_) {}

    const defaultCoins = 120;
    try { localStorage.setItem('user_coins', defaultCoins); } catch (_) {}
    return defaultCoins;
  },

  /**
   * Add coins and persist to localStorage and IndexedDB
   */
  async addCoins(amount) {
    const current = await this.getCoins();
    const updated = current + amount;

    try { localStorage.setItem('user_coins', updated); } catch (_) {}

    try {
      if (this.db) {
        await this.db.settings.put({ key: 'totalCoins', value: updated });
        await this.db.coins.add({
          amount,
          timestamp: Date.now(),
        });
      }
    } catch (e) {
      console.warn('Dexie addCoins fallback:', e);
    }

    return updated;
  },

  /**
   * Spend coins (for hints, etc.)
   */
  async spendCoins(amount) {
    const current = await this.getCoins();
    if (current < amount) return false;

    const updated = current - amount;
    try { localStorage.setItem('user_coins', updated); } catch (_) {}

    try {
      if (this.db) {
        await this.db.settings.put({ key: 'totalCoins', value: updated });
        await this.db.coins.add({
          amount: -amount,
          timestamp: Date.now(),
        });
      }
    } catch (e) {
      console.warn('Dexie spendCoins fallback:', e);
    }

    return true;
  },

  // ── Settings Operations ────────────────────────────────────

  /**
   * Get theme preference ('dark' | 'light')
   */
  async getTheme() {
    try {
      const savedTheme = localStorage.getItem('user_theme');
      if (savedTheme === 'light' || savedTheme === 'dark') return savedTheme;
    } catch (_) {}

    const val = await this.getSetting('theme');
    return val === 'light' ? 'light' : 'dark';
  },

  /**
   * Set theme preference ('dark' | 'light')
   */
  async setTheme(theme) {
    try { localStorage.setItem('user_theme', theme); } catch (_) {}
    await this.setSetting('theme', theme);
  },

  /**
   * Get a setting value
   */
  async getSetting(key) {
    try {
      if (this.db) {
        const setting = await this.db.settings.get(key);
        return setting ? setting.value : null;
      }
    } catch (_) {}
    return null;
  },

  /**
   * Set a setting value
   */
  async setSetting(key, value) {
    try {
      if (this.db) {
        await this.db.settings.put({ key, value });
      }
    } catch (_) {}
  },

  // ── Hints ──────────────────────────────────────────────────

  /**
   * Use a hint (costs 30 coins)
   */
  async useHint() {
    return await this.spendCoins(this.HINT_COST);
  },

  // ── Reset ──────────────────────────────────────────────────

  /**
   * Reset all game data
   */
  async resetAll() {
    await this.db.progress.clear();
    await this.db.coins.clear();
    await this.db.settings.bulkPut([
      { key: 'sound', value: true },
      { key: 'theme', value: 'dark' },
      { key: 'totalCoins', value: 120 },
      { key: 'hintsRemaining', value: 3 },
    ]);
  }
};
