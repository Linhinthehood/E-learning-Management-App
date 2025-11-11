# Firebase Cloud Functions Setup Guide - Gmail Version

This guide will walk you through setting up and deploying the email notification service using **Gmail** (free!).

## 📋 Prerequisites Checklist

Before you begin, make sure you have:

- [ ] Gmail account (any Gmail will work)
- [ ] Firebase account (https://firebase.google.com)
- [ ] Firebase project created
- [ ] Firebase Blaze (Pay-as-you-go) plan enabled
- [ ] Node.js 18 or higher installed
- [ ] Firebase CLI installed globally

## 🚀 Quick Setup (3 Steps)

### 1. Create Gmail App Password

You need a special "App Password" from Gmail (NOT your regular password):

1. **Enable 2FA**: Go to https://myaccount.google.com/security
   - Enable "2-Step Verification" if not already enabled

2. **Create App Password**: Go to https://myaccount.google.com/apppasswords
   - App: Mail
   - Device: Other (custom name) → "E-Learning App"
   - Click "Generate"
   - **Copy the 16-character password** (you won't see it again!)

### 2. Configure Firebase Functions

```bash
# Set your Gmail address
firebase functions:config:set gmail.email="your-email@gmail.com"

# Set your App Password (16 characters, can include spaces)
firebase functions:config:set gmail.password="xxxx xxxx xxxx xxxx"

# Set your app URL
firebase functions:config:set app.baseurl="https://your-app-url.com"
```

**Example**:
```bash
firebase functions:config:set gmail.email="elearning.app@gmail.com"
firebase functions:config:set gmail.password="abcd efgh ijkl mnop"
firebase functions:config:set app.baseurl="https://elearning.web.app"
```

### 3. Deploy

```bash
# Install dependencies
cd functions && npm install

# Deploy everything
firebase deploy --only functions,firestore:rules,firestore:indexes
```

### 4. Test!

Create a test notification in Firestore and check your email!

---

## 📚 Detailed Documentation

For detailed setup instructions, troubleshooting, and more, see:
- **GMAIL_SETUP_GUIDE.md** - Complete Gmail setup guide
- **functions/README.md** - Cloud Functions documentation

## ⚠️ Important Notes

1. **Use App Password**: You MUST use a Gmail App Password, not your regular Gmail password
2. **Enable 2FA**: 2-Factor Authentication must be enabled to create App Passwords
3. **Daily Limit**: Gmail allows 500 emails/day (plenty for most schools)
4. **Dedicated Account**: Consider using a dedicated Gmail account for your app

## 🎯 Quick Commands Reference

```bash
# View current config
firebase functions:config:get

# View function logs
firebase functions:log --follow

# Redeploy functions
firebase deploy --only functions

# Check for errors
firebase functions:log --only sendNotificationEmail
```

## 💰 Cost

**Gmail**: Completely FREE! (up to 500 emails/day)

**Firebase Functions**: Typically $0-2/month for 100 students (within free tier)

**Total**: $0-2/month

---

That's it! Much simpler than SendGrid and completely free. See **GMAIL_SETUP_GUIDE.md** for troubleshooting and advanced options.
