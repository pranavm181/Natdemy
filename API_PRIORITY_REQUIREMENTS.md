# 🎯 API Requirements - Maximum Priority Features

Based on the current API structure from [https://lms.natdemy.com/api/home/?format=json](https://lms.natdemy.com/api/home/?format=json), here are the **CRITICAL** and **HIGH PRIORITY** features needed.

**Note:** Lessons and videos will be provided in the `enrollments` field, and live classes are not being implemented.

---

## 🔴 **CRITICAL PRIORITY - Must Have Immediately**

### **1. Authentication System** ⚠️ **BLOCKING ISSUE**

**Current Problem:**
- App accepts any password (no verification)
- No real user authentication
- No security

**Required API Endpoints:**

#### **POST /api/auth/login**
**Request:**
```json
{
  "email": "rasanafavi@gmail.com",
  "password": "user_password"
}
```
**Response:**
```json
{
  "token": "jwt_token_string",
  "user": {
    "id": 11,
    "student_id": "523423",
    "name": "Rasana Favi kt",
    "email": "rasanafavi@gmail.com",
    "phone": "8590354372",
    "photo": "/media/students/photos/37f7d486-2cb6-4ef7-b6f6-0973dd333192_IgZX5rv.jpeg"
  }
}
```

#### **POST /api/auth/register**
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

**Why Critical:** Without authentication, the app has no security. Anyone can access any account.

---

## 🟠 **HIGH PRIORITY - Core Functionality**

### **2. Enrollments with Course Structure** 

**Expected Structure in `enrollments` array:**

```json
{
  "data": {
    "enrollments": [
      {
        "id": 1,
        "student_id": 11,
        "course_id": 1,
        "enrolled_at": "2025-10-29T10:00:57.010006+05:30",
        "progress_percentage": 45.5,
        "last_accessed_at": "2025-11-15T14:30:00Z",
        "course": {
          "id": 1,
          "title": "NIOS MARCH | HUMANITIES",
          "description": "HUMANITIES FOR NIOS MARCH BATCH STUDENTS",
          "thumbnail": "/media/courses/thumbnails/NIOS_MARCH_HUM_l7PGNKc.jpg",
          "rating": null,
          "price": "0.00"
        },
        "chapters": [
          {
            "id": 1,
            "course_id": 1,
            "title": "Chapter 1: Introduction",
            "order": 1,
            "is_completed": false,
            "lessons": [
              {
                "id": 1,
                "chapter_id": 1,
                "title": "Lesson 1: Getting Started",
                "order": 1,
                "is_completed": false,
                "is_locked": false,
                "videos": [
                  {
                    "id": 1,
                    "lesson_id": 1,
                    "name": "Video 1: Introduction",
                    "order": 1,
                    "vimeo_id": "357274789",
                    "duration_seconds": 600,
                    "thumbnail_url": "https://example.com/thumbnails/video_1.jpg",
                    "is_watched": false,
                    "watched_duration_seconds": 0,
                    "last_watched_at": null
                  }
                ],
                "materials": [
                  {
                    "id": 1,
                    "lesson_id": 1,
                    "name": "Lesson Notes",
                    "url": "/media/materials/lesson_1_notes.pdf",
                    "size_bytes": 1258291,
                    "size_label": "1.2 MB",
                    "file_type": "pdf"
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  }
}
```

**Required Fields in Enrollments:**
- `id` - Enrollment ID
- `student_id` - Student ID
- `course_id` - Course ID
- `enrolled_at` - Enrollment date
- `progress_percentage` - Progress (0-100)
- `last_accessed_at` - Last access time
- `course` - Full course object
- `chapters` - Array of chapters with:
  - `id`, `title`, `order`, `is_completed`
  - `lessons` - Array of lessons with:
    - `id`, `title`, `order`, `is_completed`, `is_locked`
    - `videos` - Array of videos with:
      - `id`, `name`, `order`, `vimeo_id`, `duration_seconds`
      - `thumbnail_url`, `is_watched`, `watched_duration_seconds`
    - `materials` - Array of materials (optional)

**Why High Priority:** This is the core learning experience - users need to access course content.

---

### **3. Course Enrollment Actions**

**Required API Endpoints:**

#### **POST /api/users/:userId/courses** (Join/Enroll)
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
  "id": 1,
  "student_id": 11,
  "course_id": 1,
  "enrolled_at": "2025-11-20T10:00:00Z",
  "progress_percentage": 0,
  "course": { ... },
  "chapters": [ ... ]
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

**Why High Priority:** Users need to be able to join and leave courses.

---

### **4. Video Watch Tracking**

**Required API Endpoint:**

#### **POST /api/videos/:videoId/watch**
**Headers:** `Authorization: Bearer {token}`
**Request:**
```json
{
  "watched_duration_seconds": 300,
  "is_completed": false
}
```
**Response:**
```json
{
  "message": "Progress updated",
  "video": {
    "id": 1,
    "is_watched": false,
    "watched_duration_seconds": 300,
    "last_watched_at": "2025-11-20T14:30:00Z"
  }
}
```

**Why High Priority:** Track user progress through videos.

---

## 🟡 **MEDIUM PRIORITY - Important but Not Blocking**

### **5. Profile Updates**

#### **PUT /api/users/:userId**
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

### **6. Password Change**

#### **POST /api/users/:userId/change-password**
**Headers:** `Authorization: Bearer {token}`
**Request:**
```json
{
  "current_password": "oldpassword",
  "new_password": "newpassword"
}
```

---

## ✅ **Already Available in API (No Action Needed):**

- ✅ Courses list (`data.courses`)
- ✅ Students data (`data.students`)
- ✅ Materials (`data.materials`) - Now implemented
- ✅ Course fields: `topics`, `duration` - Now implemented

---

## 📋 **Summary - Implementation Order**

### **Phase 1 - CRITICAL (Do First):**
1. ✅ **Authentication** - Login, Register, Logout endpoints
   - Without this, app has no security

### **Phase 2 - HIGH PRIORITY (Do Next):**
2. ✅ **Enrollments Structure** - Include chapters, lessons, videos in enrollments
3. ✅ **Enrollment Actions** - Join/Leave course endpoints
4. ✅ **Video Tracking** - Track video watch progress

### **Phase 3 - MEDIUM PRIORITY (Can Wait):**
5. ✅ **Profile Updates** - Update user profile endpoint
6. ✅ **Password Change** - Change password endpoint

---

## 🎯 **Expected Enrollments API Response Format**

Based on your note that lessons and videos will be in enrollments, the structure should be:

```json
{
  "data": {
    "enrollments": [
      {
        "id": 1,
        "student_id": 11,
        "course_id": 1,
        "enrolled_at": "2025-10-29T10:00:57.010006+05:30",
        "progress_percentage": 45.5,
        "last_accessed_at": "2025-11-15T14:30:00Z",
        "course": { /* course object */ },
        "chapters": [
          {
            "id": 1,
            "title": "Chapter Title",
            "order": 1,
            "is_completed": false,
            "lessons": [
              {
                "id": 1,
                "title": "Lesson Title",
                "order": 1,
                "is_completed": false,
                "is_locked": false,
                "videos": [
                  {
                    "id": 1,
                    "name": "Video Name",
                    "vimeo_id": "357274789",
                    "duration_seconds": 600,
                    "is_watched": false
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  }
}
```

---

## ⚠️ **Current Blockers:**

1. **No Authentication** - App cannot verify user identity
2. **No Course Structure** - Cannot display chapters/lessons/videos
3. **No Enrollment Actions** - Cannot join/leave courses via API
4. **No Progress Tracking** - Cannot track video watch progress

**These must be implemented for the app to function properly.**






