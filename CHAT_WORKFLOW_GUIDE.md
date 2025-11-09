# Chat Workflow Guide

## 📱 Cách Start Chat giữa Student và Instructor

### Workflow Overview

Có **3 cách** để start chat giữa student và instructor:

---

## 1. 🎓 Student Start Chat với Instructor

### Từ Course Detail Screen → People Tab

1. Mở một Course bất kỳ
2. Click vào tab **"People"** (tab cuối cùng)
3. Trong phần **"Instructor"** section, bạn sẽ thấy:
   - Instructor avatar
   - Instructor name
   - Instructor ID
   - **Message button** (icon message) ở bên phải
4. Click vào **Message button**
5. System sẽ:
   - Tạo chat mới (nếu chưa có) hoặc lấy chat đã có
   - Navigate đến Chat Screen
   - Hiển thị conversation với instructor

**Location**: `Course Detail Screen → People Tab → Instructor Section → Message Button`

---

## 2. 👨‍🏫 Instructor Start Chat với Student

### Option A: Từ Course Detail Screen → People Tab

1. Mở một Course bất kỳ (với role Instructor)
2. Click vào tab **"People"**
3. Scroll xuống phần **"Groups & Students"**
4. Expand một group để xem students
5. Mỗi student item sẽ có:
   - Student avatar
   - Student name
   - Student email
   - Student badge
   - **Message button** (icon message) ở bên phải
6. Click vào **Message button** của student bạn muốn chat
7. System sẽ:
   - Tạo chat mới (nếu chưa có) hoặc lấy chat đã có
   - Navigate đến Chat Screen
   - Hiển thị conversation với student

**Location**: `Course Detail Screen → People Tab → Groups → Student Item → Message Button`

### Option B: Từ Student Management Screen

1. Mở **Student Management Screen** (từ Instructor Dashboard → Students)
2. Tìm student bạn muốn chat trong danh sách
3. Mỗi student item sẽ có 3 buttons:
   - **Message button** (icon message) - màu primary
   - Edit button (icon edit)
   - Delete button (icon delete)
4. Click vào **Message button** (button đầu tiên)
5. System sẽ:
   - Tạo chat mới (nếu chưa có) hoặc lấy chat đã có
   - Navigate đến Chat Screen
   - Hiển thị conversation với student

**Location**: `Instructor Dashboard → Students → Student List → Message Button`

---

## 3. 💬 Từ Chat List Screen (FloatingActionButton)

### Cho cả Student và Instructor

1. Click vào **FloatingActionButton** (icon message) ở góc phải dưới màn hình
2. Màn hình **Chat List** sẽ hiển thị
3. Nếu đã có chat với người đó, click vào chat để mở conversation
4. Nếu chưa có chat, bạn cần start chat từ các locations ở trên

**Location**: `Dashboard (bất kỳ screen nào) → FloatingActionButton (góc phải dưới) → Chat List Screen`

---

## 🔄 Chat Flow

```
1. User clicks "Message" button
   ↓
2. System calls getOrCreateChat(studentId, instructorId)
   ↓
3. If chat exists → Return existing chat
   If chat doesn't exist → Create new chat with composite ID
   ↓
4. Navigate to ChatScreen with:
   - chatId: "studentId_instructorId"
   - participantId: The other person's ID
   - participantName: The other person's name
   ↓
5. ChatScreen loads:
   - Real-time messages (Stream)
   - Mark chat as read
   - Display conversation
```

---

## 📍 UI Locations Summary

### Student có thể start chat tại:
1. ✅ **Course Detail Screen → People Tab → Instructor Section → Message Button**

### Instructor có thể start chat tại:
1. ✅ **Course Detail Screen → People Tab → Groups → Student Item → Message Button**
2. ✅ **Student Management Screen → Student List → Message Button**

### Cả Student và Instructor có thể:
1. ✅ **Click FloatingActionButton → Chat List Screen → Select existing chat**

---

## 🎨 UI Features

### Message Button
- **Icon**: `Icons.message` hoặc `Icons.message_outlined`
- **Color**: `AppColors.buttonPrimary`
- **Tooltip**: "Message instructor" hoặc "Message student"
- **Visibility**:
  - Student: Chỉ thấy ở Instructor section
  - Instructor: Chỉ thấy ở Student items

### Loading State
- Hiển thị loading dialog khi đang tạo/lấy chat
- Tự động đóng khi hoàn thành
- Hiển thị error message nếu có lỗi

### Navigation
- Sau khi start chat, navigate đến `ChatScreen`
- Chat Screen sẽ tự động:
  - Load messages (real-time)
  - Mark chat as read
  - Scroll to bottom

---

## 🔧 Technical Details

### Chat ID Format
- **Format**: `studentId_instructorId`
- **Example**: `student123_instructor456`
- **Composite ID**: Đảm bảo mỗi cặp student-instructor chỉ có 1 chat

### getOrCreateChat Logic
1. Check if chat exists với composite ID
2. If exists → Return existing chat
3. If not exists → Create new chat với:
   - `participantIds`: [studentId, instructorId]
   - `studentId`: studentId
   - `instructorId`: instructorId
   - `unreadCountStudent`: 0
   - `unreadCountInstructor`: 0
   - `lastMessage`: ""
   - `lastMessageTimestamp`: DateTime.now()

### User Role Check
- Student chỉ có thể start chat với instructor
- Instructor chỉ có thể start chat với student
- System tự động check role và hiển thị button phù hợp

---

## 📝 Notes

1. **Chat chỉ tồn tại giữa Student và Instructor**: Không có chat giữa student-student hoặc instructor-instructor
2. **Composite ID**: Mỗi cặp student-instructor chỉ có 1 chat duy nhất
3. **Auto-create**: Chat được tạo tự động khi start conversation lần đầu
4. **Real-time**: Messages được stream real-time từ Firestore
5. **Unread Count**: Tự động update khi có message mới

---

## 🧪 Testing

### Test Cases:
- [ ] Student có thể start chat với instructor từ People Tab
- [ ] Instructor có thể start chat với student từ People Tab
- [ ] Instructor có thể start chat với student từ Student Management Screen
- [ ] Chat được tạo với đúng composite ID
- [ ] Existing chat được load đúng
- [ ] Navigation đến ChatScreen hoạt động
- [ ] Loading state hiển thị đúng
- [ ] Error handling hoạt động
- [ ] Role check hoạt động (button chỉ hiển thị đúng role)

---

**End of Chat Workflow Guide**

