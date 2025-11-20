# CI/CD Workflow Diagram

## Optimized Release Workflow (release.yml)

When you push a version tag (`v1.0.0`):

```
┌─────────────────────────────────────────────────────────┐
│  STEP 1: Run Tests (Once)                               │
│  ┌───────────────────────────────────┐                  │
│  │  • Run all 34 tests               │                  │
│  │  • If ANY test fails → STOP       │                  │
│  │  • If all pass → Continue          │                  │
│  └───────────────────────────────────┘                  │
└─────────────────────────────────────────────────────────┘
                        ↓
                   Tests PASS ✅
                        ↓
┌─────────────────────────────────────────────────────────┐
│  STEP 2: Create GitHub Release                          │
│  ┌───────────────────────────────────┐                  │
│  │  • Generate release notes         │                  │
│  │  • Create release on GitHub       │                  │
│  └───────────────────────────────────┘                  │
└─────────────────────────────────────────────────────────┘
                        ↓
                 Release Created ✅
                        ↓
┌─────────────────────────────────────────────────────────┐
│  STEP 3: Build All Platforms (Parallel)                 │
│                                                          │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │   Android   │  │   Windows    │  │     Web      │   │
│  │   Build     │  │    Build     │  │    Build     │   │
│  │             │  │              │  │              │   │
│  │ Build APK   │  │  Build EXE   │  │  Build HTML  │   │
│  │  (arm64)    │  │   (x64)      │  │  renderer    │   │
│  │             │  │              │  │              │   │
│  │ Upload to   │  │  Upload to   │  │  Upload to   │   │
│  │  Release    │  │   Release    │  │   Release    │   │
│  └─────────────┘  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────┘
                        ↓
                 All Builds Complete ✅
                        ↓
┌─────────────────────────────────────────────────────────┐
│  STEP 4: Deploy Web to GitHub Pages                     │
│  ┌───────────────────────────────────┐                  │
│  │  • Upload web build to Pages      │                  │
│  │  • Deploy to public URL           │                  │
│  └───────────────────────────────────┘                  │
└─────────────────────────────────────────────────────────┘
                        ↓
                  DONE! 🎉
```

---

## Timeline Example

**Trigger**: `git push origin v1.0.0`

| Time | Step | Status |
|------|------|--------|
| 0:00 | Tests start | Running... |
| 0:45 | Tests complete | ✅ All 34 pass |
| 0:46 | Create release | Running... |
| 0:50 | Release created | ✅ Created |
| 0:51 | Android build starts | Running... |
| 0:51 | Windows build starts | Running... |
| 0:51 | Web build starts | Running... |
| 2:15 | Android complete | ✅ APK uploaded |
| 2:30 | Windows complete | ✅ EXE uploaded |
| 1:45 | Web complete | ✅ ZIP uploaded |
| 2:35 | Deploy to Pages | Running... |
| 2:45 | Pages deployed | ✅ Live |

**Total Time**: ~2:45 minutes

---

## Key Benefits

### ✅ Tests Run Once
- **Before**: Tests ran 3 times (once per platform)
- **After**: Tests run 1 time total
- **Savings**: 66% reduction in test time

### ✅ Fail Fast
- If tests fail, **no builds run at all**
- Saves ~2 minutes of wasted build time
- No broken releases published

### ✅ Parallel Builds
- All platforms build simultaneously
- Total build time = slowest platform
- Not sum of all platforms

### ✅ Quality Gate
- **No release without passing tests**
- Automated quality assurance
- Prevents broken deployments

---

## Individual Build Workflows

### build-android.yml
```
Tests → Build APK → Upload Artifact
```
**When**: Push to main, PR, manual trigger

### build-windows.yml
```
Tests → Build EXE → Upload Artifact
```
**When**: Push to main, PR, manual trigger

### deploy-web.yml
```
Tests → Build Web → Deploy to GitHub Pages
```
**When**: Push to main, manual trigger

### ci.yml
```
Format Check → Analyze → Tests → Check Dependencies
```
**When**: Every push, every PR

---

## What Happens If Tests Fail?

```
┌─────────────────────────────────────┐
│  Tests Running...                   │
│  ┌───────────────────────┐          │
│  │  32/34 tests passed   │          │
│  │  2 tests FAILED ❌     │          │
│  └───────────────────────┘          │
└─────────────────────────────────────┘
              ↓
      Workflow STOPS ⛔
              ↓
┌─────────────────────────────────────┐
│  • No release created               │
│  • No builds run                    │
│  • No deployment happens            │
│  • GitHub shows red X on commit     │
└─────────────────────────────────────┘
              ↓
      Fix the failing tests
              ↓
      Push fix and try again
```

---

**Last Updated**: 2025-11-20
**Workflow Version**: Optimized (tests run once)
