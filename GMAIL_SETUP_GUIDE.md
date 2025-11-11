# Gmail Setup Guide for Email Notifications

This guide will help you set up Gmail to send automated email notifications from your E-Learning Management App.

## 📋 Prerequisites

- Gmail account (any Gmail address will work)
- Firebase project with Blaze plan enabled
- Firebase CLI installed

## 🔑 Step 1: Enable 2-Factor Authentication

Gmail requires 2-Factor Authentication (2FA) to use App Passwords.

1. Go to https://myaccount.google.com/security
2. Under "Signing in to Google", click on "2-Step Verification"
3. Follow the setup process if not already enabled

## 🔐 Step 2: Create Gmail App Password

**Important**: You CANNOT use your regular Gmail password. You must create an App Password.

### Creating an App Password:

1. Go to https://myaccount.google.com/apppasswords
   - Or: Google Account → Security → 2-Step Verification → App passwords

2. You might need to sign in again

3. In the "Select app" dropdown, choose:
   - **App**: Mail
   - **Device**: Other (Custom name)
   - Name it: "E-Learning App" or "Firebase Functions"

4. Click **Generate**

5. **IMPORTANT**: Copy the 16-character password that appears
   - It will look like: `xxxx xxxx xxxx xxxx`
   - You won't be able to see this again!
   - Save it somewhere safe temporarily

## 🚀 Step 3: Configure Firebase Functions

Set your Gmail credentials in Firebase:

```bash
# Set your Gmail address
firebase functions:config:set gmail.email="your-email@gmail.com"

# Set your App Password (remove spaces)
firebase functions:config:set gmail.password="xxxxxxxxxxxxxxxx"

# Set your app URL (optional, for deep links)
firebase functions:config:set app.baseurl="https://your-app-url.com"
```

**Example**:
```bash
firebase functions:config:set gmail.email="elearning.app@gmail.com"
firebase functions:config:set gmail.password="abcd efgh ijkl mnop"
firebase functions:config:set app.baseurl="https://elearning.web.app"
```

Verify configuration:
```bash
firebase functions:config:get
```

You should see:
```json
{
  "gmail": {
    "email": "your-email@gmail.com",
    "password": "xxxxxxxxxxxxxxxx"
  },
  "app": {
    "baseurl": "https://your-app-url.com"
  }
}
```

## 📦 Step 4: Install Dependencies

```bash
cd functions
npm install
```

## 🚀 Step 5: Deploy Functions

```bash
# Deploy Cloud Functions
firebase deploy --only functions

# Also deploy Firestore rules and indexes
firebase deploy --only firestore:rules,firestore:indexes
```

## 🧪 Step 6: Test Email Sending

### Option 1: Create Test Notification in Firebase Console

1. Go to Firebase Console → Firestore Database
2. Click on `notifications` collection
3. Click "Add Document"
4. Fill in the fields:
   ```
   studentId: [test-user-id with valid email]
   title: "Test Notification"
   message: "This is a test email"
   type: "announcement"
   linkTo: "announcement/testCourse/testId"
   isRead: false
   createdAt: [Timestamp - now]
   ```
5. Click "Save"
6. Check your email! (also check spam folder)

### Option 2: Test via App

1. Log in as instructor
2. Create an announcement or assignment
3. Check student's email inbox

## 📊 Monitoring

### View Function Logs

```bash
# View recent logs
firebase functions:log

# Follow logs in real-time
firebase functions:log --follow

# View specific function
firebase functions:log --only sendNotificationEmail
```

Look for these messages:
- ✅ "Email sent successfully to [email]"
- ❌ "Error sending email: [error]"

### Common Success Messages
```
Email sent successfully to student@example.com
Email sent to student@example.com for announcement
Sent reminder to student123 for assignment assign456
```

## ⚠️ Important Notes

### Gmail Sending Limits

**Free Gmail Account**:
- **500 emails per day** (rolling 24-hour period)
- **100 recipients per message**
- More than enough for most educational institutions

**Google Workspace Account** (if you have one):
- **2,000 emails per day**
- Better for larger deployments

### Sender Name

Emails will appear as:
```
From: E-Learning App <your-email@gmail.com>
```

You can customize this in `functions/index.js` line 101:
```javascript
from: `Your Custom Name <${SENDER_EMAIL}>`,
```

### Email Deliverability

To improve email deliverability:

