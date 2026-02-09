import {
  auth,
  db,
  googleProvider,
  isFirebaseConfigured
} from "./firebase-config.js";
import {
  browserLocalPersistence,
  getRedirectResult,
  onAuthStateChanged,
  setPersistence,
  signInWithPopup,
  signInWithRedirect,
  signOut
} from "https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js";
import {
  addDoc,
  collection,
  doc,
  limit,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc
} from "https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js";

const MAX_MESSAGE_LENGTH = 500;
const MAX_MESSAGES = 200;
const ONLINE_WINDOW_MS = 2 * 60 * 1000;
const PRESENCE_HEARTBEAT_MS = 30 * 1000;
const SEND_COOLDOWN_MS = 900;
const MAX_ONLINE_AVATARS = 6;
const GOOGLE_BUTTON_HTML = '<span class="google-icon" aria-hidden="true">G</span> Continue with Google';

const dom = {
  loadingScreen: document.getElementById("loadingScreen"),
  loadingText: document.getElementById("loadingText"),
  loginScreen: document.getElementById("loginScreen"),
  chatScreen: document.getElementById("chatScreen"),
  loginHint: document.getElementById("loginHint"),
  signInBtn: document.getElementById("googleSignInBtn"),
  signOutBtn: document.getElementById("signOutBtn"),
  currentUserName: document.getElementById("currentUserName"),
  currentUserAvatar: document.getElementById("currentUserAvatar"),
  onlineSummary: document.getElementById("onlineSummary"),
  onlineUsers: document.getElementById("onlineUsers"),
  messagesContainer: document.getElementById("messagesContainer"),
  messagesList: document.getElementById("messagesList"),
  messagesEmptyState: document.getElementById("messagesEmptyState"),
  messageForm: document.getElementById("messageForm"),
  messageInput: document.getElementById("messageInput"),
  sendBtn: document.getElementById("sendBtn"),
  charCounter: document.getElementById("charCounter"),
  statusText: document.getElementById("statusText"),
  toast: document.getElementById("toast")
};

let currentUser = null;
let unsubscribeMessages = null;
let unsubscribePresence = null;
let presenceTimer = null;
let cachedMessages = [];
let onlineUsersMap = new Map();
let toastTimer = null;
let lastSentAt = 0;
let statusResetTimer = null;

function showScreen(screen) {
  const screenMap = {
    loading: dom.loadingScreen,
    login: dom.loginScreen,
    chat: dom.chatScreen
  };

  Object.values(screenMap).forEach((element) => element.classList.add("hidden"));
  screenMap[screen].classList.remove("hidden");
}

function setLoadingText(text) {
  dom.loadingText.textContent = text;
}

function setStatus(message) {
  dom.statusText.textContent = message;
}

function setStatusTemporarily(message, duration = 2000) {
  if (statusResetTimer) {
    clearTimeout(statusResetTimer);
  }

  setStatus(message);
  statusResetTimer = setTimeout(() => {
    if (currentUser) {
      setStatus("Connected");
    }
  }, duration);
}

function showToast(message, tone = "info") {
  if (toastTimer) {
    clearTimeout(toastTimer);
  }

  dom.toast.textContent = message;
  dom.toast.classList.remove("hidden", "error", "success");

  if (tone === "error") {
    dom.toast.classList.add("error");
  } else if (tone === "success") {
    dom.toast.classList.add("success");
  }

  toastTimer = setTimeout(() => {
    dom.toast.classList.add("hidden");
  }, 3500);
}

function updateCharCounter() {
  const length = dom.messageInput.value.length;
  dom.charCounter.textContent = `${length} / ${MAX_MESSAGE_LENGTH}`;
}

// Input is stored as plain text and rendered with textContent to avoid XSS injection.
function sanitizeMessageInput(value) {
  return value
    .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, "")
    .trim();
}

