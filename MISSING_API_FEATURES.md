# Missing API Features - What the App Needs But API Doesn't Provide

This document lists features that the app currently has (with hardcoded/mock data) but are **NOT available in the API** and need to be added to the backend.

---

## 🔐 **1. Authentication & Authorization** - **CRITICAL MISSING**

### **Current State:**
- ❌ Login screen accepts any email/password (no validation)
- ❌ No password verification
- ❌ No JWT token authentication
- ❌ No user registration API
- ❌ No logout API
- ❌ No token refresh mechanism

### **What's Needed from API:**

#### **POST /api/auth/login** (Sign In)
**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```
**Response:**
```json
{
  "token": "jwt_token_here",
  "user": {
    "id": 11,
    "name": "Rasana Favi kt",
    "email": "rasanafavi@gmail.com",
    "phone": "8590354372",
    "photo": "/media/students/photos/..."
  }
}
```

#### **POST /api/auth/register** (Sign Up)
**Request:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "1234567890",
  "password": "password123"
}
```
**Response:** Same as login

#### **POST /api/auth/logout**
**Headers:** `Authorization: Bearer {token}`
**Response:**
```json
{
  "message": "Logged out successfully"
}
```

#### **POST /api/auth/refresh** (Refresh Token)
**Headers:** `Authorization: Bearer {token}`
**Response:**
```json
{
  "token": "new_jwt_token"
}
```

**Priority:** 🔴 **CRITICAL** - Without this, the app has no real security

---

## 📖 **2. Course Chapters & Lessons Structure** - **HIGH PRIORITY**

### **Current State:**
- ❌ All chapters and lessons are hardcoded in `lessons_config.dart`
- ❌ No API endpoint to fetch course structure
- ❌ App shows chapters/lessons but they're not from API

### **What's Needed from API:**

#### **GET /api/courses/:courseId/chapters**
**Response:**
```json
[
  {
    "id": 1,
    "course_id": 1,
    "title": "Intro to Flutter",
    "order": 1,
    "is_completed": false
  }
]
```

#### **GET /api/chapters/:chapterId/lessons**
**Response:**
```json
[
  {
    "id": 1,
    "chapter_id": 1,
    "title": "Introduction to Flutter",
    "order": 1,
    "is_completed": false,
    "is_locked": false
  }
]
```

**Priority:** 🟠 **HIGH** - Core functionality for course navigation

---

## 🎥 **3. Lesson Videos** - **HIGH PRIORITY**

### **Current State:**
- ❌ All videos are hardcoded in `lesson_videos_config.dart`
- ❌ Uses same Vimeo ID for all videos (357274789)
- ❌ No API endpoint to fetch lesson videos
- ❌ No video watch tracking

### **What's Needed from API:**

#### **GET /api/lessons/:lessonId/videos**
**Response:**
```json
[
  {
    "id": 1,
    "lesson_id": 1,
    "name": "Video 1: What is Flutter?",
    "order": 1,
    "vimeo_id": "357274789",
    "duration_seconds": 600,
    "thumbnail_url": "https://example.com/thumbnails/video_1.jpg",
    "is_watched": false,
    "watched_duration_seconds": 0,
    "last_watched_at": null
  }
]
```

#### **POST /api/videos/:videoId/watch** (Track Video Progress)
**Request:**
```json
{
  "watched_duration_seconds": 300,
  "is_completed": false
}
```

**Priority:** 🟠 **HIGH** - Essential for video learning

---

## 📅 **4. Live Classes / Scheduled Classes** - **MEDIUM PRIORITY**

### **Current State:**
- ❌ All classes are mock data in `classes.dart`
- ❌ No API endpoint for live/upcoming classes
- ❌ No class registration

### **What's Needed from API:**

#### **GET /api/classes**
**Query Params:** `?status=upcoming&course_id=1`
**Response:**
```json
[
  {
    "id": 1,
    "course_id": 1,
    "title": "Live Q&A Session",
    "teacher": "John Doe",
    "start_time": "2024-02-20T14:00:00Z",
    "end_time": "2024-02-20T15:30:00Z",
    "video_url": "https://example.com/live/stream_123",
    "thumbnail_url": "https://example.com/thumbnails/class_1.jpg",
    "status": "upcoming"
  }
]
```

#### **POST /api/classes/:classId/register**
**Response:**
```json
{
  "message": "Registered successfully",
  "class": { ... }
}
```

**Priority:** 🟡 **MEDIUM** - Nice to have feature

---

## 💾 **5. Profile Updates** - **MEDIUM PRIORITY**

### **Current State:**
- ❌ Profile updates only save locally (SharedPreferences)
- ❌ No API endpoint to update profile
- ❌ No profile image upload to server

### **What's Needed from API:**

#### **PUT /api/users/:userId** (Update Profile)
**Headers:** `Authorization: Bearer {token}`, `Content-Type: multipart/form-data`
**Request:**
- `name` (string, optional)
- `phone` (string, optional)
- `profile_image` (file, optional)

**Response:**
```json
{
  "id": 11,
  "name": "Updated Name",
  "email": "rasanafavi@gmail.com",
  "phone": "8590354372",
  "photo": "/media/students/photos/updated.jpg"
}
```

**Priority:** 🟡 **MEDIUM** - Users expect profile changes to persist

---

