# Firebase Setup Guide

## Step 1: Create Firebase Project (BROWSER)

1. Go to https://console.firebase.google.com/
2. Click "Add project"
3. Name: `e-learning-management-app`
4. Disable Google Analytics
5. Click "Create project"

---

## Step 2: Add Web App (BROWSER)

1. In Firebase Console, click the **Web icon** (</>)
2. App nickname: `E-Learning Web`
3. **Check** "Also set up Firebase Hosting"
4. Click "Register app"
5. **COPY** the Firebase configuration object that appears
6. Click "Continue to console"

The config looks like this (COPY YOURS):
```javascript
const firebaseConfig = {
  apiKey: "YOUR-API-KEY",
  authDomain: "your-app.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-app.appspot.com",
  messagingSenderId: "123456789",
  appId: "YOUR-APP-ID"
};
```

---

## Step 3: Add Android App (BROWSER)

1. In Firebase Console, click **Android icon**
2. Android package name: `com.example.e_learning_management_app`
3. App nickname: `E-Learning Android`
4. Click "Register app"
5. **DOWNLOAD** `google-services.json`
6. Click "Next" → "Next" → "Continue to console"

**IMPORTANT**: Save the `google-services.json` file, you'll need it!

---

## Step 4: Enable Authentication (BROWSER)

1. In Firebase Console, go to **Authentication**
2. Click "Get started"
3. Click "Email/Password"
4. **Enable** Email/Password
5. Click "Save"

---

## Step 5: Create Firestore Database (BROWSER)

1. In Firebase Console, go to **Firestore Database**
2. Click "Create database"
3. Choose "Start in **test mode**" (we'll secure it later)
4. Select location closest to you
5. Click "Enable"

---

## Step 6: Set Up Storage (BROWSER)

1. In Firebase Console, go to **Storage**
2. Click "Get started"
3. Start in **test mode**
4. Click "Next" → "Done"

---

## Step 7: Configure Firebase Rules (BROWSER)

### Firestore Rules (Database)
Go to Firestore → Rules → Replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

Click "Publish"

### Storage Rules
Go to Storage → Rules → Replace with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

Click "Publish"

---

## Step 8: Create Admin User (BROWSER)

1. Go to **Authentication** → **Users**
2. Click "Add user"
3. Email: `admin@example.com`
4. Password: `admin`
5. Click "Add user"

---

## ✅ Checklist

- [ ] Firebase project created
- [ ] Web app added and config copied
- [ ] Android app added and google-services.json downloaded
- [ ] Email/Password authentication enabled
- [ ] Firestore database created
- [ ] Storage set up
- [ ] Security rules updated
- [ ] Admin user created

---

## Next Steps

Once you complete the above:
1. Tell me you're done
2. I'll help you integrate the Firebase config into your Flutter app
3. We'll test the authentication

**Take your time and follow each step carefully!**
