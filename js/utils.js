// ============================================================
// utils.js — Utility Functions
// ============================================================

const Utils = {

  /**
   * Format seconds into MM:SS string
   */
  formatTime(totalSeconds) {
    const mins = Math.floor(totalSeconds / 60).toString().padStart(2, '0');
    const secs = (totalSeconds % 60).toString().padStart(2, '0');
    return `${mins}:${secs}`;
  },

  /**
   * Create a DOM element with attributes and children
   */
  createElement(tag, attrs = {}, children = []) {
    const el = document.createElement(tag);
    for (const [key, val] of Object.entries(attrs)) {
      if (key === 'className') {
        el.className = val;
      } else if (key === 'textContent') {
        el.textContent = val;
      } else if (key === 'innerHTML') {
        el.innerHTML = val;
      } else if (key.startsWith('on')) {
        el.addEventListener(key.slice(2).toLowerCase(), val);
      } else if (key === 'dataset') {
        for (const [dk, dv] of Object.entries(val)) {
          el.dataset[dk] = dv;
        }
      } else {
        el.setAttribute(key, val);
      }
    }
    for (const child of children) {
      if (typeof child === 'string') {
        el.appendChild(document.createTextNode(child));
      } else if (child) {
        el.appendChild(child);
      }
    }
    return el;
  },

  /**
   * Calculate star rating (1-3) based on time and hints
   */
  calculateStars(timeTaken, hintsUsed, totalWords) {
    // Base: 3 stars
    let stars = 3;
    
    // Time penalty: lose 1 star if over 3 minutes, 2 if over 5 minutes
    if (timeTaken > 300) stars -= 2;
    else if (timeTaken > 180) stars -= 1;
    
    // Hint penalty: lose 1 star if used more than 2 hints
    if (hintsUsed > 2) stars -= 1;
    
    return Math.max(1, Math.min(3, stars));
  },

  /**
   * Calculate coins earned based on performance
   */
  calculateCoins(stars, timeTaken) {
    const base = 10;
    const starBonus = stars * 5;
    const timeBonus = timeTaken < 120 ? 10 : timeTaken < 180 ? 5 : 0;
    return base + starBonus + timeBonus;
  },

  /**
   * Word highlight colors — rotate through these for found words
   */
  HIGHLIGHT_COLORS: [
    '#38bdf8', // Cyan / Sky
    '#2dd4bf', // Mint / Teal
    '#facc15', // Sunny Yellow
    '#a3e635', // Lime Green
    '#fb923c', // Coral / Salmon
    '#f472b6', // Pink / Rose
    '#c084fc', // Lavender / Purple
    '#f59e0b', // Amber / Gold
    '#60a5fa', // Soft Blue
    '#fb7185', // Soft Red
    '#10b981', // Emerald Green
    '#e879f9', // Fuchsia / Magenta
  ],

  /**
   * Get highlight color for nth found word
   */
  getHighlightColor(index) {
    return this.HIGHLIGHT_COLORS[index % this.HIGHLIGHT_COLORS.length];
  },

  /**
   * Vibrate device (mobile haptic feedback)
   */
  vibrate(ms = 50) {
    if (navigator.vibrate) {
      navigator.vibrate(ms);
    }
  },

  /**
   * Simple confetti burst (CSS animation based)
   */
  showConfetti(container) {
    const colors = ['#f1c40f', '#e74c3c', '#3498db', '#2ecc71', '#9b59b6', '#e67e22'];
    for (let i = 0; i < 30; i++) {
      const confetti = document.createElement('div');
      confetti.className = 'confetti-piece';
      confetti.style.left = Math.random() * 100 + '%';
      confetti.style.backgroundColor = colors[Math.floor(Math.random() * colors.length)];
      confetti.style.animationDelay = Math.random() * 0.5 + 's';
      confetti.style.animationDuration = (Math.random() * 1 + 1.5) + 's';
      container.appendChild(confetti);
      setTimeout(() => confetti.remove(), 3000);
    }
  },

  /**
   * Debounce function
   */
  debounce(fn, delay) {
    let timer;
    return (...args) => {
      clearTimeout(timer);
      timer = setTimeout(() => fn(...args), delay);
    };
  }
};
