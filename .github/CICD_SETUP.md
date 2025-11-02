# CI/CD Pipeline Setup Guide

This project uses GitHub Actions for continuous integration and deployment across multiple platforms.

## Workflows Overview

### 1. CI - Test and Lint (`ci.yml`)
**Triggers:** Push to `main` or `Hvan` branches, Pull requests to `main`

**What it does:**
- Runs on every push and PR
- Checks code formatting
- Runs static analysis
- Executes tests
- Checks for outdated dependencies

**No setup required** - runs automatically

---

### 2. Deploy Web (`deploy-web.yml`)
**Triggers:** Push to `main`, Manual dispatch

**What it does:**
- Builds Flutter web app for production
- Deploys to GitHub Pages
- Creates a live web version of your app

**Setup Required:**

1. **Enable GitHub Pages:**
   - Go to repository Settings → Pages
   - Under "Build and deployment":
     - Source: Select "GitHub Actions"
   - Save

2. **Access your deployed app:**
   - After deployment, your app will be available at:
   - `https://<your-username>.github.io/<repository-name>/`
   - URL is shown in the workflow run logs

**Manual Deployment:**
- Go to Actions → Deploy Web → Run workflow

---

### 3. Build Android (`build-android.yml`)
**Triggers:** Push to `main`, Tags starting with `v*`, Pull requests, Manual dispatch

**What it does:**
- Builds release APK (for direct installation)
- Builds App Bundle (for Google Play Store)
- Uploads artifacts (available for 30 days)
- Creates GitHub releases when tagged

**Setup Required:**

**For basic builds (no signing):**
- No setup needed - APKs will be unsigned (for testing only)

**For signed releases (production):**

1. **Generate keystore:**
   ```bash
   keytool -genkey -v -keystore release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release
   ```

2. **Create `android/key.properties`:**
   ```properties
   storePassword=<your-keystore-password>
   keyPassword=<your-key-password>
   keyAlias=release
   storeFile=release-keystore.jks
   ```

3. **Update `android/app/build.gradle`:**
   ```gradle
   def keystoreProperties = new Properties()
   def keystorePropertiesFile = rootProject.file('key.properties')
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
   }

   android {
       ...
       signingConfigs {
           release {
               keyAlias keystoreProperties['keyAlias']
               keyPassword keystoreProperties['keyPassword']
               storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
               storePassword keystoreProperties['storePassword']
           }
       }
       buildTypes {
           release {
               signingConfig signingConfigs.release
           }
       }
   }
   ```

4. **Add GitHub secrets:**
   - Go to Settings → Secrets and variables → Actions
   - Add the following secrets:
     - `ANDROID_KEYSTORE_BASE64`: Base64 encoded keystore file
       ```bash
       base64 release-keystore.jks > keystore-base64.txt
       ```
     - `ANDROID_KEYSTORE_PASSWORD`: Your keystore password
     - `ANDROID_KEY_PASSWORD`: Your key password
     - `ANDROID_KEY_ALIAS`: Your key alias (usually "release")

5. **Update workflow** (uncomment signing steps in `build-android.yml`)

**Download APK/AAB:**
- Go to Actions → Build Android → Latest run
- Scroll down to Artifacts section
- Download `android-apk` or `android-aab`

**Create Release:**
- Create and push a tag:
  ```bash
  git tag v1.0.0
  git push origin v1.0.0
  ```
- Workflow automatically creates a GitHub release with APK/AAB attached

---

### 4. Build macOS (`build-macos.yml`)
**Triggers:** Push to `main`, Tags starting with `v*`, Pull requests, Manual dispatch

**What it does:**
- Builds macOS desktop application
- Creates ZIP archive
- Uploads artifact (available for 30 days)
- Creates GitHub releases when tagged

**Setup Required:**

**For basic builds (unsigned):**
- No setup needed - app will be unsigned

**For signed releases (production):**

1. **Apple Developer Requirements:**
   - Apple Developer account
   - Developer ID Application certificate
   - App-specific password

2. **Add GitHub secrets:**
   - `MACOS_CERTIFICATE_BASE64`: Base64 encoded certificate
   - `MACOS_CERTIFICATE_PASSWORD`: Certificate password
   - `APPLE_ID`: Your Apple ID
   - `APPLE_APP_SPECIFIC_PASSWORD`: App-specific password
   - `APPLE_TEAM_ID`: Your team ID

