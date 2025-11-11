# Firebase Cloud Functions - Email Notification Service

This directory contains Firebase Cloud Functions that handle automated email notifications for the E-Learning Management App.

## 📋 Features

The email notification service provides automated emails for:

1. **New Announcements** - Notifies students when instructors post announcements
2. **New Assignments** - Alerts students about newly created assignments with deadlines
3. **New Quizzes** - Informs students when quizzes become available
4. **Assignment Graded** - Notifies students when their work has been graded
5. **Submission Confirmed** - Confirms successful assignment submission
6. **Deadline Reminders** - Sends reminders 24 hours before deadlines
7. **New Messages** - Alerts students to new messages from instructors

## 🚀 Setup Instructions

### Prerequisites

1. **Node.js 18** or higher
2. **Firebase CLI** installed globally:
   ```bash
   npm install -g firebase-tools
   ```
3. **SendGrid Account** (free tier available at https://sendgrid.com)
4. **Firebase Project** with Blaze (Pay-as-you-go) plan (required for Cloud Functions)

### Step 1: Install Dependencies

```bash
cd functions
npm install
```

### Step 2: Configure SendGrid

1. Sign up for SendGrid at https://sendgrid.com
2. Create an API key with "Mail Send" permissions
3. Verify your sender email/domain in SendGrid
4. Set the SendGrid API key in Firebase:

```bash
firebase functions:config:set sendgrid.key="YOUR_SENDGRID_API_KEY"
firebase functions:config:set sendgrid.sender="noreply@yourdomain.com"
```

### Step 3: Configure App URL

Set your app's base URL for deep links in emails:

```bash
firebase functions:config:set app.baseurl="https://your-app-url.com"
```

### Step 4: Deploy Functions

Deploy all functions to Firebase:

```bash
firebase deploy --only functions
```

Or deploy individual functions:

```bash
firebase deploy --only functions:sendNotificationEmail
firebase deploy --only functions:checkUpcomingDeadlines
firebase deploy --only functions:cleanupOldReminders
```

## 📁 Project Structure

```
functions/
├── index.js                          # Main Cloud Functions file
├── package.json                      # Node.js dependencies
├── .gitignore                        # Git ignore rules
├── .env.example                      # Environment variables template
└── src/
    └── templates/                    # Email HTML templates
        ├── baseTemplate.js           # Base email layout
        ├── announcementEmail.js      # Announcement template
        ├── assignmentEmail.js        # Assignment template
        ├── quizEmail.js              # Quiz template
        ├── gradedEmail.js            # Graded work template
        ├── submissionConfirmedEmail.js  # Submission confirmation
        ├── deadlineReminderEmail.js  # Deadline reminder template
        └── messageEmail.js           # New message template
```

## 🔧 Cloud Functions

### 1. `sendNotificationEmail`

**Trigger**: Firestore `notifications` collection onCreate
**Purpose**: Automatically sends an email when a new notification is created in Firestore
**Process**:
- Listens for new documents in the `notifications` collection
- Fetches student email and related data (course, assignment, etc.)
- Generates HTML email using appropriate template
- Sends email via SendGrid
- Updates notification document with email status

### 2. `checkUpcomingDeadlines`

**Trigger**: Scheduled (runs every hour)
**Purpose**: Backup system to ensure deadline reminders are sent even if app service fails
**Process**:
- Queries for assignments/quizzes with deadlines in next 24 hours
- Checks if reminders already sent (via `deadlineReminders` collection)
- Creates notifications for students (which triggers `sendNotificationEmail`)
- Marks reminders as sent to prevent duplicates

### 3. `cleanupOldReminders`

**Trigger**: Scheduled (runs daily at midnight)
**Purpose**: Removes old deadline reminder records to keep database clean
**Process**:
- Queries for reminder records older than 7 days
- Deletes old records in batch operations

## 📧 Email Templates

All email templates use a consistent, professional design with:
- Responsive layout (mobile-friendly)
- Brand colors (purple gradient header)
- Clear call-to-action buttons
- Proper formatting and styling
- Footer with app information

### Customizing Templates

Email templates are located in `src/templates/`. Each template is a JavaScript module that exports a function returning HTML.

To customize:
1. Edit the template file (e.g., `announcementEmail.js`)
2. Modify the HTML structure and styling
3. Redeploy functions: `firebase deploy --only functions`

## 🔐 Security & Configuration

### Environment Variables

Configuration values are stored in Firebase Functions config:

```bash
# View current config
firebase functions:config:get

# Set config values
firebase functions:config:set key="value"

# Delete config values
firebase functions:config:unset key
```

### Required Configuration

- `sendgrid.key` - SendGrid API key
- `sendgrid.sender` - Verified sender email address
- `app.baseurl` - Your app's base URL for deep links

## 🧪 Testing

### Local Testing with Firebase Emulators

1. Start the emulators:
   ```bash
   firebase emulators:start
   ```

2. Test functions locally before deployment

### Testing Email Delivery

1. Create a test notification in Firestore:
   ```javascript
   // In Firebase Console or your app
   await db.collection('notifications').add({
     studentId: 'test_student_id',
     title: 'Test Notification',
     message: 'This is a test',
     type: 'announcement',
     linkTo: 'announcement/course123/announce456',
     createdAt: FieldValue.serverTimestamp(),
     isRead: false
   });
   ```

2. Check Firebase Functions logs:
   ```bash
   firebase functions:log
   ```

3. Verify email delivery in SendGrid dashboard

## 📊 Monitoring

### View Function Logs

```bash
# View recent logs
firebase functions:log

# Follow logs in real-time
firebase functions:log --follow

# View logs for specific function
firebase functions:log --only sendNotificationEmail
```

### Firebase Console

Monitor function execution in the Firebase Console:
1. Go to Firebase Console → Functions
2. View execution count, errors, and performance metrics
3. Check for failed invocations

### SendGrid Dashboard

Monitor email delivery in SendGrid:
1. Go to SendGrid Dashboard → Activity
2. View sent, delivered, bounced, and failed emails
3. Check spam reports and unsubscribes

## 💰 Cost Estimation

### Firebase Functions (Blaze Plan)

- **Free tier**: 2M invocations/month, 400K GB-seconds, 200K CPU-seconds
- **After free tier**: $0.40 per million invocations

### Estimated Monthly Costs

For a class of 100 students:
- ~500 notifications/day = 15,000/month
- Well within free tier
- **Estimated cost**: $0/month

For a school of 1,000 students:
- ~5,000 notifications/day = 150,000/month
- Still within free tier
- **Estimated cost**: $0/month

### SendGrid Costs

- **Free tier**: 100 emails/day (3,000/month)
- **Essentials plan**: $19.95/month for 50,000 emails/month
- **Pro plan**: $89.95/month for 100,000 emails/month

## 🐛 Troubleshooting

### Emails Not Sending

1. **Check SendGrid API Key**:
   ```bash
   firebase functions:config:get sendgrid.key
   ```

2. **Verify Sender Email**: Ensure sender email is verified in SendGrid

3. **Check Function Logs**:
   ```bash
   firebase functions:log --only sendNotificationEmail
   ```

4. **Test SendGrid API**: Use SendGrid's API test tool

### Function Not Triggering

1. **Check Firestore Triggers**: Ensure notifications are being created in Firestore
2. **Check Function Deployment**: `firebase functions:list`
3. **Check Firebase Permissions**: Ensure functions have proper IAM roles

### Deployment Errors

1. **Check Node Version**: Ensure Node 18 is installed
2. **Check Dependencies**: Run `npm install` in functions directory
3. **Check Firebase Project**: `firebase use --list`
4. **Check Billing**: Ensure Firebase project has Blaze plan enabled

## 🔄 Updates & Maintenance

### Updating Dependencies

```bash
cd functions
npm update
firebase deploy --only functions
```

### Adding New Email Types

1. Create new template in `src/templates/`
2. Add case in `sendNotificationEmail` function in `index.js`
3. Deploy: `firebase deploy --only functions`

## 📝 Best Practices

1. **Test Locally First**: Always test with emulators before deploying
2. **Monitor Costs**: Keep an eye on Firebase and SendGrid usage
3. **Handle Errors Gracefully**: Functions should not throw errors that affect app
4. **Log Important Events**: Use console.log for debugging
5. **Keep Templates Updated**: Maintain consistent branding across all emails
6. **Rate Limiting**: Be mindful of SendGrid rate limits
7. **Email Deliverability**: Follow email best practices to avoid spam filters

## 📞 Support

For issues or questions:
1. Check Firebase Functions documentation: https://firebase.google.com/docs/functions
2. Check SendGrid documentation: https://docs.sendgrid.com
3. Review Firebase Console logs
4. Check SendGrid Activity Feed

## 📄 License

This project is part of the E-Learning Management App.