1. **Use a dedicated Gmail account** for your app (not your personal email)
2. **Warm up the account**: Start by sending a few emails per day, gradually increase
3. **Monitor spam reports**: Check if emails are going to spam
4. **Add SPF/DKIM** (for custom domains - advanced)

## 🐛 Troubleshooting

### Problem: "Invalid login: 535-5.7.8 Username and Password not accepted"

**Solution**:
- Make sure you're using an **App Password**, not your regular Gmail password
- Verify 2FA is enabled on your Google account
- Double-check the app password (no spaces)
- Try generating a new app password

### Problem: "Error: Missing credentials for 'PLAIN'"

**Solution**:
- Gmail credentials not set in Firebase config
- Run: `firebase functions:config:get` to verify
- Re-run configuration commands if needed

### Problem: Emails not arriving

**Solution**:
1. Check spam/junk folder
2. Verify recipient email is correct
3. Check function logs: `firebase functions:log`
4. Verify Gmail daily limit not exceeded
5. Check if Gmail account is locked (too many emails too fast)

### Problem: "Error: Invalid login: 535 Authentication failed"

**Solution**:
- App password may have been revoked
- Generate a new app password
- Update Firebase config with new password

### Problem: Emails going to spam

**Solution**:
1. Ask recipients to mark as "Not Spam"
2. Avoid spam trigger words in subject lines
3. Include unsubscribe link (optional)
4. Use consistent sender name
5. Don't send too many emails at once

## 💰 Cost Comparison

### Gmail (Free)
- **Cost**: Free
- **Limit**: 500 emails/day
- **Setup**: 5 minutes
- **Reliability**: High
- **Best for**: Small to medium deployments (< 100 students)

### Google Workspace (Paid)
- **Cost**: $6/user/month
- **Limit**: 2,000 emails/day
- **Setup**: 10 minutes
- **Reliability**: Very high
- **Best for**: Large deployments (> 100 students)

### SendGrid (Alternative)
- **Cost**: Free (100/day), $19.95/month (50K)
- **Limit**: Varies by plan
- **Setup**: 15 minutes
- **Reliability**: Very high
- **Best for**: Very large deployments or professional needs

## 🔒 Security Best Practices

1. **Never commit credentials** to version control
2. **Use App Passwords** (not your main Gmail password)
3. **Create dedicated Gmail** account for the app
4. **Rotate app passwords** every 6 months
5. **Monitor unauthorized access** in Google Account activity
6. **Enable alerts** for suspicious activity
7. **Revoke app passwords** when no longer needed

## 📱 Gmail Account Setup Tips

### Creating a Dedicated Account

Consider creating a dedicated Gmail account for your app:

**Good examples**:
- `elearning.app@gmail.com`
- `noreply.elearning@gmail.com`
- `notifications.elearning@gmail.com`

**Benefits**:
- Separates app emails from personal emails
- Easier to monitor and manage
- Better for troubleshooting
- Cleaner logs

### Account Settings

After creating the account:
1. Set a strong password
2. Enable 2FA immediately
3. Add recovery email/phone
4. Set profile picture (optional, appears in emails)

## ✅ Verification Checklist

Before going live, verify:

- [ ] 2FA enabled on Gmail account
- [ ] App password created and saved
- [ ] Firebase config set correctly (`firebase functions:config:get`)
- [ ] Functions deployed successfully
- [ ] Test email sent and received
- [ ] Email arrives in inbox (not spam)
- [ ] Email formatting looks good
- [ ] Deep links in emails work
- [ ] Function logs show no errors
- [ ] Firestore rules deployed

## 🎉 You're Done!

Your email notification system is now using Gmail! Students will receive:

- ✉️ New announcement notifications
- ✉️ Assignment deadline reminders
- ✉️ Grade notifications
- ✉️ Submission confirmations
- ✉️ Quiz notifications
- ✉️ New message alerts
- ✉️ Deadline reminders (24 hours before)

All emails are professional, mobile-friendly, and include direct links back to your app.

## 📞 Support

If you encounter issues:

1. Check Firebase Functions logs
2. Verify Gmail App Password is correct
3. Check Gmail account isn't locked
4. Review troubleshooting section above
5. Check Google Account security alerts

## 🔄 Updating Configuration

To change Gmail account or password:

```bash
# Update email
firebase functions:config:set gmail.email="new-email@gmail.com"

# Update password
firebase functions:config:set gmail.password="new-app-password"

# Redeploy functions
firebase deploy --only functions
```

---

**Congratulations!** You're now sending emails through Gmail. Much simpler than SendGrid, and completely free! 🚀