3. **Update workflow** (see commented signing example in workflow file)

**Download App:**
- Go to Actions → Build macOS → Latest run
- Download `macos-app` artifact
- Extract and run (may need to allow in Security settings for unsigned builds)

---

### 5. Build iOS (`build-ios.yml`)
**Triggers:** Push to `main`, Tags starting with `v*`, Pull requests, Manual dispatch

**What it does:**
- Builds iOS application (unsigned by default)
- Creates IPA archive
- Uploads artifact (available for 30 days)
- Creates GitHub releases when tagged

**Setup Required:**

**For basic builds (unsigned):**
- No setup needed - IPA will be unsigned (cannot be installed on real devices)

**For signed releases (production):**

1. **Apple Developer Requirements:**
   - Apple Developer account ($99/year)
   - iOS Distribution certificate
   - Provisioning profile

2. **Generate certificates:**
   - Use Xcode or Apple Developer Portal
   - Export certificate as P12 file

3. **Add GitHub secrets:**
   - `IOS_CERTIFICATES_P12`: Base64 encoded P12 file
   - `IOS_CERTIFICATES_PASSWORD`: P12 password
   - `IOS_PROVISIONING_PROFILE`: Base64 encoded provisioning profile

4. **Update workflow:**
   - Uncomment the `build-signed` job in `build-ios.yml`

**Download IPA:**
- Go to Actions → Build iOS → Latest run
- Download `ios-app-unsigned` artifact

**Note:** Unsigned IPAs can only be installed on simulators. For real device testing, you need a signed build or use TestFlight.

---

## Common Tasks

### Run workflows manually
1. Go to Actions tab
2. Select the workflow
3. Click "Run workflow"
4. Choose branch and click "Run workflow"

### View workflow status
- Check the Actions tab in your repository
- Green checkmark = Success
- Red X = Failed (click to see logs)
- Yellow dot = In progress

### Download build artifacts
1. Go to Actions → Select workflow run
2. Scroll to "Artifacts" section
3. Click to download

### Create a release
1. Create and push a tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
2. Workflows automatically create GitHub release
3. Built files are attached to the release

---

## Troubleshooting

### Web deployment fails with 404
- Check GitHub Pages settings
- Ensure "Source" is set to "GitHub Actions"
- Wait 5-10 minutes after first deployment

### Android build fails
- Check Java version (requires Java 17)
- Verify `android/app/build.gradle` configuration
- Check for signing configuration errors

### macOS/iOS builds fail
- These require macOS runners (free for public repos)
- Check Xcode version compatibility
- Verify provisioning profiles are valid

### Workflow doesn't trigger
- Check branch names in workflow file
- Ensure workflow file is in `.github/workflows/`
- Check repository settings → Actions (must be enabled)

---

## Security Best Practices

1. **Never commit sensitive files:**
   - ❌ `key.properties`
   - ❌ `release-keystore.jks`
   - ❌ `.p12` certificates
   - ❌ Provisioning profiles

2. **Use GitHub Secrets for:**
   - Signing keys and passwords
   - API keys
   - Firebase configuration (consider using environment-specific configs)

3. **Add to `.gitignore`:**
   ```
   # Android signing
   *.jks
   *.keystore
   key.properties

   # iOS signing
   *.p12
   *.mobileprovision
   *.certSigningRequest
   ```

---

## Current Status

- ✅ CI workflow (testing & linting)
- ✅ Web deployment (GitHub Pages)
- ✅ Android build (unsigned)
- ✅ macOS build (unsigned)
- ✅ iOS build (unsigned)
- ⏳ Signed builds (requires setup)

---

## Next Steps

1. **Test the workflows:**
   - Push to `main` or `Hvan` branch
   - Check Actions tab for results

2. **Set up GitHub Pages:**
   - Follow steps in "Deploy Web" section
   - Access your live web app

3. **Configure signing (optional):**
   - For production releases
   - Follow platform-specific instructions above

4. **Create your first release:**
   ```bash
   git tag v0.1.0
   git push origin v0.1.0
   ```

---

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter CI/CD Guide](https://docs.flutter.dev/deployment/cd)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [iOS Code Signing](https://developer.apple.com/support/code-signing/)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
