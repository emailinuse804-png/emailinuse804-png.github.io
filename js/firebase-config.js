import { initializeApp } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js";
import { getAuth, GoogleAuthProvider } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js";

/**
 * Replace this object with values from:
 * Firebase Console -> Project Settings -> General -> Your apps -> SDK setup and configuration
 */
const firebaseConfig = {
  apiKey: "AIzaSyAPkKTtNQQnBK5Oj9XuoZhSpSvRXJl8YxY",
  authDomain: "testing-c781b.firebaseapp.com",
  projectId: "testing-c781b",
  storageBucket: "testing-c781b.firebasestorage.app",
  messagingSenderId: "916663078402",
  appId: "1:916663078402:web:d0a2cb7c4356ff542da11b",
  measurementId: "G-JQLYDQ7J6J"
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

const googleProvider = new GoogleAuthProvider();
googleProvider.setCustomParameters({ prompt: "select_account" });

const isFirebaseConfigured = () => {
  return Object.values(firebaseConfig).every((value) => typeof value === "string" && !value.startsWith("YOUR_"));
};

export { app, auth, db, googleProvider, firebaseConfig, isFirebaseConfigured };
