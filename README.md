# Realtime Chat App (Firebase + GitHub Pages)

A pure frontend real-time messaging application built with **HTML + CSS + Vanilla JavaScript** and powered by:

- **Firebase Authentication** (Google Sign-In)
- **Cloud Firestore** (real-time messages + online presence)
- **GitHub Pages** (static hosting)

No backend server is required.

---

## File Structure

```text
/
|-- index.html
|-- css/
|   `-- styles.css
|-- js/
|   |-- app.js
|   `-- firebase-config.js
|-- firestore.rules
|-- README.md
`-- .gitignore
```

---

## Features

- Google Sign-In / Sign-Out
- Persistent auth session (stays signed in)
- Real-time chat updates with Firestore listeners
- Sender name + profile photo + timestamps
- Auto-scroll to newest messages
- Online user indicators (presence heartbeat)
- Loading states + status messages + error toasts
- Input sanitization and message character limits
- Mobile-friendly responsive UI

---

## 1) Create a Firebase Project

1. Open [https://console.firebase.google.com](https://console.firebase.google.com)
2. Click **Create a project**
3. Enter your project name and follow setup steps
4. Inside the project, click **Add app** and choose **Web** (`</>`)
5. Register your app (nickname optional)
6. Copy the Firebase config object from SDK setup

---

## 2) Enable Google Authentication

1. In Firebase Console, go to **Authentication** -> **Sign-in method**
2. Enable **Google**
3. Set your support email and save
4. Go to **Authentication** -> **Settings** -> **Authorized domains**
5. Add domains you will use:
   - `localhost` (for local testing)
   - `<your-username>.github.io`
   - Optional project page domain: `<your-username>.github.io/<repo-name>` (domain is still `<your-username>.github.io`)
   - Optional custom domain (if used)

---

## 3) Create Firestore Database

1. Go to **Firestore Database**
2. Click **Create database**
3. Start in **Production mode**
4. Choose a region near your users

---

## 4) Add Firebase Config to the App

Open `js/firebase-config.js` and replace placeholder values:

```js
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_PROJECT_ID.appspot.com",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  appId: "YOUR_APP_ID"
};
```

> The app intentionally warns and disables sign-in if placeholders are still present.

---

## 5) Apply Firestore Security Rules

Use the contents of `firestore.rules` in:
**Firestore Database -> Rules**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() {
      return request.auth != null;
    }

    function isValidMessage() {
      return request.resource.data.keys().hasOnly([
        "uid",
        "displayName",
        "photoURL",
        "text",
        "createdAt"
      ])
      && request.resource.data.uid == request.auth.uid
      && request.resource.data.displayName is string
      && request.resource.data.displayName.size() > 0
      && request.resource.data.displayName.size() <= 80
      && request.resource.data.photoURL is string
      && request.resource.data.photoURL.size() <= 500
      && request.resource.data.text is string
      && request.resource.data.text.size() > 0
      && request.resource.data.text.size() <= 500
      && request.resource.data.createdAt == request.time;
    }

    function isValidPresence() {
      return request.resource.data.keys().hasOnly([
        "uid",
        "displayName",
        "photoURL",
        "state",
        "lastActive"
      ])
      && request.resource.data.uid == request.auth.uid
      && request.resource.data.displayName is string
      && request.resource.data.displayName.size() > 0
      && request.resource.data.displayName.size() <= 80
      && request.resource.data.photoURL is string
      && request.resource.data.photoURL.size() <= 500
      && request.resource.data.state in ["online", "offline"]
      && request.resource.data.lastActive == request.time;
    }

    match /messages/{messageId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() && isValidMessage();
      allow update, delete: if false;
    }

    match /presence/{userId} {
      allow read: if isSignedIn();
      allow create, update: if isSignedIn() && userId == request.auth.uid && isValidPresence();
      allow delete: if isSignedIn() && userId == request.auth.uid;
    }
  }
}
```

### Rate Limiting Guidance

Firestore rules cannot reliably enforce per-user message rate limits by time window alone.
For stricter anti-spam protection, use one or more of:

- **Firebase App Check**
- **Cloud Functions** gatekeeper endpoint
- Moderation + abuse reporting workflow

The frontend includes a lightweight client cooldown to reduce accidental spam, but server-side enforcement is recommended for higher trust requirements.

---

## 6) Run Locally

Because this app uses JavaScript modules and popup auth, serve it over HTTP:

```bash
python3 -m http.server 8080
```

Then open:

```text
http://localhost:8080
```

---

## 7) Deploy to GitHub Pages

1. Push this project to your GitHub repository
2. Go to **Repository -> Settings -> Pages**
3. Under **Build and deployment**:
   - **Source**: Deploy from a branch
   - **Branch**: `main` (or your chosen branch)
   - **Folder**: `/ (root)`
   - Alternative: keep site files in `/docs` and select `docs` folder
4. Save and wait for deployment
5. Your URL will be:
   - User site repo: `https://<username>.github.io/`
   - Project site repo: `https://<username>.github.io/<repo-name>/`

### Optional: Custom Domain

1. In Pages settings, add your custom domain
2. Update DNS records at your domain provider
3. Add that domain to Firebase Auth authorized domains
4. Enable HTTPS in GitHub Pages settings

---

## Firestore Collections Used

### `messages`

Each document:

```json
{
  "uid": "user_uid",
  "displayName": "User Name",
  "photoURL": "https://...",
  "text": "Hello world",
  "createdAt": "server timestamp"
}
```

### `presence`

Document ID = user UID

```json
{
  "uid": "user_uid",
  "displayName": "User Name",
  "photoURL": "https://...",
  "state": "online",
  "lastActive": "server timestamp"
}
```

---

## Security Notes and Best Practices

- Authenticate users before accessing chat data
- Use strict Firestore rules (included)
- Render message text with `textContent` (prevents HTML/script injection)
- Keep message length capped at 500 chars
- Keep sensitive secrets out of frontend (Firebase config is public-safe, API keys are not secrets)
- For production abuse prevention, add App Check and/or Cloud Functions validation

---

## Firebase Hosting Configuration (Optional)

This repository is designed for **GitHub Pages** static hosting.
If you also want Firebase Hosting later, you can initialize it with:

```bash
firebase init hosting
```

Then deploy using:

```bash
firebase deploy
```

---

## License

Use this project as a starter template for your own real-time chat applications.
