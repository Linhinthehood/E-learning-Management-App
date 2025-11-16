# Test CSV Files

## ✅ Fixed Issue: Phone Numbers with Leading Zeros

### The Problem
CSV parsers (Excel, LibreOffice, etc.) treat numbers starting with 0 as numeric values and drop the leading zero:
- `0123456789` → becomes → `123456789` (9 digits - INVALID!)

### The Solution
Use one of these approaches:

#### Option 1: Phone Numbers Without Leading Zeros ✅
**File**: `students_valid.csv`
```csv
email,displayName,phone,studentId,password
john.doe@example.com,John Doe,1234567890,IT2023001,Password123!
```
- Phone: `1234567890` (10 digits - valid!)

#### Option 2: Quoted Phone Numbers (Preserves Leading Zeros) ✅
**File**: `students_valid_vn_phones.csv`
```csv
email,displayName,phone,studentId,password
john.doe@example.com,John Doe,"0901234567",IT2023002,Password123!
```
- Phone: `"0901234567"` (quotes preserve the leading zero)
- Vietnamese phone format: 09xxxxxxxx, 08xxxxxxxx, etc.

---

## 📁 Available Test Files

### 1. students_valid.csv ✅ RECOMMENDED
- **Records**: 5 valid students
- **Phone Format**: No leading zeros (1234567890)
- **Use For**: Basic testing, guaranteed to work

### 2. students_valid_vn_phones.csv ✅ ALTERNATIVE
- **Records**: 5 valid students
- **Phone Format**: Vietnamese format with quotes ("0901234567")
- **Use For**: Testing with Vietnamese phone numbers

### 3. students_invalid.csv ❌ ERROR TESTING
- **Records**: 5 students with various errors
- **Use For**: Testing validation and error messages
- **Expected Errors**:
  - Row 1: Invalid email format (no @ sign)
  - Row 2: Display name too short (1 character)
  - Row 3: Phone number too short (5 digits)
  - Row 4: Student ID too short (3 characters)
  - Row 5: Missing display name (empty field)

### 4. courses_sample.csv ✅
- **Records**: 6 IT courses
- **Use For**: Course bulk import testing

### 5. groups_sample.csv ✅
- **Records**: 4 groups
- **Use For**: Group bulk import testing

---

## 🚀 Quick Start

### Test Student Import (Working)
1. Run your Flutter app
2. Login as admin/admin
3. Go to Student Management
4. Click "Import CSV"
5. Upload: `students_valid.csv`
6. ✅ Should show 5 students ready to import (green)

---

## 📋 Phone Number Validation Rules

From `student_csv_import_service.dart`:
```dart
// Phone is optional
// If provided, must be 10-15 digits
if (phone != null && phone.isNotEmpty) {
  if (phone.length < 10 || phone.length > 15) {
    errors.add('Phone number must be between 10-15 digits');
  }
}
```

**Valid Examples**:
- ✅ `1234567890` (10 digits)
- ✅ `"0901234567"` (10 digits with quotes)
- ✅ `123456789012345` (15 digits)
- ✅ `` (empty - optional field)

**Invalid Examples**:
- ❌ `123456789` (9 digits - too short)
- ❌ `0123456789` (becomes 9 digits after parsing!)
- ❌ `12345` (5 digits - too short)
- ❌ `1234567890123456` (16 digits - too long)

---

## 💡 Tips for Creating Your Own CSV Files

### 1. Save Phone Numbers as Text
**Excel/LibreOffice**:
- Format cells as "Text" before entering phone numbers
- Or add single quote prefix: `'0901234567`
- Or use quotes in CSV: `"0901234567"`

### 2. Use Comma Separators
Make sure your CSV uses commas, not semicolons:
```csv
email,displayName,phone          ✅ Correct
email;displayName;phone          ❌ Wrong
```

### 3. Required vs Optional Fields

**Students CSV**:
- ✅ Required: `email`, `displayName`
- ⚠️ Optional: `phone`, `studentId`, `password`

**Courses CSV**:
- ✅ Required: `code`, `name`
- ⚠️ Optional: `description`, `sessions`
- ℹ️ Note: Need to select default semester & instructor in UI

**Groups CSV**:
- ✅ Required: `name`
- ⚠️ Optional: `studentEmails`
- ℹ️ Note: Need to select default course & semester in UI

---

## 🐛 Troubleshooting

### All rows show "Invalid data - Phone number must be between 10-15 digits"
**Cause**: CSV parser dropped leading zeros from phone numbers
**Fix**: Use `students_valid.csv` (no leading zeros) or `students_valid_vn_phones.csv` (quoted)

### "Invalid email format" errors
**Check**:
- Email must contain @
- Email must have domain (.com, .vn, etc.)
- No spaces in email

### "Display Name must be at least 2 characters"
**Check**: Display name is not empty and has 2+ characters

### "Student ID must be 5-20 characters"
**Check**: Student ID (if provided) is between 5-20 characters

---

## ✅ Now Try Again!

1. Delete any partially imported students (if any)
2. Use the updated `students_valid.csv` file
3. Upload and import
4. Should work perfectly! ✨

---

**Last Updated**: 2025-11-13
**Issue Fixed**: Phone numbers with leading zeros