function buildFallbackAvatar(name) {
  const firstChar = (name || "?").trim().charAt(0).toUpperCase() || "?";
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64"><rect width="64" height="64" fill="#bfdbfe"/><text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" fill="#1e3a8a" font-size="28" font-family="Arial">${firstChar}</text></svg>`;
  return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`;
}

function profilePhotoOrFallback(photoUrl, displayName) {
  return photoUrl || buildFallbackAvatar(displayName);
}

function formatTimestamp(timestamp) {
  if (!timestamp || typeof timestamp.toDate !== "function") {
    return "Sending...";
  }

  return new Intl.DateTimeFormat(undefined, {
    hour: "numeric",
    minute: "2-digit"
  }).format(timestamp.toDate());
}

function isNearBottom() {
  const threshold = 120;
  const { scrollTop, scrollHeight, clientHeight } = dom.messagesContainer;
  return scrollTop + clientHeight >= scrollHeight - threshold;
}

function scrollToBottom() {
  dom.messagesContainer.scrollTop = dom.messagesContainer.scrollHeight;
}

function clearMessagesUi() {
  cachedMessages = [];
  dom.messagesList.textContent = "";
  dom.messagesEmptyState.classList.remove("hidden");
}

function setCurrentUserUi(user) {
  const displayName = user.displayName || "Anonymous";
  dom.currentUserName.textContent = displayName;
  dom.currentUserAvatar.src = profilePhotoOrFallback(user.photoURL, displayName);
}

function renderOnlineUsers(users) {
  dom.onlineUsers.textContent = "";

  const visibleUsers = users.slice(0, MAX_ONLINE_AVATARS);
  visibleUsers.forEach((user) => {
    const avatar = document.createElement("img");
    avatar.className = "avatar-pill";
    avatar.src = profilePhotoOrFallback(user.photoURL, user.displayName);
    avatar.alt = `${user.displayName || "Anonymous"} is online`;
    avatar.title = user.displayName || "Anonymous";
    dom.onlineUsers.appendChild(avatar);
  });

  const onlineCount = users.length;
  dom.onlineSummary.textContent = `${onlineCount} user${onlineCount === 1 ? "" : "s"} online`;
}

function renderMessages(messages) {
  dom.messagesList.textContent = "";

  messages.forEach((message) => {
    const isOwn = message.uid === currentUser?.uid;
    const item = document.createElement("li");
    item.className = `message-item${isOwn ? " own" : ""}`;

    const avatar = document.createElement("img");
    avatar.className = "avatar";
    avatar.src = profilePhotoOrFallback(message.photoURL, message.displayName);
    avatar.alt = `${message.displayName || "Anonymous"} profile photo`;

    const body = document.createElement("article");
    body.className = "message-body";

    const meta = document.createElement("div");
    meta.className = "message-meta";

    const author = document.createElement("span");
    author.className = "message-author";
    author.textContent = isOwn ? "You" : (message.displayName || "Anonymous");

    meta.appendChild(author);

    if (!isOwn && onlineUsersMap.has(message.uid)) {
      const onlineDot = document.createElement("span");
      onlineDot.className = "online-dot";
      onlineDot.setAttribute("aria-label", "User online");
      meta.appendChild(onlineDot);
    }

    const time = document.createElement("time");
    time.textContent = formatTimestamp(message.createdAt);
    meta.appendChild(time);

    const text = document.createElement("p");
    text.className = "message-text";
    text.textContent = message.text || "";

    body.append(meta, text);
    item.append(avatar, body);
    dom.messagesList.appendChild(item);
  });

  dom.messagesEmptyState.classList.toggle("hidden", messages.length > 0);
}

function authErrorMessage(error) {
  const code = error?.code || "";

  if (code === "auth/popup-closed-by-user") {
    return "Sign-in was canceled.";
  }
  if (code === "auth/network-request-failed") {
    return "Network error. Check your connection and try again.";
  }
  if (code === "permission-denied") {
    return "Permission denied. Check your Firebase rules.";
  }
  return "Something went wrong. Please try again.";
}

async function updatePresence(state = "online") {
  if (!currentUser) {
    return;
  }

  const presenceRef = doc(db, "presence", currentUser.uid);
  await setDoc(
    presenceRef,
    {
      uid: currentUser.uid,
      displayName: currentUser.displayName || "Anonymous",
      photoURL: currentUser.photoURL || "",
      state,
      lastActive: serverTimestamp()
    },
    { merge: true }
  );
}

function subscribeToMessages() {
  if (unsubscribeMessages) {
    unsubscribeMessages();
  }

  const messagesQuery = query(
    collection(db, "messages"),
    orderBy("createdAt", "desc"),
    limit(MAX_MESSAGES)
  );

  unsubscribeMessages = onSnapshot(
    messagesQuery,
    (snapshot) => {
      const shouldAutoScroll = isNearBottom();

      // Query newest messages first, then reverse for natural top-to-bottom reading.
      cachedMessages = snapshot.docs
        .map((snapshotDoc) => ({
          id: snapshotDoc.id,
          ...snapshotDoc.data()
        }))
        .reverse();

      renderMessages(cachedMessages);

      const latestMessage = cachedMessages[cachedMessages.length - 1];
      if (shouldAutoScroll || latestMessage?.uid === currentUser?.uid) {
        scrollToBottom();
      }
    },
    (error) => {
      console.error("messages listener error", error);
      showToast(`Unable to load messages: ${authErrorMessage(error)}`, "error");
      setStatus("Disconnected");
    }
  );
}

function subscribeToPresence() {
  if (unsubscribePresence) {
    unsubscribePresence();
  }

  const presenceQuery = query(
    collection(db, "presence"),
    orderBy("lastActive", "desc"),
    limit(50)
  );

  unsubscribePresence = onSnapshot(
    presenceQuery,
    (snapshot) => {
      const now = Date.now();
      onlineUsersMap = new Map();

      const onlineUsers = snapshot.docs
        .map((snapshotDoc) => snapshotDoc.data())
        .filter((user) => {
          const lastActive = user?.lastActive;
          if (!lastActive || typeof lastActive.toMillis !== "function") {
            return false;
          }

          const activeRecently = now - lastActive.toMillis() <= ONLINE_WINDOW_MS;
          const markedOnline = user.state === "online";
          return Boolean(user.uid) && markedOnline && activeRecently;
        });

      onlineUsers.forEach((user) => onlineUsersMap.set(user.uid, user));
      renderOnlineUsers(onlineUsers);

      if (cachedMessages.length) {
        const shouldAutoScroll = isNearBottom();
        renderMessages(cachedMessages);
        if (shouldAutoScroll) {
          scrollToBottom();
        }
      }
    },
    (error) => {
      console.error("presence listener error", error);
      showToast(`Unable to load online users: ${authErrorMessage(error)}`, "error");
    }
  );
}

function startPresenceHeartbeat() {
  if (presenceTimer) {
    clearInterval(presenceTimer);
  }

  updatePresence("online").catch((error) => {
    console.error("presence heartbeat initial error", error);
  });

  presenceTimer = setInterval(() => {
    updatePresence("online").catch((error) => {
      console.error("presence heartbeat interval error", error);
    });
  }, PRESENCE_HEARTBEAT_MS);
}

async function markCurrentUserOffline() {
  if (!currentUser) {
    return;
  }

  const presenceRef = doc(db, "presence", currentUser.uid);

  try {
    await updateDoc(presenceRef, {
      state: "offline",
      lastActive: serverTimestamp()
    });
  } catch (updateError) {
    // Fallback for first-time users that do not yet have a presence document.
    await setDoc(
      presenceRef,
      {
        uid: currentUser.uid,
        displayName: currentUser.displayName || "Anonymous",
        photoURL: currentUser.photoURL || "",
        state: "offline",
        lastActive: serverTimestamp()
      },
      { merge: true }
    );
  }
}

function cleanupRealtimeListeners() {
  if (unsubscribeMessages) {
    unsubscribeMessages();
    unsubscribeMessages = null;
  }

  if (unsubscribePresence) {
    unsubscribePresence();
    unsubscribePresence = null;
  }

  if (presenceTimer) {
    clearInterval(presenceTimer);
    presenceTimer = null;
  }
}

async function handleSignIn() {
  if (!isFirebaseConfigured()) {
    showToast("Firebase config is missing. Update js/firebase-config.js first.", "error");
    return;
  }

  dom.signInBtn.disabled = true;
  dom.signInBtn.textContent = "Signing in...";

  try {
    await signInWithPopup(auth, googleProvider);
  } catch (error) {
    const shouldFallbackToRedirect = [
      "auth/popup-blocked",
      "auth/operation-not-supported-in-this-environment"
    ].includes(error?.code);

    if (shouldFallbackToRedirect) {
      await signInWithRedirect(auth, googleProvider);
      return;
    }

    console.error("sign in error", error);
    showToast(`Sign-in failed: ${authErrorMessage(error)}`, "error");
  } finally {
    dom.signInBtn.disabled = false;
    dom.signInBtn.innerHTML = GOOGLE_BUTTON_HTML;
  }
}

async function handleSignOut() {
  dom.signOutBtn.disabled = true;

  try {
    await markCurrentUserOffline();
    await signOut(auth);
    showToast("Signed out successfully.", "success");
  } catch (error) {
    console.error("sign out error", error);
    showToast(`Unable to sign out: ${authErrorMessage(error)}`, "error");
  } finally {
    dom.signOutBtn.disabled = false;
  }
}

async function handleSendMessage(event) {
  event.preventDefault();

  if (!currentUser) {
    showToast("You must be signed in to send a message.", "error");
    return;
  }

  const now = Date.now();
  if (now - lastSentAt < SEND_COOLDOWN_MS) {
    showToast("Please wait a moment before sending another message.", "error");
    return;
  }

  const sanitized = sanitizeMessageInput(dom.messageInput.value);
  if (!sanitized) {
    return;
  }

  if (sanitized.length > MAX_MESSAGE_LENGTH) {
    showToast(`Message is too long (max ${MAX_MESSAGE_LENGTH} characters).`, "error");
    return;
  }

  dom.sendBtn.disabled = true;
  setStatus("Sending...");

  try {
    await addDoc(collection(db, "messages"), {
      uid: currentUser.uid,
      displayName: currentUser.displayName || "Anonymous",
      photoURL: currentUser.photoURL || "",
      text: sanitized,
      createdAt: serverTimestamp()
    });

    lastSentAt = Date.now();
    dom.messageInput.value = "";
    updateCharCounter();
    setStatusTemporarily("Message sent", 1200);
  } catch (error) {
    console.error("send message error", error);
    setStatus("Send failed");
    showToast(`Unable to send message: ${authErrorMessage(error)}`, "error");
  } finally {
    dom.sendBtn.disabled = false;
    dom.messageInput.focus();
  }
}

async function onAuthChanged(user) {
  cleanupRealtimeListeners();

  if (user) {
    // Start real-time listeners only after the user is authenticated.
    currentUser = user;
    setCurrentUserUi(user);
    setStatus("Connected");
    showScreen("chat");
    subscribeToMessages();
    subscribeToPresence();
    startPresenceHeartbeat();
    dom.messageInput.focus();
    return;
  }

  currentUser = null;
  onlineUsersMap = new Map();
  clearMessagesUi();
  renderOnlineUsers([]);
  setStatus("");
  showScreen("login");
}

function bindUiEvents() {
  dom.signInBtn.addEventListener("click", handleSignIn);
  dom.signOutBtn.addEventListener("click", handleSignOut);
  dom.messageForm.addEventListener("submit", handleSendMessage);
  dom.messageInput.addEventListener("input", updateCharCounter);

  window.addEventListener("beforeunload", () => {
    markCurrentUserOffline().catch(() => {
      // No-op: browser may stop async work during unload.
    });
  });

  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible") {
      updatePresence("online").catch(() => {
        // No-op: network may be unavailable momentarily.
      });
    }
  });
}

async function init() {
  bindUiEvents();
  updateCharCounter();
  showScreen("loading");
  setLoadingText("Checking your session.");

  if (!isFirebaseConfigured()) {
    showScreen("login");
    dom.signInBtn.disabled = true;
    dom.signInBtn.innerHTML = GOOGLE_BUTTON_HTML;
    dom.loginHint.textContent = "Add your Firebase config in js/firebase-config.js before signing in.";
    setStatus("Firebase config missing");
    return;
  }

  try {
    await setPersistence(auth, browserLocalPersistence);
  } catch (error) {
    console.error("auth persistence error", error);
    showToast("Could not set persistent session. Continuing with default behavior.", "error");
  }

  try {
    await getRedirectResult(auth);
  } catch (error) {
    console.error("redirect sign-in error", error);
    showToast(`Sign-in redirect failed: ${authErrorMessage(error)}`, "error");
  }

  onAuthStateChanged(
    auth,
    (user) => {
      onAuthChanged(user).catch((error) => {
        console.error("auth state handler error", error);
        showToast("Unable to initialize your session.", "error");
        showScreen("login");
      });
    },
    (error) => {
      console.error("auth listener error", error);
      showToast(`Authentication error: ${authErrorMessage(error)}`, "error");
      showScreen("login");
    }
  );
}

init().catch((error) => {
  console.error("fatal init error", error);
  showToast("Application failed to initialize.", "error");
  showScreen("login");
});