## 🔑 **6. Password Change** - **MEDIUM PRIORITY**

### **Current State:**
- ❌ Password change UI exists but only simulates (no API call)
- ❌ No API endpoint for password change

### **What's Needed from API:**

#### **POST /api/users/:userId/change-password**
**Headers:** `Authorization: Bearer {token}`
**Request:**
```json
{
  "current_password": "oldpassword",
  "new_password": "newpassword"
}
```
**Response:**
```json
{
  "message": "Password changed successfully"
}
```

**Priority:** 🟡 **MEDIUM** - Security feature

---

## 🎓 **7. Course Enrollment Actions** - **HIGH PRIORITY**

### **Current State:**
- ❌ "Join Course" only saves locally (SharedPreferences)
- ❌ No API call to actually enroll in course
- ❌ No API call to leave/unenroll from course

### **What's Needed from API:**

#### **POST /api/users/:userId/courses** (Enroll in Course)
**Headers:** `Authorization: Bearer {token}`
**Request:**
```json
{
  "course_id": 1
}
```
**Response:**
```json
{
  "id": "enrollment_123",
  "course": { ... },
  "enrolled_at": "2024-01-20T10:00:00Z",
  "progress_percentage": 0
}
```

#### **DELETE /api/users/:userId/courses/:courseId** (Leave Course)
**Headers:** `Authorization: Bearer {token}`
**Response:**
```json
{
  "message": "Successfully left the course"
}
```

**Priority:** 🟠 **HIGH** - Core enrollment functionality

---

## 📊 **8. Progress Tracking** - **MEDIUM PRIORITY**

### **Current State:**
- ❌ No progress tracking
- ❌ No completion status
- ❌ No analytics

### **What's Needed from API:**

#### **GET /api/users/:userId/progress**
**Response:**
```json
{
  "total_courses_enrolled": 5,
  "total_lessons_completed": 32,
  "completion_percentage": 45.5,
  "courses": [
    {
      "course_id": 1,
      "progress_percentage": 60,
      "lessons_completed": 8,
      "total_lessons": 12
    }
  ]
}
```

**Priority:** 🟡 **MEDIUM** - Good for user engagement

---

## 📄 **9. Lesson-Specific Materials** - **LOW PRIORITY**

### **Current State:**
- ✅ Course materials are now supported from API
- ❌ Lesson-specific materials not yet implemented

### **What's Needed from API:**

#### **GET /api/lessons/:lessonId/materials**
**Response:** Same structure as course materials

**Priority:** 🟢 **LOW** - Can use course materials for now

---

## 🔍 **10. Search Functionality** - **LOW PRIORITY**

### **Current State:**
- ❌ No search feature in app
- ❌ No API endpoint for searching courses

### **What's Needed from API:**

#### **GET /api/courses/search?q=flutter**
**Response:** Filtered list of courses

**Priority:** 🟢 **LOW** - Nice to have

---

## 📝 **Summary - Priority Order (UPDATED)**

**Note:** Lessons and videos will be in the `enrollments` field. Live classes are NOT being implemented.

### **🔴 CRITICAL (Must Have - Do First):**
1. **Authentication** - Login, Register, Logout, Token management
   - Without this, app has no real security
   - **BLOCKING ISSUE** - Must be implemented immediately

### **🟠 HIGH PRIORITY (Core Features - Do Next):**
2. **Enrollments with Course Structure** - Include chapters, lessons, videos in enrollments array
   - This replaces separate chapters/lessons/videos endpoints
   - Structure: `enrollments[].chapters[].lessons[].videos[]`
3. **Enrollment Actions** - Join/Leave courses via API
   - `POST /api/users/:userId/courses` - Join course
   - `DELETE /api/users/:userId/courses/:courseId` - Leave course
4. **Video Watch Tracking** - Track video progress
   - `POST /api/videos/:videoId/watch` - Update watch progress

### **🟡 MEDIUM PRIORITY (Important but Not Blocking):**
5. **Profile Updates** - Save profile changes to API
   - `PUT /api/users/:userId` - Update profile
6. **Password Change** - Security feature
   - `POST /api/users/:userId/change-password`

### **❌ NOT NEEDED (Removed from Priority):**
- ~~Live Classes~~ - Not being implemented
- ~~Separate Chapters API~~ - Will be in enrollments
- ~~Separate Lessons API~~ - Will be in enrollments
- ~~Separate Videos API~~ - Will be in enrollments

---

## 🎯 **Current Workarounds:**

The app currently uses:
- ✅ **Hardcoded data** for chapters, lessons, videos
- ✅ **Local storage** (SharedPreferences) for enrollments
- ✅ **Mock data** for classes
- ✅ **No authentication** - just checks if student exists by email

**These workarounds allow the app to function, but:**
- Data doesn't sync across devices
- No real user authentication
- No progress tracking
- Limited scalability

---

## 📌 **Recommendation:**

**Phase 1 (Critical):**
1. Implement authentication endpoints (login, register, logout)
2. Add JWT token support

**Phase 2 (Core Features):**
3. Add chapters/lessons endpoints
4. Add videos endpoint
5. Add enrollment endpoints (join/leave)

**Phase 3 (Enhancements):**
6. Profile update endpoint
7. Password change endpoint
8. Progress tracking

**Phase 4 (Nice to Have):**
9. Live classes
10. Search functionality

