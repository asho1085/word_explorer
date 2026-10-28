// ============================================================
// grid-generator.js — Word Search Grid Generation Algorithm
// ============================================================
// Places words in multiple directions and fills remaining
// cells with random letters. Supports 8 directions.
// ============================================================

const GridGenerator = {

  // Allowed directions:
  // - Horizontal words must ALWAYS start from left to right (dr: 0, dc: 1)
  // - Vertical words retain standard top-to-bottom flow (dr: 1, dc: 0)
  // - Diagonal words retain standard top-left to bottom-right flow (dr: 1, dc: 1)
  DIRECTIONS: [
    { dr: 0, dc: 1, name: 'right' },       // → Horizontal (Left to Right ONLY)
    { dr: 1, dc: 0, name: 'down' },        // ↓ Vertical (Top to Bottom)
    { dr: 1, dc: 1, name: 'down-right' },  // ↘ Diagonal (Top-Left to Bottom-Right)
  ],

  LETTERS: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
  HINDI_LETTERS: 'अआइईउऊऋएऐओऔकखगघचछजझटठडढणतथदधनपफबभमयरलवशषसह',

  getWordChars(word) {
    if (typeof Intl !== 'undefined' && Intl.Segmenter) {
      const segmenter = new Intl.Segmenter('hi', { granularity: 'grapheme' });
      return [...segmenter.segment(word)].map(s => s.segment);
    }
    return word.match(/[\u0900-\u097F][\u093E-\u094D\u0901-\u0903\u0951-\u0954\u0962-\u0963]*|[^\u0900-\u097F]/gu) || word.split('');
  },

  /**
   * Generate a complete word search grid
   * @param {string[]} words — Array of words to place
   * @param {number} rows — Number of rows
   * @param {number} cols — Number of columns
   * @param {boolean} [isHindi=false] — Whether Hindi mode
   * @returns {{ grid: string[][], placements: Object[] }}
   */
  generate(words, rows, cols, isHindi = false) {
    // Create empty grid
    const grid = Array.from({ length: rows }, () =>
      Array.from({ length: cols }, () => null)
    );

    const placements = [];

    // Sort words by grapheme count (longest first for better placement)
    const sortedWords = [...words].sort((a, b) => this.getWordChars(b).length - this.getWordChars(a).length);

    for (const word of sortedWords) {
      const placement = this.placeWord(grid, word, rows, cols);
      if (placement) {
        placements.push(placement);
      } else {
        console.warn(`Could not place word: ${word}`);
        // Try with a simpler direction (horizontal only)
        const fallback = this.placeWordSimple(grid, word, rows, cols);
        if (fallback) {
          placements.push(fallback);
        }
      }
    }

    // Fill empty cells with random letters
    this.fillEmpty(grid, rows, cols, isHindi);

    return { grid, placements };
  },

  /**
   * Try to place a word in the grid
   * @returns {Object|null} Placement info or null if failed
   */
  placeWord(grid, word, rows, cols, maxAttempts = 200) {
    const directions = this.shuffleArray([...this.DIRECTIONS]);

    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      const dir = directions[attempt % directions.length];
      const startRow = Math.floor(Math.random() * rows);
      const startCol = Math.floor(Math.random() * cols);

      if (this.canPlace(grid, word, startRow, startCol, dir, rows, cols)) {
        this.doPlace(grid, word, startRow, startCol, dir);
        return {
          word,
          startRow,
          startCol,
          direction: dir,
          cells: this.getCells(word, startRow, startCol, dir),
        };
      }
    }
    return null;
  },

  /**
   * Fallback: place word horizontally or vertically
   */
  placeWordSimple(grid, word, rows, cols) {
    const chars = this.getWordChars(word);
    // Try every position horizontally
    for (let r = 0; r < rows; r++) {
      for (let c = 0; c <= cols - chars.length; c++) {
        const dir = this.DIRECTIONS[0]; // right
        if (this.canPlace(grid, word, r, c, dir, rows, cols)) {
          this.doPlace(grid, word, r, c, dir);
          return {
            word,
            startRow: r,
            startCol: c,
            direction: dir,
            cells: this.getCells(word, r, c, dir),
          };
        }
      }
    }
    // Try every position vertically
    for (let r = 0; r <= rows - chars.length; r++) {
      for (let c = 0; c < cols; c++) {
        const dir = this.DIRECTIONS[1]; // down
        if (this.canPlace(grid, word, r, c, dir, rows, cols)) {
          this.doPlace(grid, word, r, c, dir);
          return {
            word,
            startRow: r,
            startCol: c,
            direction: dir,
            cells: this.getCells(word, r, c, dir),
          };
        }
      }
    }
    return null;
  },

  /**
   * Check if a word can be placed at given position/direction
   */
  canPlace(grid, word, startRow, startCol, dir, rows, cols) {
    // Strict horizontal constraint: Horizontal words must ALWAYS be left-to-right (dr: 0, dc: 1)
    if (dir.dr === 0 && dir.dc !== 1) return false;

    const chars = this.getWordChars(word);
    for (let i = 0; i < chars.length; i++) {
      const r = startRow + i * dir.dr;
      const c = startCol + i * dir.dc;

      // Out of bounds
      if (r < 0 || r >= rows || c < 0 || c >= cols) return false;

      // Cell occupied with different letter
      if (grid[r][c] !== null && grid[r][c] !== chars[i]) return false;
    }
    return true;
  },

  /**
   * Place a word in the grid
   */
  doPlace(grid, word, startRow, startCol, dir) {
    const chars = this.getWordChars(word);
    for (let i = 0; i < chars.length; i++) {
      const r = startRow + i * dir.dr;
      const c = startCol + i * dir.dc;
      grid[r][c] = chars[i];
    }
  },

  /**
   * Get cell coordinates for a placed word
   */
  getCells(word, startRow, startCol, dir) {
    const cells = [];
    const chars = this.getWordChars(word);
    for (let i = 0; i < chars.length; i++) {
      cells.push({
        row: startRow + i * dir.dr,
        col: startCol + i * dir.dc,
        letter: chars[i],
      });
    }
    return cells;
  },

  /**
   * Fill remaining null cells with random letters
   */
  fillEmpty(grid, rows, cols, isHindi = false) {
    const alphabet = isHindi ? this.HINDI_LETTERS : this.LETTERS;
    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        if (grid[r][c] === null) {
          grid[r][c] = alphabet[Math.floor(Math.random() * alphabet.length)];
        }
      }
    }
  },

  /**
   * Shuffle array (Fisher-Yates)
   */
  shuffleArray(arr) {
    for (let i = arr.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [arr[i], arr[j]] = [arr[j], arr[i]];
    }
    return arr;
  },

  /**
   * Shuffle the grid letters (keeping word positions)
   * Returns a new grid with non-word cells randomized
   */
  shuffleGrid(currentGrid, placements, rows, cols, isHindi = false) {
    const newGrid = currentGrid.map(row => [...row]);
    const alphabet = isHindi ? this.HINDI_LETTERS : this.LETTERS;
    
    // Collect word cell positions
    const wordCells = new Set();
    for (const p of placements) {
      for (const cell of p.cells) {
        wordCells.add(`${cell.row},${cell.col}`);
      }
    }
    
    // Re-randomize non-word cells
    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        if (!wordCells.has(`${r},${c}`)) {
          newGrid[r][c] = alphabet[Math.floor(Math.random() * alphabet.length)];
        }
      }
    }
    
    return newGrid;
  }
};
