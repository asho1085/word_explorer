// ============================================================
// app.js — Main Application Controller
// ============================================================
// SPA Router, Screen Management, Game Engine, Event Handlers
// ============================================================

const App = {

  // ── State ──────────────────────────────────────────────────
  currentScreen: 'mode-selection',
  currentMode: null,      // 'english' | 'hindi' | 'master'
  currentLevel: null,
  gameState: null,        // Active game state
  timerInterval: null,
  coins: 0,
  theme: 'dark',
  soundEnabled: true,
  _audioCtx: null,
  _pendingHintClue: null,

  // ── Initialize ─────────────────────────────────────────────
  async init() {
    try {
      await GameDB.init();
      if (typeof Auth !== 'undefined') {
        await Auth.init();
      }
      this.coins = await GameDB.getCoins();

      // Normalize coins: if bonus claimed and no levels played yet, cap at 200
      const activeUid = (typeof Auth !== 'undefined' && Auth.currentUser) ? Auth.currentUser.uid : null;
      const isClaimed = typeof Auth !== 'undefined' ? Auth.isWelcomeBonusClaimed(activeUid) : false;
      if (isClaimed) {
        const totalCompleted = await GameDB.getTotalCompletedLevels();
        if (totalCompleted === 0 && this.coins > 200) {
          this.coins = 200;
          await GameDB.setCoins(200);
        }
      } else if (this.coins === 120 || this.coins === 150) {
        this.coins = 0;
        await GameDB.setCoins(0);
      }

      this.theme = await GameDB.getTheme();
      const sound = await GameDB.getSetting('sound');
      this.soundEnabled = sound !== false;
      this.applyTheme(this.theme);
      this.bindGlobalEvents();
      this.bindAuthEvents();

      if (typeof Auth !== 'undefined' && Auth.currentUser) {
        this.updateUserProfileDisplay(Auth.currentUser);
        this.showScreen('mode-selection');
        this.checkAndShowWelcomeBonus(Auth.currentUser);
      } else {
        this.showScreen('auth-screen');
      }
      this.updateCoinsDisplay();
    } catch (err) {
      console.error('App init error:', err);
      // Fallback: still show the app
      this.showScreen('mode-selection');
    }
  },

  // ── Web Audio Synthesizer (Offline & Zero-dependency) ──────
  playSound(type) {
    if (!this.soundEnabled) return;
    try {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (!AudioCtx) return;
      if (!this._audioCtx) {
        this._audioCtx = new AudioCtx();
      }
      if (this._audioCtx.state === 'suspended') {
        this._audioCtx.resume();
      }
      const ctx = this._audioCtx;
      const now = ctx.currentTime;

      if (type === 'tap') {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(440, now);
        osc.frequency.exponentialRampToValueAtTime(880, now + 0.05);
        gain.gain.setValueAtTime(0.08, now);
        gain.gain.linearRampToValueAtTime(0.001, now + 0.05);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.05);
      } else if (type === 'found') {
        // Joyful chord chime
        [523.25, 659.25, 783.99].forEach((freq, i) => {
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.type = 'triangle';
          osc.frequency.value = freq;
          gain.gain.setValueAtTime(0.12, now + i * 0.07);
          gain.gain.exponentialRampToValueAtTime(0.001, now + i * 0.07 + 0.25);
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start(now + i * 0.07);
          osc.stop(now + i * 0.07 + 0.25);
        });
      } else if (type === 'complete') {
        // Victory fanfare
        [523.25, 659.25, 783.99, 1046.50].forEach((freq, i) => {
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.type = 'triangle';
          osc.frequency.value = freq;
          gain.gain.setValueAtTime(0.15, now + i * 0.09);
          gain.gain.exponentialRampToValueAtTime(0.001, now + i * 0.09 + 0.35);
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start(now + i * 0.09);
          osc.stop(now + i * 0.09 + 0.35);
        });
      } else if (type === 'hint') {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(587.33, now);
        osc.frequency.exponentialRampToValueAtTime(880, now + 0.18);
        gain.gain.setValueAtTime(0.1, now);
        gain.gain.linearRampToValueAtTime(0.001, now + 0.18);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.18);
      }
    } catch (_) {
      // Audio not permitted or not supported
    }
  },

  // ── Theme Management ───────────────────────────────────────
  applyTheme(theme) {
    this.theme = theme;
    if (theme === 'light') {
      document.body.classList.add('light-mode');
    } else {
      document.body.classList.remove('light-mode');
    }

    // Toggle button icons (sun for switching to light, moon for switching to dark)
    const icon = theme === 'light' ? '🌙' : '☀️';
    const title = theme === 'light' ? 'Switch to Dark Mode' : 'Switch to Light Mode';
    document.querySelectorAll('.theme-toggle-btn').forEach(btn => {
      btn.textContent = icon;
      btn.title = title;
      btn.setAttribute('aria-label', title);
    });

    // Settings screen toggle sync
    const settingsToggle = document.getElementById('toggle-theme');
    if (settingsToggle) {
      settingsToggle.checked = theme === 'light';
    }
    const settingsDesc = document.getElementById('settings-theme-desc');
    if (settingsDesc) {
      settingsDesc.textContent = theme === 'light' ? 'Light mode active' : 'Dark mode active';
    }
    const settingsIcon = document.getElementById('settings-theme-icon');
    if (settingsIcon) {
      settingsIcon.textContent = theme === 'light' ? '☀️' : '🌙';
    }
  },

  async toggleTheme() {
    const newTheme = this.theme === 'light' ? 'dark' : 'light';
    this.applyTheme(newTheme);
    await GameDB.setTheme(newTheme);
    this.playSound('tap');
    this.showToast(`Switched to ${newTheme === 'light' ? 'White' : 'Dark'} Mode`);
  },

  // ── Screen Management ──────────────────────────────────────
  showScreen(screenId) {
    // Hide all screens
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));

    // Show target screen
    const screen = document.getElementById(screenId);
    if (screen) {
      screen.classList.add('active');
      this.currentScreen = screenId;
    }

    // Stop timer if leaving game
    if (screenId !== 'game-screen' && this.timerInterval) {
      clearInterval(this.timerInterval);
      this.timerInterval = null;
    }
  },

  // ── Global Events ──────────────────────────────────────────
  bindGlobalEvents() {
    // Theme toggle buttons across all screens
    document.querySelectorAll('.theme-toggle-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        this.toggleTheme();
      });
    });

    // Mode selection
    document.querySelectorAll('.mode-card').forEach(card => {
      card.addEventListener('click', () => {
        const mode = card.dataset.mode;
        this.currentMode = mode;
        this.openLevelSelection(mode);
      });
    });

    // Settings button
    document.getElementById('btn-settings')?.addEventListener('click', () => {
      this.showScreen('settings-screen');
      this.renderSettings();
    });

    // Leaderboard button
    document.getElementById('btn-leaderboard')?.addEventListener('click', () => {
      this.openLeaderboard();
    });
    document.getElementById('btn-refresh-leaderboard')?.addEventListener('click', () => {
      this.renderLeaderboard();
    });

    // Back buttons
    document.querySelectorAll('.back-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const target = btn.dataset.target;
        if (target === 'mode-selection') {
          this.showScreen('mode-selection');
        } else if (target === 'level-selection') {
          this.showScreen('level-selection');
        }
      });
    });

    // Coin add (+) buttons
    document.querySelectorAll('.coin-add').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        this.openInsufficientCoinsModal();
      });
    });

    // Game action buttons
    document.getElementById('btn-hint')?.addEventListener('click', () => this.showHint());
    document.getElementById('btn-clear')?.addEventListener('click', () => this.clearSelection());
    document.getElementById('btn-shuffle')?.addEventListener('click', () => this.shuffleGrid());

    // Hint popup close
    document.getElementById('hint-close')?.addEventListener('click', () => this.closeHint());
    document.getElementById('hint-ok')?.addEventListener('click', () => this.closeHint());

    // Insufficient coins modal buttons
    document.getElementById('btn-close-coins-modal')?.addEventListener('click', () => {
      this.closeInsufficientCoinsModal();
    });
    document.getElementById('btn-watch-ad-hint')?.addEventListener('click', () => {
      this.watchRewardedAd();
    });

    // Level complete buttons
    document.getElementById('btn-next-level')?.addEventListener('click', () => this.nextLevel());
    document.getElementById('btn-replay-level')?.addEventListener('click', () => this.replayLevel());
    document.getElementById('btn-go-home')?.addEventListener('click', () => {
      this.closeLevelComplete();
      this.showScreen('mode-selection');
    });

    // Settings actions
    document.getElementById('btn-reset-progress')?.addEventListener('click', () => this.resetProgress());

    // Sound toggle
    document.getElementById('toggle-sound')?.addEventListener('change', async (e) => {
      this.soundEnabled = e.target.checked;
      await GameDB.setSetting('sound', e.target.checked);
      if (this.soundEnabled) this.playSound('tap');
    });

    // Theme toggle switch in settings
    document.getElementById('toggle-theme')?.addEventListener('change', async () => {
      await this.toggleTheme();
    });

    // Responsive window resize listener
    window.addEventListener('resize', () => {
      if (this.currentScreen === 'game-screen' && this.gameState) {
        const { cols, rows } = this.gameState;
        const container = document.getElementById('word-grid');
        if (container) {
          const availableWidth = Math.min(window.innerWidth - 32, 400);
          const gap = 3;
          const computedCell = Math.floor((availableWidth - (cols + 1) * gap - 8) / cols);
          const cellSize = Math.min(44, Math.max(26, computedCell));
          container.style.setProperty('--cell-size', `${cellSize}px`);
          container.style.gridTemplateColumns = `repeat(${cols}, ${cellSize}px)`;
          container.style.gridTemplateRows = `repeat(${rows}, ${cellSize}px)`;
        }
      }
    });
  },

  updateCoinsDisplay() {
    document.querySelectorAll('.coin-count').forEach(el => {
      el.textContent = this.coins;
    });
  },

  // ── Auth Management ────────────────────────────────────────
  bindAuthEvents() {
    let isSignUp = false;
    let selectedAvatar = '🦊';

    const tabLogin = document.getElementById('tab-login');
    const tabSignup = document.getElementById('tab-signup');
    const fieldAvatar = document.getElementById('field-avatar');
    const fieldUsername = document.getElementById('field-username');
    const fieldIdentifier = document.getElementById('field-identifier');
    const fieldEmail = document.getElementById('field-email');
    const submitText = document.getElementById('auth-submit-text');
    const authAlert = document.getElementById('auth-alert');
    const btnTogglePwd = document.getElementById('btn-toggle-pwd');
    const inputPassword = document.getElementById('auth-input-password');

    const showAlert = (msg, isError = true) => {
      if (!authAlert) return;
      authAlert.textContent = msg;
      authAlert.className = `auth-alert ${isError ? 'error' : 'success'}`;
      authAlert.style.display = 'block';
    };

    const clearAlert = () => {
      if (!authAlert) return;
      authAlert.style.display = 'none';
      authAlert.textContent = '';
    };

    // Toggle password visibility
    btnTogglePwd?.addEventListener('click', () => {
      if (!inputPassword) return;
      const type = inputPassword.getAttribute('type') === 'password' ? 'text' : 'password';
      inputPassword.setAttribute('type', type);
      btnTogglePwd.textContent = type === 'password' ? '👁️' : '🙈';
    });

    // Avatar picker in registration
    document.querySelectorAll('#auth-avatar-picker .avatar-pill').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('#auth-avatar-picker .avatar-pill').forEach(b => b.classList.remove('selected'));
        btn.classList.add('selected');
        selectedAvatar = btn.dataset.avatar || '🦊';
      });
    });

    // Avatar picker in profile modal
    document.querySelectorAll('#profile-avatar-picker .avatar-pill').forEach(btn => {
      btn.addEventListener('click', async () => {
        const avatar = btn.dataset.avatar || '🦊';
        document.querySelectorAll('#profile-avatar-picker .avatar-pill').forEach(b => b.classList.remove('selected'));
        btn.classList.add('selected');
        if (typeof Auth !== 'undefined') {
          await Auth.updateAvatar(avatar);
          this.showToast(`Avatar changed to ${avatar}!`);
          this.updateUserProfileDisplay(Auth.currentUser);
          const modalAvatar = document.getElementById('profile-modal-avatar');
          if (modalAvatar) modalAvatar.textContent = avatar;
        }
      });
    });

    // Tab switching
    tabLogin?.addEventListener('click', () => {
      isSignUp = false;
      tabLogin.classList.add('active');
      tabSignup?.classList.remove('active');
      if (fieldAvatar) fieldAvatar.style.display = 'none';
      if (fieldUsername) fieldUsername.style.display = 'none';
      if (fieldIdentifier) fieldIdentifier.style.display = 'block';
      if (fieldEmail) fieldEmail.style.display = 'none';
      if (submitText) submitText.textContent = 'Log In';
      clearAlert();
    });

    tabSignup?.addEventListener('click', () => {
      isSignUp = true;
      tabSignup?.classList.add('active');
      tabLogin?.classList.remove('active');
      if (fieldAvatar) fieldAvatar.style.display = 'block';
      if (fieldUsername) fieldUsername.style.display = 'block';
      if (fieldIdentifier) fieldIdentifier.style.display = 'none';
      if (fieldEmail) fieldEmail.style.display = 'block';
      if (submitText) submitText.textContent = 'Create Account';
      clearAlert();
    });

    // Form submit handler
    const handleAuthSubmit = async () => {
      clearAlert();

      const pwd = document.getElementById('auth-input-password')?.value || '';

      try {
        let activeUser = null;
        if (isSignUp) {
          const username = document.getElementById('auth-input-username')?.value || '';
          const email = document.getElementById('auth-input-email')?.value || '';
          activeUser = await Auth.register(username, email, pwd, selectedAvatar);
          this.showToast(`Welcome, ${username}! Account created.`);
        } else {
          const identifier = document.getElementById('auth-input-identifier')?.value || '';
          activeUser = await Auth.login(identifier, pwd);
          this.showToast(`Welcome back, ${activeUser.username}!`);
        }
        this.showScreen('mode-selection');
        this.checkAndShowWelcomeBonus(activeUser);
      } catch (err) {
        showAlert(err.message || 'Authentication error', true);
      }
    };

    document.getElementById('auth-form')?.addEventListener('submit', (e) => {
      e.preventDefault();
      handleAuthSubmit();
    });

    document.getElementById('btn-auth-submit')?.addEventListener('click', (e) => {
      e.preventDefault();
      handleAuthSubmit();
    });

    // Clear alert when user types
    document.querySelectorAll('.auth-input').forEach(input => {
      input.addEventListener('input', () => clearAlert());
    });

    // Google Sign-in button
    document.getElementById('btn-google-signin')?.addEventListener('click', async () => {
      clearAlert();
      if (typeof Auth !== 'undefined' && Auth.isFirebaseActive) {
        try {
          const user = await Auth.loginWithGoogle();
          if (user) {
            this.showToast(`Signed in with Google as ${user.username}!`);
            this.showScreen('mode-selection');
            this.checkAndShowWelcomeBonus(user);
          }
        } catch (err) {
          showAlert(err.message, true);
        }
      } else {
        // Open Google login modal to capture Gmail & preferred username
        const modal = document.getElementById('google-auth-modal');
        if (modal) modal.classList.add('active');
      }
    });

    // Google modal actions
    document.getElementById('btn-confirm-google-login')?.addEventListener('click', async () => {
      const email = document.getElementById('google-input-email')?.value || '';
      const username = document.getElementById('google-input-username')?.value || '';
      try {
        const user = await Auth.loginWithGoogle(email, username);
        if (user) {
          document.getElementById('google-auth-modal')?.classList.remove('active');
          this.showToast(`Signed in with Google as ${user.username}!`);
          this.showScreen('mode-selection');
          this.checkAndShowWelcomeBonus(user);
        }
      } catch (err) {
        alert(err.message);
      }
    });

    document.getElementById('btn-cancel-google-modal')?.addEventListener('click', () => {
      document.getElementById('google-auth-modal')?.classList.remove('active');
    });

    // Guest button
    document.getElementById('btn-guest-play')?.addEventListener('click', async () => {
      const guest = await Auth.loginAsGuest();
      this.showToast('Playing as Guest!');
      this.showScreen('mode-selection');
      this.checkAndShowWelcomeBonus(guest);
    });

    // Welcome Bonus Claim & Close buttons
    document.getElementById('btn-claim-welcome-bonus')?.addEventListener('click', () => {
      this.claimWelcomeBonus();
    });

    document.getElementById('btn-close-welcome-bonus')?.addEventListener('click', () => {
      this.closeWelcomeBonusModal();
    });

    document.getElementById('welcome-bonus-overlay')?.addEventListener('click', (e) => {
      if (e.target && e.target.id === 'welcome-bonus-overlay') {
        this.closeWelcomeBonusModal();
      }
    });

    // Profile modal
    document.getElementById('btn-user-profile')?.addEventListener('click', () => {
      this.openUserProfileModal();
    });

    document.getElementById('btn-close-profile-modal')?.addEventListener('click', () => {
      document.getElementById('user-profile-modal')?.classList.remove('active');
    });

    document.getElementById('btn-logout-profile')?.addEventListener('click', async () => {
      document.getElementById('user-profile-modal')?.classList.remove('active');
      await Auth.logout();
      this.showToast('Logged out.');
      this.showScreen('auth-screen');
    });

    // Listen for auth changes
    if (typeof Auth !== 'undefined') {
      Auth.onAuthStateChanged((user) => {
        this.updateUserProfileDisplay(user);
      });
    }
  },

  updateUserProfileDisplay(user) {
    const avatarEl = document.getElementById('header-user-avatar');
    const nameEl = document.getElementById('header-user-name');
    if (!nameEl) return;

    if (user) {
      nameEl.textContent = user.username || 'Player';
      if (avatarEl) {
        avatarEl.textContent = user.avatar || '🦊';
      }
    } else {
      nameEl.textContent = 'Login';
      if (avatarEl) avatarEl.textContent = '👤';
    }
  },

  openUserProfileModal() {
    const user = typeof Auth !== 'undefined' ? Auth.currentUser : null;
    if (!user) {
      this.showScreen('auth-screen');
      return;
    }

    const modal = document.getElementById('user-profile-modal');
    if (!modal) return;

    const usernameEl = document.getElementById('profile-modal-username');
    const emailEl = document.getElementById('profile-modal-email');
    const providerEl = document.getElementById('profile-modal-provider');
    const coinsEl = document.getElementById('profile-modal-coins');
    const avatarEl = document.getElementById('profile-modal-avatar');

    if (usernameEl) usernameEl.textContent = user.username;
    if (emailEl) emailEl.textContent = user.isGuest ? 'Guest Session' : (user.email || 'No email attached');
    if (providerEl) {
      providerEl.textContent = user.provider === 'google' ? 'Google (Gmail)' : (user.isGuest ? 'Guest' : 'Username & Password');
    }
    if (coinsEl) coinsEl.textContent = `${this.coins} 🪙`;
    if (avatarEl) {
      avatarEl.textContent = user.avatar || '🦊';
    }

    // Mark current avatar as selected in profile modal
    document.querySelectorAll('#profile-avatar-picker .avatar-pill').forEach(btn => {
      btn.classList.toggle('selected', btn.dataset.avatar === (user.avatar || '🦊'));
    });

    modal.classList.add('active');
  },

  // ── Welcome Bonus Popup (200 Coins for First-Time Sign In) ──
  checkAndShowWelcomeBonus(user) {
    if (!user) return;
    const uid = user.uid || 'guest';
    if (typeof Auth !== 'undefined' && Auth.isWelcomeBonusClaimed(uid)) {
      return; // Already claimed before!
    }

    const overlay = document.getElementById('welcome-bonus-overlay');
    if (!overlay) return;
    if (overlay.classList.contains('active') || this._isClaimingBonus) return;

    const usernameEl = document.getElementById('welcome-bonus-username');
    if (usernameEl) {
      usernameEl.textContent = user.username || 'Explorer';
    }

    const amountEl = document.getElementById('welcome-bonus-amount');
    if (amountEl) {
      amountEl.textContent = '200';
    }

    // Delay slightly so the screen transition completes smoothly first
    setTimeout(() => {
      if (typeof Auth !== 'undefined' && Auth.isWelcomeBonusClaimed(uid)) return;
      overlay.classList.add('active');
      this.playSound('found');
    }, 400);
  },

  closeWelcomeBonusModal() {
    const overlay = document.getElementById('welcome-bonus-overlay');
    if (overlay) overlay.classList.remove('active');
    this._isClaimingBonus = false;
  },

  async claimWelcomeBonus() {
    if (this._isClaimingBonus) return;
    this._isClaimingBonus = true;

    const overlay = document.getElementById('welcome-bonus-overlay');
    const claimBtn = document.getElementById('btn-claim-welcome-bonus');
    if (claimBtn) {
      claimBtn.disabled = true;
      claimBtn.innerHTML = '<span>✨</span> Claimed!';
    }

    try {
      const user = (typeof Auth !== 'undefined' && Auth.currentUser)
        ? Auth.currentUser
        : { uid: 'guest', username: 'Explorer' };
      const uid = user.uid || 'guest';

      // 1. One-time welcome bonus guarantee:
      // Ensure coins is set to exactly 200 (if excess coins accumulated from the repeated click bug, cap at 200)
      const currentCoins = await GameDB.getCoins();
      if (currentCoins < 200) {
        await GameDB.setCoins(200);
      } else {
        const totalCompleted = await GameDB.getTotalCompletedLevels();
        if (totalCompleted === 0) {
          await GameDB.setCoins(200);
        }
      }
      this.coins = await GameDB.getCoins();

      // 2. Mark welcome bonus as claimed immediately in local storage & user record
      if (typeof Auth !== 'undefined') {
        await Auth.markWelcomeBonusClaimed(uid, this.coins);
        try {
          if (typeof Auth.syncToFirestore === 'function') {
            const totalStars = await GameDB.getTotalStars();
            const totalLevels = await GameDB.getTotalCompletedLevels();
            await Auth.syncToFirestore(totalStars, totalLevels, this.coins, true);
          }
        } catch (syncErr) {
          console.warn('[Sync] Non-blocking Firestore sync warning:', syncErr);
        }
      }

      this.updateCoinsDisplay();
      this.playSound('complete');
      this.showToast('🎉 200 Welcome Bonus Coins added to your balance!');

      // Animate coin display badges
      document.querySelectorAll('.coin-display').forEach(el => {
        el.classList.add('coin-bump-anim');
        setTimeout(() => el.classList.remove('coin-bump-anim'), 1000);
      });
    } catch (err) {
      console.error('Error in claimWelcomeBonus:', err);
    } finally {
      // 3. ALWAYS dismiss the overlay safely and reset flag so screen is NEVER stuck!
      setTimeout(() => {
        if (overlay) overlay.classList.remove('active');
        if (claimBtn) {
          claimBtn.disabled = false;
          claimBtn.innerHTML = '<span>🎁</span> Claim 200 Coins';
        }
        this._isClaimingBonus = false;
      }, 350);
    }
  },

  // ── Leaderboard Management ──────────────────────────────────
  async openLeaderboard() {
    this.showScreen('leaderboard-screen');
    await this.renderLeaderboard();
  },

  async renderLeaderboard() {
    const totalStars = await GameDB.getTotalStars();
    const totalLevels = await GameDB.getTotalCompletedLevels();
    const currentUser = (typeof Auth !== 'undefined' && Auth.currentUser)
      ? Auth.currentUser
      : null;
    const canRank = !!(currentUser && !currentUser.isGuest && Auth.isFirebaseActive);
    const esc = value => String(value ?? '').replace(/[&<>"']/g, ch => ({
      '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
    })[ch]);

    let firestorePlayers = [];
    let loadFailed = false;
    if (typeof Auth !== 'undefined' && Auth.isFirebaseActive) {
      const remote = await Auth.fetchLeaderboardFromFirestore();
      if (remote) firestorePlayers = remote;
      else loadFailed = true;
    }

    const all = firestorePlayers
      .filter(c => !(canRank && c.uid === currentUser.uid))
      .map(c => ({
        uid: c.uid,
        username: c.username,
        stars: Number(c.stars) || 0,
        levels: Number(c.levels) || 0,
        avatar: c.avatar || '🦊',
        isMe: false
      }));

    if (canRank) {
      all.push({
        uid: currentUser.uid,
        username: currentUser.username || 'You',
        stars: totalStars,
        levels: totalLevels,
        avatar: currentUser.avatar || '🦊',
        isMe: true
      });
    }

    all.sort((a, b) => {
      if (b.stars !== a.stars) return b.stars - a.stars;
      if (b.levels !== a.levels) return b.levels - a.levels;
      return String(a.uid).localeCompare(String(b.uid));
    });

    all.forEach((item, idx) => item.rank = idx + 1);

    const podiumContainer = document.getElementById('podium-container');
    if (podiumContainer && all.length >= 3) {
      const first = all[0];
      const second = all[1];
      const third = all[2];

      podiumContainer.innerHTML = `
        <!-- 2nd Place -->
        <div class="podium-col podium-silver">
          <div class="podium-avatar-wrap">
            <div class="podium-avatar">${esc(second.avatar)}</div>
            <span class="podium-crown">🥈</span>
          </div>
          <span class="podium-name">${second.isMe ? 'YOU' : esc(second.username)}</span>
          <span class="podium-stars-badge">⭐ ${second.stars}</span>
          <div class="podium-pillar">#2</div>
        </div>

        <!-- 1st Place -->
        <div class="podium-col podium-gold">
          <div class="podium-avatar-wrap">
            <div class="podium-avatar">${esc(first.avatar)}</div>
            <span class="podium-crown">👑</span>
          </div>
          <span class="podium-name">${first.isMe ? 'YOU' : esc(first.username)}</span>
          <span class="podium-stars-badge">⭐ ${first.stars}</span>
          <div class="podium-pillar">#1</div>
        </div>

        <!-- 3rd Place -->
        <div class="podium-col podium-bronze">
          <div class="podium-avatar-wrap">
            <div class="podium-avatar">${esc(third.avatar)}</div>
            <span class="podium-crown">🥉</span>
          </div>
          <span class="podium-name">${third.isMe ? 'YOU' : esc(third.username)}</span>
          <span class="podium-stars-badge">⭐ ${third.stars}</span>
          <div class="podium-pillar">#3</div>
        </div>
      `;
    } else if (podiumContainer) {
      podiumContainer.innerHTML = '';
    }

    const listContainer = document.getElementById('leaderboard-list');
    if (listContainer) {
      const rest = all.length >= 3 ? all.slice(3) : all;
      const empty = loadFailed
        ? 'Leaderboard unavailable. Check your connection.'
        : 'No ranked players yet.';
      listContainer.innerHTML = all.length === 0
        ? `<div class="leaderboard-item"><span>${empty}</span></div>`
        : rest.map(item => `
        <div class="leaderboard-item ${item.isMe ? 'me' : ''}">
          <span class="leaderboard-rank-pill">#${item.rank}</span>
          <div class="leaderboard-user-avatar">${esc(item.avatar)}</div>
          <div class="leaderboard-user-info">
            <div class="leaderboard-user-name">
              <span>${esc(item.username)}</span>
              ${item.isMe ? '<span class="leaderboard-you-tag">YOU</span>' : ''}
            </div>
            <span class="leaderboard-user-levels">${item.levels} levels cleared</span>
          </div>
          <div class="leaderboard-stars-pill">
            <span>⭐</span>
            <span>${item.stars}</span>
          </div>
        </div>
      `).join('');
    }

    const playerBar = document.getElementById('leaderboard-player-bar');
    const myRankItem = all.find(item => item.isMe);
    if (playerBar && !myRankItem) {
      playerBar.innerHTML = `
        <div class="player-bar-info">
          <div class="player-bar-title">Not ranked</div>
          <div class="player-bar-sub">Sign in to appear on the global leaderboard.</div>
        </div>
      `;
    }
    if (playerBar && myRankItem) {
      const isTop = myRankItem.rank === 1;
      let nextNotice = 'Play levels to climb up the ranks!';
      if (!isTop && myRankItem.rank > 1) {
        const above = all[myRankItem.rank - 2];
        const needed = (above.stars - myRankItem.stars) + 1;
        nextNotice = `⭐ Need ${needed} more stars to beat ${esc(above.username)}!`;
      } else if (isTop) {
        nextNotice = '👑 You are #1 Leader of the World!';
      }

      playerBar.innerHTML = `
        <div class="player-bar-rank-badge">#${myRankItem.rank}</div>
        <div class="player-bar-info">
          <div class="player-bar-title">Your Standing: #${myRankItem.rank} (${esc(myRankItem.username)})</div>
        </div>
        <div class="leaderboard-stars-pill">
          <span>⭐</span>
          <span>${myRankItem.stars}</span>
        </div>
      `;
    }
  },

  // ══════════════════════════════════════════════════════════
  // LEVEL SELECTION
  // ══════════════════════════════════════════════════════════

  async openLevelSelection(mode) {
    const modeNames = { english: 'English', hindi: 'Hindi', master: 'Duo' };
    const modeIcons = { english: 'Aa', hindi: 'अ', master: '👑' };

    document.getElementById('level-mode-title').innerHTML =
      `<span class="mode-icon">${modeIcons[mode]}</span> ${modeNames[mode]} Levels`;

    await this.renderLevels(mode);
    this.showScreen('level-selection');
  },

  async renderLevels(mode) {
    const container = document.getElementById('levels-container');
    container.innerHTML = '';

    const allProgress = await GameDB.getAllProgress(mode);
    const progressMap = {};
    allProgress.forEach(p => { progressMap[p.level] = p; });

    for (let level = 1; level <= WORD_DATA.totalLevels; level++) {
      const progress = progressMap[level];
      const isUnlocked = level === 1 || progressMap[level - 1]?.completed;

      const card = Utils.createElement('div', {
        className: `level-card ${progress?.completed ? 'completed' : ''} ${isUnlocked && !progress?.completed ? 'current' : ''} ${!isUnlocked ? 'locked' : ''}`,
        dataset: { level: level.toString() },
        onClick: () => {
          if (isUnlocked) this.startGame(mode, level);
        }
      });

      if (isUnlocked) {
        // Level number
        card.appendChild(Utils.createElement('div', {
          className: 'level-number',
          textContent: level.toString()
        }));

        // Stars
        const starsDiv = Utils.createElement('div', { className: 'level-stars' });
        for (let s = 1; s <= 3; s++) {
          starsDiv.appendChild(Utils.createElement('span', {
            className: `star ${progress && s <= progress.stars ? 'earned' : ''}`,
            textContent: '★'
          }));
        }
        card.appendChild(starsDiv);
      } else {
        // Lock icon
        card.appendChild(Utils.createElement('div', {
          className: 'level-number',
          textContent: level.toString()
        }));
        card.appendChild(Utils.createElement('div', {
          className: 'lock-icon',
          textContent: '🔒'
        }));
      }

      container.appendChild(card);
    }
  },

  // ══════════════════════════════════════════════════════════
  // GAME ENGINE
  // ══════════════════════════════════════════════════════════

  async startGame(mode, level) {
    this.currentMode = mode;
    this.currentLevel = level;

    // Get words and grid config
    const gridWords = WORD_DATA.getGridWords(mode, level);
    const clues = WORD_DATA.getClues(mode, level);
    const { rows, cols } = WORD_DATA.getGridSize(level);

    // Generate grid
    const isHindi = mode === 'hindi';
    const { grid, placements } = GridGenerator.generate(gridWords, rows, cols, isHindi);

    // Init game state
    this.gameState = {
      mode,
      level,
      grid,
      placements,
      clues,
      rows,
      cols,
      foundWords: [],
      totalWords: gridWords.length,
      timeElapsed: 0,
      hintsUsed: 0,
      isSelecting: false,
      selectedCells: [],
      startCell: null,
    };

    // Update header
    const modeNames = { english: 'English', hindi: 'Hindi', master: 'Duo' };
    const modeIcons = { english: 'Aa', hindi: 'अ', master: '👑' };
    document.getElementById('game-mode-title').innerHTML =
      `${modeNames[mode]} - Level ${level} <span style="margin-left:4px">${modeIcons[mode]}</span>`;

    // Render everything
    this.renderClues();
    this.renderGrid();
    this.updateGameInfo();
    this.updateHintBadge();

    // Start timer
    this.startTimer();

    // Show game screen
    this.showScreen('game-screen');
  },

  // ── Render Clues ───────────────────────────────────────────
  renderClues() {
    const { clues, mode } = this.gameState;
    const container = document.getElementById('clue-words');
    container.innerHTML = '';

    const titleEl = document.getElementById('clue-title');
    if (mode === 'master') {
      titleEl.textContent = 'Find the meaning of these Hindi words:';
    } else if (mode === 'english') {
      titleEl.textContent = 'Find these words in the grid:';
    } else {
      titleEl.textContent = 'Find these Hindi words in the grid:';
    }

    clues.forEach(clue => {
      const el = Utils.createElement('span', {
        className: 'clue-word',
        textContent: clue.display,
        dataset: { answer: clue.answer }
      });
      container.appendChild(el);
    });
  },

  // ── Render Grid ────────────────────────────────────────────
  renderGrid() {
    const { grid, rows, cols } = this.gameState;
    const container = document.getElementById('word-grid');
    container.innerHTML = '';

    // Calculate fluid responsive cell size
    const availableWidth = Math.min(window.innerWidth - 32, 400);
    const gap = 3;
    const computedCell = Math.floor((availableWidth - (cols + 1) * gap - 8) / cols);
    const cellSize = Math.min(44, Math.max(26, computedCell));
    container.style.setProperty('--cell-size', `${cellSize}px`);
    container.style.gridTemplateColumns = `repeat(${cols}, ${cellSize}px)`;
    container.style.gridTemplateRows = `repeat(${rows}, ${cellSize}px)`;

    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        const cell = Utils.createElement('div', {
          className: 'grid-cell',
          textContent: grid[r][c],
          dataset: { row: r.toString(), col: c.toString() }
        });

        // Touch/mouse events for selection
        cell.addEventListener('pointerdown', (e) => this.onCellPointerDown(e, r, c));
        cell.addEventListener('pointerenter', (e) => this.onCellPointerEnter(e, r, c));
        cell.addEventListener('pointerup', (e) => this.onCellPointerUp(e));

        container.appendChild(cell);
      }
    }

    // Global pointer up to handle edge cases
    document.addEventListener('pointerup', () => {
      if (this.gameState?.isSelecting) {
        this.checkSelection();
        this.gameState.isSelecting = false;
      }
    }, { once: false });
  },

  // ── Cell Selection Handlers ────────────────────────────────
  onCellPointerDown(e, row, col) {
    e.preventDefault();
    if (!this.gameState) return;

    this.gameState.isSelecting = true;
    this.gameState.startCell = { row, col };
    this.gameState.selectedCells = [{ row, col }];
    this.updateSelectionVisuals();
  },

  onCellPointerEnter(e, row, col) {
    if (!this.gameState?.isSelecting) return;
    e.preventDefault();

    const start = this.gameState.startCell;
    if (!start) return;

    // Calculate direction from start to current
    const dr = Math.sign(row - start.row);
    const dc = Math.sign(col - start.col);

    // Must be in a valid direction (horizontal, vertical, or diagonal)
    const rowDiff = Math.abs(row - start.row);
    const colDiff = Math.abs(col - start.col);

    const isHorizontal = (rowDiff === 0 && colDiff > 0);
    const isVertical = (colDiff === 0 && rowDiff > 0);
    const isDiagonal = (rowDiff === colDiff && rowDiff > 0);

    const isValid = isHorizontal || isVertical || isDiagonal;
    if (!isValid) return;

    // Strict horizontal constraint: never allow dragging/selecting right-to-left
    if (isHorizontal && dc < 0) return;

    // Build cells along the line
    const cells = [];
    const length = Math.max(rowDiff, colDiff);
    for (let i = 0; i <= length; i++) {
      cells.push({
        row: start.row + i * dr,
        col: start.col + i * dc
      });
    }

    this.gameState.selectedCells = cells;
    this.updateSelectionVisuals();
  },

  onCellPointerUp(e) {
    if (!this.gameState?.isSelecting) return;
    e.preventDefault();
    this.checkSelection();
    this.gameState.isSelecting = false;
  },

  updateSelectionVisuals() {
    // Clear all selecting
    document.querySelectorAll('.grid-cell.selecting').forEach(el => {
      el.classList.remove('selecting');
    });

    // Highlight selected
    for (const { row, col } of this.gameState.selectedCells) {
      const cell = document.querySelector(
        `.grid-cell[data-row="${row}"][data-col="${col}"]`
      );
      if (cell && !cell.classList.contains('found')) {
        cell.classList.add('selecting');
      }
    }
  },

  // ── Check Selection Against Words ──────────────────────────
  checkSelection() {
    const { selectedCells, placements, foundWords } = this.gameState;
    if (selectedCells.length < 2) {
      this.clearSelectionVisuals();
      return;
    }

    // Build selected word
    const selectedWord = selectedCells.map(({ row, col }) =>
      this.gameState.grid[row][col]
    ).join('');

    // Check against placements
    let matched = false;
    for (const placement of placements) {
      if (foundWords.includes(placement.word)) continue;

      // Check forward match
      const placementWord = placement.cells.map(c => c.letter).join('');
      
      // Check if selected cells match placement cells
      if (selectedCells.length === placement.cells.length) {
        const isHorizontal = placement.cells.length > 1 && 
          placement.cells[0].row === placement.cells[placement.cells.length - 1].row;

        const forwardMatch = selectedCells.every((sc, i) =>
          sc.row === placement.cells[i].row && sc.col === placement.cells[i].col
        );
        // Strict horizontal constraint: do not allow reverse/right-to-left match for horizontal words
        const reverseMatch = !isHorizontal && selectedCells.every((sc, i) => {
          const ri = placement.cells.length - 1 - i;
          return sc.row === placement.cells[ri].row && sc.col === placement.cells[ri].col;
        });

        if (forwardMatch || reverseMatch) {
          this.wordFound(placement);
          matched = true;
          break;
        }
      }
    }

    if (!matched) {
      // Shake animation for wrong selection
      this.gameState.selectedCells.forEach(({ row, col }) => {
        const cell = document.querySelector(
          `.grid-cell[data-row="${row}"][data-col="${col}"]`
        );
        if (cell) cell.classList.add('shake');
        setTimeout(() => cell?.classList.remove('shake'), 400);
      });
    }

    this.clearSelectionVisuals();
  },

  clearSelectionVisuals() {
    document.querySelectorAll('.grid-cell.selecting').forEach(el => {
      el.classList.remove('selecting');
    });
    if (this.gameState) {
      this.gameState.selectedCells = [];
    }
  },

  // ── Word Found ─────────────────────────────────────────────
  wordFound(placement) {
    const { foundWords, clues } = this.gameState;
    foundWords.push(placement.word);

    // Get highlight color
    const colorIndex = foundWords.length - 1;
    const color = Utils.getHighlightColor(colorIndex);

    // Highlight cells
    placement.cells.forEach((cell, i) => {
      const el = document.querySelector(
        `.grid-cell[data-row="${cell.row}"][data-col="${cell.col}"]`
      );
      if (el) {
        el.classList.add('found', 'found-animate');
        el.style.backgroundColor = color;
        el.style.animationDelay = `${i * 50}ms`;
      }
    });

    // Mark clue as found
    const clueEl = document.querySelector(
      `.clue-word[data-answer="${placement.word}"]`
    );
    if (clueEl) {
      clueEl.classList.add('found');
    }

    // Update progress
    this.updateGameInfo();

    // Haptic feedback & audio chime
    Utils.vibrate(50);
    this.playSound('found');

    // Show toast
    this.showToast(`Found: ${placement.word}! 🎉`);

    // Check if all words found
    if (foundWords.length === this.gameState.totalWords) {
      setTimeout(() => this.levelComplete(), 800);
    }
  },

  // ── Timer ──────────────────────────────────────────────────
  startTimer() {
    if (this.timerInterval) clearInterval(this.timerInterval);

    this.gameState.timeElapsed = 0;
    this.timerInterval = setInterval(() => {
      this.gameState.timeElapsed++;
      document.getElementById('game-timer-value').textContent =
        Utils.formatTime(this.gameState.timeElapsed);
    }, 1000);
  },

  // ── Update Game Info ───────────────────────────────────────
  updateGameInfo() {
    const { foundWords, totalWords } = this.gameState;
    document.getElementById('game-progress-value').textContent =
      `${foundWords.length}/${totalWords}`;
  },

  // ── Hint (Costs 30 coins) ──────────────────────────────────
  async showHint() {
    if (!this.gameState) return;

    const { clues, foundWords } = this.gameState;

    // Find first unfound word
    const unfoundClue = clues.find(c => !foundWords.includes(c.answer));
    if (!unfoundClue) {
      this.showToast('All words already found! 🌟');
      return;
    }

    const currentCoins = await GameDB.getCoins();
    if (currentCoins < GameDB.HINT_COST) {
      // Coins < 30: Do not allow hint purchase using coins. Trigger insufficient coins modal!
      this.openInsufficientCoinsModal(unfoundClue);
      return;
    }

    // Coins >= 30: Deduct 30 coins immediately
    const spent = await GameDB.spendCoins(GameDB.HINT_COST);
    if (!spent) {
      this.openInsufficientCoinsModal(unfoundClue);
      return;
    }

    this.coins = await GameDB.getCoins();
    this.updateCoinsDisplay();
    this.gameState.hintsUsed++;

    this.revealHint(unfoundClue);
    this.showToast('Hint unlocked! (-30 🪙)');
  },

  openInsufficientCoinsModal(targetClue = null) {
    this._pendingHintClue = targetClue;
    const coinsEl = document.getElementById('modal-current-coins');
    if (coinsEl) coinsEl.textContent = this.coins;
    document.getElementById('insufficient-coins-overlay')?.classList.add('active');
  },

  closeInsufficientCoinsModal() {
    document.getElementById('insufficient-coins-overlay')?.classList.remove('active');
  },

  async watchRewardedAd() {
    this.closeInsufficientCoinsModal();

    const adOverlay = document.getElementById('ad-simulator-overlay');
    const countdownEl = document.getElementById('ad-countdown');
    const progressBar = document.getElementById('ad-progress-bar');
    const statusText = document.getElementById('ad-status-text');

    if (!adOverlay) return;

    adOverlay.classList.add('active');
    if (progressBar) progressBar.style.width = '0%';
    if (statusText) statusText.textContent = 'Watching ad for hint & +50 bonus coins...';

    let secondsLeft = 3;
    if (countdownEl) countdownEl.textContent = `Ad: ${secondsLeft}s`;

    const timer = setInterval(() => {
      secondsLeft--;
      if (countdownEl) countdownEl.textContent = `Ad: ${Math.max(0, secondsLeft)}s`;
      const pct = ((3 - secondsLeft) / 3) * 100;
      if (progressBar) progressBar.style.width = `${pct}%`;

      if (secondsLeft <= 0) {
        clearInterval(timer);
        setTimeout(async () => {
          adOverlay.classList.remove('active');

          // Award 50 bonus coins
          await GameDB.addCoins(50);
          this.coins = await GameDB.getCoins();
          this.updateCoinsDisplay();

          this.showToast('🎉 Ad reward received! +50 Coins earned.');

          // If triggered while trying to get a hint, unlock the hint now
          if (this._pendingHintClue && this.gameState) {
            // Deduct 30 coins for the hint
            await GameDB.useHint();
            this.coins = await GameDB.getCoins();
            this.updateCoinsDisplay();
            this.gameState.hintsUsed++;
            this.revealHint(this._pendingHintClue);
            this._pendingHintClue = null;
          }
        }, 300);
      }
    }, 1000);
  },

  revealHint(unfoundClue) {
    const { mode } = this.gameState;

    // Show hint popup
    if (mode === 'master') {
      document.getElementById('hint-hindi-word').textContent = unfoundClue.display;
      document.getElementById('hint-english-word').textContent = unfoundClue.answer;
      document.getElementById('hint-meaning-label').style.display = 'block';
    } else {
      document.getElementById('hint-hindi-word').textContent = unfoundClue.display;
      document.getElementById('hint-english-word').textContent = unfoundClue.answer;
      document.getElementById('hint-meaning-label').style.display = 'none';
    }

    document.getElementById('hint-overlay')?.classList.add('active');
    this.playSound('hint');

    // Reveal starting letter/cell and target word highlight on the grid
    const placement = this.gameState.placements.find(p => p.word === unfoundClue.answer);
    if (placement && placement.cells.length > 0) {
      const startCell = placement.cells[0];
      const startEl = document.querySelector(
        `.grid-cell[data-row="${startCell.row}"][data-col="${startCell.col}"]`
      );
      if (startEl) {
        startEl.style.transform = 'scale(1.2)';
        startEl.style.boxShadow = '0 0 20px #f1c40f';
        startEl.style.zIndex = '5';
      }

      placement.cells.forEach(cell => {
        const el = document.querySelector(
          `.grid-cell[data-row="${cell.row}"][data-col="${cell.col}"]`
        );
        if (el && !el.classList.contains('found')) {
          el.style.backgroundColor = 'rgba(241, 196, 15, 0.45)';
          el.style.borderColor = '#f1c40f';
          setTimeout(() => {
            if (!el.classList.contains('found')) {
              el.style.backgroundColor = '';
              el.style.borderColor = '';
              el.style.transform = '';
              el.style.boxShadow = '';
              el.style.zIndex = '';
            }
          }, 3500);
        }
      });
    }
  },

  closeHint() {
    document.getElementById('hint-overlay')?.classList.remove('active');
  },

  updateHintBadge() {
    const badge = document.getElementById('hint-badge');
    if (badge) badge.textContent = `${GameDB.HINT_COST}🪙`;
  },

  // ── Clear Selection ────────────────────────────────────────
  clearSelection() {
    this.clearSelectionVisuals();
    this.showToast('Selection cleared');
  },

  // ── Shuffle Grid ───────────────────────────────────────────
  shuffleGrid() {
    if (!this.gameState) return;

    const { placements, rows, cols, mode } = this.gameState;
    const isHindi = mode === 'hindi';
    this.gameState.grid = GridGenerator.shuffleGrid(
      this.gameState.grid, placements, rows, cols, isHindi
    );

    // Re-render grid preserving found words
    this.renderGrid();

    // Re-apply found highlights
    this.gameState.foundWords.forEach((word, index) => {
      const placement = placements.find(p => p.word === word);
      if (placement) {
        const color = Utils.getHighlightColor(index);
        placement.cells.forEach(cell => {
          const el = document.querySelector(
            `.grid-cell[data-row="${cell.row}"][data-col="${cell.col}"]`
          );
          if (el) {
            el.classList.add('found');
            el.style.backgroundColor = color;
          }
        });
      }
    });

    this.showToast('Grid shuffled! 🔀');
  },

  // ══════════════════════════════════════════════════════════
  // LEVEL COMPLETE
  // ══════════════════════════════════════════════════════════

  async levelComplete() {
    clearInterval(this.timerInterval);
    this.playSound('complete');

    const { timeElapsed, hintsUsed, totalWords, foundWords, mode, level } = this.gameState;

    const stars = Utils.calculateStars(timeElapsed, hintsUsed, totalWords);
    const coinsEarned = Utils.calculateCoins(stars, timeElapsed);

    // Save progress
    await GameDB.saveProgress(mode, level, stars, timeElapsed, coinsEarned);
    this.coins = await GameDB.getCoins();
    this.updateCoinsDisplay();

    // Minimum-use Firestore sync (throttled: only writes if stars increased!)
    if (typeof Auth !== 'undefined' && Auth.currentUser && !Auth.currentUser.isGuest) {
      GameDB.getTotalStars().then(totalStars => {
        GameDB.getTotalCompletedLevels().then(totalLevels => {
          Auth.syncToFirestore(totalStars, totalLevels, this.coins);
        });
      });
    }

    // Update UI
    document.getElementById('complete-time').textContent = Utils.formatTime(timeElapsed);
    document.getElementById('complete-words').textContent = `${foundWords.length}/${totalWords}`;
    document.getElementById('complete-coins').textContent = `+${coinsEarned}`;

    // Stars
    const starsContainer = document.getElementById('complete-stars');
    starsContainer.innerHTML = '';
    for (let i = 1; i <= 3; i++) {
      const star = Utils.createElement('span', {
        className: `star ${i <= stars ? 'earned' : ''}`,
        textContent: '★'
      });
      if (i <= stars) {
        star.style.animationDelay = `${i * 0.2}s`;
      }
      starsContainer.appendChild(star);
    }

    // Show confetti
    Utils.showConfetti(document.body);

    // Show overlay
    document.getElementById('level-complete-overlay').classList.add('active');
  },

  closeLevelComplete() {
    document.getElementById('level-complete-overlay').classList.remove('active');
  },

  nextLevel() {
    this.closeLevelComplete();
    const nextLevel = this.currentLevel + 1;
    if (nextLevel <= WORD_DATA.totalLevels) {
      this.startGame(this.currentMode, nextLevel);
    } else {
      this.showToast('🏆 You completed all levels!');
      this.showScreen('mode-selection');
    }
  },

  replayLevel() {
    this.closeLevelComplete();
    this.startGame(this.currentMode, this.currentLevel);
  },

  // ══════════════════════════════════════════════════════════
  // SETTINGS
  // ══════════════════════════════════════════════════════════

  async renderSettings() {
    this.soundEnabled = (await GameDB.getSetting('sound')) !== false;
    const soundToggle = document.getElementById('toggle-sound');
    if (soundToggle) soundToggle.checked = this.soundEnabled;

    const themeToggle = document.getElementById('toggle-theme');
    if (themeToggle) themeToggle.checked = this.theme === 'light';

    const settingsDesc = document.getElementById('settings-theme-desc');
    if (settingsDesc) {
      settingsDesc.textContent = this.theme === 'light' ? 'White mode active' : 'Dark mode active';
    }

    const settingsIcon = document.getElementById('settings-theme-icon');
    if (settingsIcon) {
      settingsIcon.textContent = this.theme === 'light' ? '☀️' : '🌙';
    }

    this.applyTheme(this.theme);
  },

  async resetProgress() {
    if (confirm('Are you sure? This will reset ALL your game progress, coins, and settings.')) {
      await GameDB.resetAll();
      this.coins = 0;
      this.theme = 'dark';
      this.applyTheme('dark');
      this.updateCoinsDisplay();
      this.showToast('Progress reset! 🔄');
      this.showScreen('mode-selection');
    }
  },

  // ══════════════════════════════════════════════════════════
  // TOAST NOTIFICATION
  // ══════════════════════════════════════════════════════════

  showToast(message, duration = 2000) {
    let toast = document.getElementById('app-toast');
    if (!toast) {
      toast = Utils.createElement('div', { className: 'toast', id: 'app-toast' });
      document.body.appendChild(toast);
    }
    toast.textContent = message;
    toast.classList.add('show');

    clearTimeout(this._toastTimer);
    this._toastTimer = setTimeout(() => {
      toast.classList.remove('show');
    }, duration);
  },
};

// ── Bootstrap ────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  App.init();
});
