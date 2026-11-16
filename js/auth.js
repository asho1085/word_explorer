// ============================================================
// auth.js — Word Search Explorer Authentication & Firestore Controller
// ============================================================
// Supports:
// 1. Username + Password Login / Registration (with instant Username resolution)
// 2. Google (Gmail) Sign-In with preferred Username & Avatar
// 3. Guest Mode
// 4. Real Firebase Authentication & Cloud Firestore Leaderboard Sync
//    (With resilient offline fallback & cost-optimized caching)
// ============================================================

const Auth = {
  currentUser: null,
  isFirebaseActive: false,
  _listeners: [],
  _cachedLeaderboard: null,
  _leaderboardCacheTime: 0,
  _lastSyncedStars: -1,

  // ── Predefined Game Avatars ─────────────────────────────────
  AVATARS: [
    '🦊', '🦁', '🦉', '🐯', '🐼', '🐺', '🦅', '🐲',
    '🦄', '🐬', '🦈', '🦖', '👑', '🧙', '🥷', '⚔️',
    '🦸', '🕵️', '🚀', '💎', '🪐', '⚡', '🌟', '🏆'
  ],

  /**
   * Return Firestore database instance targeting the project's 'default' database
   */
  getDb() {
    if (typeof firebase === 'undefined' || !firebase.apps || !firebase.apps.length) return null;
    try {
      return firebase.app().firestore('default');
    } catch (_) {
      try {
        return firebase.firestore();
      } catch (_) {
        return null;
      }
    }
  },

  /**
   * Initialize Authentication & Firestore Service
   */
  async init() {
    this.currentUser = this._getLocalSession();

    if (typeof firebase !== 'undefined' && window.isFirebaseConfigured && window.isFirebaseConfigured()) {
      try {
        if (!firebase.apps.length) {
          firebase.initializeApp(window.FIREBASE_CONFIG);
        }
        this.isFirebaseActive = true;
        console.log('[Auth] Firebase & Firestore initialized.');

        // Enable offline persistence to save reads and work offline
        try {
          const db = this.getDb();
          if (db) db.enablePersistence({ synchronizeTabs: true });
        } catch (_) {}

        // Listen for Firebase auth state changes
        firebase.auth().onAuthStateChanged(async (firebaseUser) => {
          if (firebaseUser) {
            let username = firebaseUser.displayName;
            let avatar = '🦊';

            // Check cached local session
            const cached = this._getLocalSession();
            if (cached && cached.uid === firebaseUser.uid) {
              username = cached.username || username;
              avatar = cached.avatar || avatar;
            } else if (!username) {
              username = firebaseUser.email ? firebaseUser.email.split('@')[0] : 'Player';
            }

            // Fetch firestore profile doc if exists
            try {
              const db = this.getDb();
              const doc = db ? await db.collection('users').doc(firebaseUser.uid).get() : null;
              if (doc && doc.exists) {
                const data = doc.data();
                if (data.username) username = data.username;
                if (data.avatar) avatar = data.avatar;
                if (data.welcomeBonusClaimed) {
                  localStorage.setItem('wse_welcome_bonus_' + firebaseUser.uid, 'true');
                }
              }
            } catch (_) {}

            this.currentUser = {
              uid: firebaseUser.uid,
              username: username,
              email: firebaseUser.email || '',
              avatar: avatar,
              photoURL: firebaseUser.photoURL || null,
              provider: firebaseUser.providerData && firebaseUser.providerData[0] ? firebaseUser.providerData[0].providerId : 'firebase',
              isGuest: firebaseUser.isAnonymous || false
            };
            this._saveLocalSession(this.currentUser);
          } else {
            this.currentUser = this._getLocalSession();
          }
          this._notifyListeners();
        });
        return;
      } catch (err) {
        console.warn('[Auth] Firebase init failed, using local database mode:', err);
      }
    }

    // Local session restore
    this.currentUser = this._getLocalSession();
    this._notifyListeners();
  },

  /**
   * Register with Username, Email, Password & Chosen Avatar
   */
  async register(username, email, password, avatar = '🦊') {
    const cleanUsername = (username || '').trim();
    const cleanEmail = (email || '').trim().toLowerCase();
    const cleanAvatar = this.AVATARS.includes(avatar) ? avatar : '🦊';

    if (!cleanUsername || cleanUsername.length < 3 || cleanUsername.length > 30) {
      throw new Error('Username must be between 3 and 30 characters long.');
    }
    if (!/^[a-zA-Z0-9 _#-]+$/.test(cleanUsername)) {
      throw new Error('Username can only contain letters, numbers, spaces, and hyphens.');
    }
    if (/(http|www|\.com|\.net|\.org|\.io|\.xyz)/i.test(cleanUsername)) {
      throw new Error('Username cannot contain website links or URLs.');
    }
    if (!cleanEmail || !cleanEmail.includes('@') || !cleanEmail.includes('.')) {
      throw new Error('Please enter a valid email address.');
    }
    if (!password || password.length < 6) {
      throw new Error('Password must be at least 6 characters long.');
    }

    // Check local accounts first to prevent duplicate usernames
    const accounts = this._getRegisteredAccounts();
    for (const id in accounts) {
      if (accounts[id].username && accounts[id].username.toLowerCase() === cleanUsername.toLowerCase()) {
        throw new Error(`Username "${cleanUsername}" is already taken.`);
      }
      if (accounts[id].email && accounts[id].email.toLowerCase() === cleanEmail) {
        throw new Error('An account with this email already exists. Please log in.');
      }
    }

    if (this.isFirebaseActive) {
      try {
        // 1. Firebase Auth Registration
        const userCredential = await firebase.auth().createUserWithEmailAndPassword(cleanEmail, password);
        try { await userCredential.user.updateProfile({ displayName: cleanUsername }); } catch (_) {}

        this.currentUser = {
          uid: userCredential.user.uid,
          username: cleanUsername,
          email: cleanEmail,
          avatar: cleanAvatar,
          provider: 'password',
          isGuest: false
        };
        this._saveLocalSession(this.currentUser);

        // Always save locally as backup and for instant username lookups
        accounts[cleanEmail] = { ...this.currentUser, password: password };
        localStorage.setItem('wse_registered_accounts', JSON.stringify(accounts));

        // Sync initial document to Firestore
        try { await this.syncToFirestore(0, 0, 0); } catch (_) {}

        this._notifyListeners();
        return this.currentUser;
      } catch (fbErr) {
        if (fbErr.code === 'auth/email-already-in-use') {
          throw new Error('This email is already registered. Please click Log In.');
        } else if (fbErr.code === 'auth/weak-password') {
          throw new Error('Password must be at least 6 characters.');
        } else if (fbErr.code === 'auth/operation-not-allowed') {
          console.warn('[Firebase] Email/Password provider disabled in Console. Saving locally as fallback.');
          // Fall through to local registration!
        } else {
          console.warn('[Firebase] Registration error, using local fallback:', fbErr);
          // If offline or permission, continue with local registration so user is never blocked!
        }
      }
    }

    // Local Registration Fallback
    const uid = 'user_' + Date.now();
    const user = {
      uid: uid,
      username: cleanUsername,
      email: cleanEmail,
      avatar: cleanAvatar,
      password: password,
      provider: 'password',
      isGuest: false,
      createdAt: new Date().toISOString()
    };

    accounts[cleanEmail] = user;
    localStorage.setItem('wse_registered_accounts', JSON.stringify(accounts));

    this.currentUser = {
      uid: user.uid,
      username: user.username,
      email: user.email,
      avatar: cleanAvatar,
      provider: 'password',
      isGuest: false
    };
    this._saveLocalSession(this.currentUser);
    this._notifyListeners();
    return this.currentUser;
  },

  /**
   * Log In with Username or Email + Password
   */
  async login(identifier, password) {
    const cleanId = (identifier || '').trim();
    if (!cleanId) {
      throw new Error('Please enter your username or email.');
    }
    if (!password) {
      throw new Error('Please enter your password.');
    }

    const cleanLower = cleanId.toLowerCase();
    const accounts = this._getRegisteredAccounts();

    // 1. Resolve username to email if identifier is not an email
    let targetEmail = cleanLower;
    let targetUsername = cleanId;

    if (!targetEmail.includes('@')) {
      // Find matching username in local registered accounts
      for (const k in accounts) {
        if (accounts[k].username && accounts[k].username.toLowerCase() === cleanLower) {
          targetEmail = accounts[k].email;
          targetUsername = accounts[k].username;
          break;
        }
      }

      // If not in local cache, query Firestore by username
      if (!targetEmail.includes('@') && this.isFirebaseActive) {
        try {
          const db = this.getDb();
          const snap = db ? await db.collection('users')
            .where('username', '==', cleanId)
            .limit(1)
            .get() : null;
          if (snap && !snap.empty) {
            targetEmail = snap.docs[0].data().email;
            targetUsername = snap.docs[0].data().username;
          }
        } catch (_) {}
      }
    }

    // 2. Try Firebase Login if active and we have an email
    if (this.isFirebaseActive && targetEmail.includes('@')) {
      try {
        const cred = await firebase.auth().signInWithEmailAndPassword(targetEmail, password);
        let username = cred.user.displayName || targetUsername || targetEmail.split('@')[0];
        let avatar = '🦊';

        // Check firestore for profile
        try {
          const db = this.getDb();
          const doc = db ? await db.collection('users').doc(cred.user.uid).get() : null;
          if (doc && doc.exists) {
            const d = doc.data();
            if (d.username) username = d.username;
            if (d.avatar) avatar = d.avatar;
            if (d.welcomeBonusClaimed) {
              localStorage.setItem('wse_welcome_bonus_' + cred.user.uid, 'true');
            }
          }
        } catch (_) {}

        this.currentUser = {
          uid: cred.user.uid,
          username: username,
          email: cred.user.email,
          avatar: avatar,
          provider: 'password',
          isGuest: false
        };
        this._saveLocalSession(this.currentUser);

        // Update local cache
        accounts[cred.user.email] = { ...this.currentUser, password: password };
        localStorage.setItem('wse_registered_accounts', JSON.stringify(accounts));

        this._notifyListeners();
        return this.currentUser;
      } catch (fbErr) {
        if (fbErr.code === 'auth/wrong-password' || fbErr.code === 'auth/invalid-credential') {
          throw new Error('Incorrect password. Please try again.');
        } else if (fbErr.code === 'auth/user-not-found') {
          throw new Error('No account found for this username or email.');
        } else if (fbErr.code === 'auth/operation-not-allowed') {
          console.warn('[Firebase] Email/Password provider disabled in Console. Trying local fallback.');
        } else {
          console.warn('[Firebase] Login error, checking local fallback:', fbErr);
        }
      }
    }

    // 3. Fallback / Local Database matching
    let matched = null;
    for (const key in accounts) {
      const acc = accounts[key];
      if ((acc.email && acc.email.toLowerCase() === cleanLower) ||
          (acc.username && acc.username.toLowerCase() === cleanLower)) {
        matched = acc;
        break;
      }
    }

    if (!matched) {
      throw new Error('No account found with this username or email.');
    }

    if (matched.password && matched.password !== password) {
      throw new Error('Incorrect password. Please try again.');
    }

    this.currentUser = {
      uid: matched.uid,
      username: matched.username,
      email: matched.email,
      avatar: matched.avatar || '🦊',
      provider: 'password',
      isGuest: false
    };
    this._saveLocalSession(this.currentUser);
    this._notifyListeners();
    return this.currentUser;
  },

  /**
   * Sign In with Google (Gmail)
   */
  async loginWithGoogle(email = '', username = '', avatar = '👑') {
    // If called with specific email & username from prompt modal
    if (email) {
      const cleanEmail = email.trim().toLowerCase();
      if (!cleanEmail.includes('@')) {
        throw new Error('Please enter a valid Gmail address.');
      }

      let finalUsername = username.trim() || cleanEmail.split('@')[0];
      const accounts = this._getRegisteredAccounts();
      const uid = accounts[cleanEmail] ? accounts[cleanEmail].uid : ('google_' + Date.now());

      const user = {
        uid: uid,
        username: finalUsername,
        email: cleanEmail,
        avatar: avatar || '👑',
        provider: 'google',
        isGuest: false,
        createdAt: new Date().toISOString()
      };

      accounts[cleanEmail] = user;
      localStorage.setItem('wse_registered_accounts', JSON.stringify(accounts));

      this.currentUser = user;
      this._saveLocalSession(this.currentUser);

      if (this.isFirebaseActive) {
        try { await this.syncToFirestore(0, 0, 0); } catch (_) {}
      }

      this._notifyListeners();
      return this.currentUser;
    }

    // Direct Firebase Popup Sign In
    if (this.isFirebaseActive) {
      try {
        const provider = new firebase.auth.GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        const result = await firebase.auth().signInWithPopup(provider);
        const fbUser = result.user;

        let finalUsername = fbUser.displayName || (fbUser.email ? fbUser.email.split('@')[0] : 'Player');
        let finalAvatar = avatar || '👑';

        try {
          const db = this.getDb();
          const doc = db ? await db.collection('users').doc(fbUser.uid).get() : null;
          if (doc && doc.exists) {
            const data = doc.data();
            if (data.username) finalUsername = data.username;
            if (data.avatar) finalAvatar = data.avatar;
          }
        } catch (_) {}

        this.currentUser = {
          uid: fbUser.uid,
          username: finalUsername,
          email: fbUser.email || '',
          avatar: finalAvatar,
          photoURL: fbUser.photoURL || null,
          provider: 'google',
          isGuest: false
        };
        this._saveLocalSession(this.currentUser);

        try { await this.syncToFirestore(0, 0, 120); } catch (_) {}

        this._notifyListeners();
        return this.currentUser;
      } catch (fbErr) {
        if (fbErr.code === 'auth/popup-closed-by-user') {
          throw new Error('Sign-in popup was closed.');
        }
        // If Google sign-in is disabled or blocked on localhost, trigger Google prompt modal
        console.warn('[Firebase] Google sign-in popup error, showing modal fallback:', fbErr);
        const modal = document.getElementById('google-auth-modal');
        if (modal) modal.classList.add('active');
        return null;
      }
    }

    // Offline / Local
    const modal = document.getElementById('google-auth-modal');
    if (modal) modal.classList.add('active');
    return null;
  },

  /**
   * Continue as Guest
   */
  async loginAsGuest(avatar = '🦊') {
    const guestId = 'guest_' + Math.floor(1000 + Math.random() * 9000);
    this.currentUser = {
      uid: guestId,
      username: 'Explorer #' + guestId.split('_')[1],
      email: '',
      avatar: avatar,
      provider: 'guest',
      isGuest: true
    };
    this._saveLocalSession(this.currentUser);
    this._notifyListeners();
    return this.currentUser;
  },

  /**
   * Update Avatar
   */
  async updateAvatar(newAvatar) {
    if (!this.AVATARS.includes(newAvatar) || !this.currentUser) return;
    this.currentUser.avatar = newAvatar;
    this._saveLocalSession(this.currentUser);

    // Update in local accounts database
    if (!this.currentUser.isGuest && this.currentUser.email) {
      const accounts = this._getRegisteredAccounts();
      if (accounts[this.currentUser.email]) {
        accounts[this.currentUser.email].avatar = newAvatar;
        localStorage.setItem('wse_registered_accounts', JSON.stringify(accounts));
      }
    }

    // Update in Firestore
    if (this.isFirebaseActive && !this.currentUser.isGuest) {
      try {
        const db = this.getDb();
        if (db) {
          await db.collection('users').doc(this.currentUser.uid).set({
            avatar: newAvatar,
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
          }, { merge: true });

          await db.collection('leaderboard').doc(this.currentUser.uid).set({
            avatar: newAvatar,
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
          }, { merge: true });
        }
      } catch (err) {
        console.warn('[Firestore] Failed to update avatar:', err);
      }
    }

    this._notifyListeners();
  },

  /**
   * Check if user has already claimed the 200 coins welcome bonus
   */
  isWelcomeBonusClaimed(uid) {
    // 1. Check device-level global flag
    if (localStorage.getItem('wse_welcome_bonus_claimed') === 'true') {
      return true;
    }
    if (!uid) return false;
    // 2. Check per-user localStorage flag
    if (localStorage.getItem('wse_welcome_bonus_' + uid) === 'true') {
      return true;
    }
    // 3. Check current user in-memory object
    if (this.currentUser && (this.currentUser.uid === uid || this.currentUser.welcomeBonusClaimed)) {
      if (this.currentUser.welcomeBonusClaimed) return true;
    }
    // 4. Check registered accounts dictionary
    const accounts = this._getRegisteredAccounts();
    for (const key in accounts) {
      if ((accounts[key].uid === uid || accounts[key].email === uid) && accounts[key].welcomeBonusClaimed) {
        return true;
      }
    }
    return false;
  },

  /**
   * Mark the welcome bonus as claimed for the user and sync to Firestore
   */
  async markWelcomeBonusClaimed(uid, coins = 200) {
    try {
      localStorage.setItem('wse_welcome_bonus_claimed', 'true');
      if (uid) {
        localStorage.setItem('wse_welcome_bonus_' + uid, 'true');
      }
    } catch (_) {}

    if (this.currentUser) {
      this.currentUser.welcomeBonusClaimed = true;
      this._saveLocalSession(this.currentUser);
    }

    const accounts = this._getRegisteredAccounts();
    for (const key in accounts) {
      if (accounts[key].uid === uid || (this.currentUser && accounts[key].email === this.currentUser.email)) {
        accounts[key].welcomeBonusClaimed = true;
        accounts[key].coins = coins;
        localStorage.setItem('wse_registered_accounts', JSON.stringify(accounts));
        break;
      }
    }

    // Sync to Firestore user document
    if (this.isFirebaseActive && uid && !uid.startsWith('guest')) {
      try {
        const db = this.getDb();
        if (db) {
          await db.collection('users').doc(uid).set({
            welcomeBonusClaimed: true,
            coins: coins,
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
          }, { merge: true });
          console.log('[Firestore] Welcome bonus claimed recorded for', uid);
        }
      } catch (e) {
        console.warn('[Firestore] Failed to save welcome bonus to Firestore:', e);
      }
    }
  },

  /**
   * ── MINIMUM-USE FIRESTORE LEADERBOARD SYNC ────────────────────
   */
  async syncToFirestore(stars, levelsCompleted, coins, force = false) {
    if (!this.isFirebaseActive || !this.currentUser || this.currentUser.isGuest) return;

    if (!force && this._lastSyncedStars >= 0 && stars <= this._lastSyncedStars) {
      return;
    }

    try {
      const db = this.getDb();
      if (!db) return;
      const payload = {
        uid: this.currentUser.uid,
        username: this.currentUser.username,
        avatar: this.currentUser.avatar || '🦊',
        stars: stars,
        levelsCompleted: levelsCompleted,
        coins: coins,
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
      };

      await db.collection('users').doc(this.currentUser.uid).set(payload, { merge: true });
      await db.collection('leaderboard').doc(this.currentUser.uid).set({
        username: this.currentUser.username,
        avatar: this.currentUser.avatar || '🦊',
        stars: stars,
        levelsCompleted: levelsCompleted,
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      this._lastSyncedStars = stars;
      console.log('[Firestore] Synced player stars to leaderboard:', stars);
    } catch (err) {
      console.warn('[Firestore] Sync warning (offline or permission):', err);
    }
  },

  /**
   * ── MINIMUM-USE FIRESTORE LEADERBOARD FETCH ───────────────────
   */
  async fetchLeaderboardFromFirestore() {
    const CACHE_TTL_MS = 5 * 60 * 1000;
    const now = Date.now();

    if (this._cachedLeaderboard && (now - this._leaderboardCacheTime < CACHE_TTL_MS)) {
      return this._cachedLeaderboard;
    }

    if (!this.isFirebaseActive) {
      return null;
    }

    try {
      const db = this.getDb();
      if (!db) return [];
      const snap = await db.collection('leaderboard')
        .orderBy('stars', 'desc')
        .limit(25)
        .get();

      const realPlayers = [];
      snap.forEach(doc => {
        const d = doc.data();
        realPlayers.push({
          username: d.username || 'Explorer',
          avatar: d.avatar || '🦊',
          stars: d.stars || 0,
          levels: d.levelsCompleted || 0,
          uid: doc.id
        });
      });

      this._cachedLeaderboard = realPlayers;
      this._leaderboardCacheTime = now;
      return realPlayers;
    } catch (err) {
      console.warn('[Firestore] Failed to fetch leaderboard:', err);
      return null;
    }
  },

  /**
   * Log Out
   */
  async logout() {
    if (this.isFirebaseActive && firebase.auth().currentUser) {
      try { await firebase.auth().signOut(); } catch (_) {}
    }
    this.currentUser = null;
    this._lastSyncedStars = -1;
    localStorage.removeItem('wse_current_session');
    this._notifyListeners();
  },

  onAuthStateChanged(callback) {
    if (typeof callback === 'function') {
      this._listeners.push(callback);
      callback(this.currentUser);
    }
  },

  _notifyListeners() {
    this._listeners.forEach(cb => {
      try { cb(this.currentUser); } catch (e) { console.error(e); }
    });
  },

  _saveLocalSession(user) {
    try { localStorage.setItem('wse_current_session', JSON.stringify(user)); } catch (_) {}
  },

  _getLocalSession() {
    try {
      const raw = localStorage.getItem('wse_current_session');
      return raw ? JSON.parse(raw) : null;
    } catch (_) { return null; }
  },

  _getRegisteredAccounts() {
    try {
      const raw = localStorage.getItem('wse_registered_accounts');
      return raw ? JSON.parse(raw) : {};
    } catch (_) { return {}; }
  }
};
