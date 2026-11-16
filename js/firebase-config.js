// ============================================================
// firebase-config.js — Firebase Configuration
// ============================================================
// Connected to your live Firebase project: word-explorer-8ca65
// ============================================================

window.FIREBASE_CONFIG = {
  apiKey: "AIzaSyAbBd5w9rUQ8iu78ufUNeJmvIT0yNNMp28",
  authDomain: "word-explorer-8ca65.firebaseapp.com",
  projectId: "word-explorer-8ca65",
  storageBucket: "word-explorer-8ca65.firebasestorage.app",
  messagingSenderId: "462304291385",
  appId: "1:462304291385:web:d1fdf5f8c6cb9d14357be8",
  measurementId: "G-JBRXT1L1TQ"
};

// Returns true if valid Firebase configuration has been provided
window.isFirebaseConfigured = function() {
  return window.FIREBASE_CONFIG &&
    window.FIREBASE_CONFIG.apiKey &&
    window.FIREBASE_CONFIG.apiKey.trim().length > 0 &&
    !window.FIREBASE_CONFIG.apiKey.includes("PASTE_");
};
