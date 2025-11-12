# 📋 API Data Requirements for NATDEMY App

This document lists all the data points you need from your backend API to integrate with the Flutter app.

---

## 🔐 **1. Authentication & User Management**

### **POST /api/auth/register** (Sign Up)
**Request Body:**
- `name` (string, required)
- `email` (string, required, unique)
- `phone` (string, required, min 7 characters)
- `password` (string, required, min 6 characters)

**Response:**
- `token` (string) - JWT authentication token
- `user` (object):
  - `id` (string) - User ID
  - `name` (string)
  - `email` (string)
  - `phone` (string)
  - `profile_image_url` (string, nullable) - URL to profile image

---

### **POST /api/auth/login** (Sign In)
**Request Body:**
- `email` (string, required)
- `password` (string, required)

**Response:**
- `token` (string) - JWT authentication token
- `user` (object):
  - `id` (string)
  - `name` (string)
  - `email` (string)
  - `phone` (string)
  - `profile_image_url` (string, nullable)

---

### **POST /api/auth/logout** (Logout)
**Headers:**
- `Authorization: Bearer {token}`

**Response:**
- `message` (string) - Success message

---

### **POST /api/auth/refresh** (Refresh Token)
**Headers:**
- `Authorization: Bearer {token}`

**Response:**
- `token` (string) - New JWT token

---

### **GET /api/users/:userId** (Get User Profile)
**Headers:**
- `Authorization: Bearer {token}`

**Response:**
- `id` (string)
- `name` (string)
- `email` (string)
- `phone` (string)
- `profile_image_url` (string, nullable)

---

### **PUT /api/users/:userId** (Update User Profile)
**Headers:**
- `Authorization: Bearer {token}`
- `Content-Type: multipart/form-data` (if uploading image)

**Request Body:**
- `name` (string, optional)
- `phone` (string, optional)
- `profile_image` (file, optional) - Image file

**Response:**
- `id` (string)
- `name` (string)
- `email` (string)
- `phone` (string)
- `profile_image_url` (string, nullable)

---

## 📚 **2. Courses**

### **GET /api/courses** (Get All Courses)
**Headers:**
- `Authorization: Bearer {token}` (optional, for personalized data)

**Response:**
```json
[
  {
    "id": "course_123",
    "title": "Flutter Basics",
    "description": "Build beautiful cross-platform apps with Flutter. Learn widgets, layouts, state, and navigation.",
    "what_youll_learn": [
      "Comprehensive curriculum covering all fundamentals",
      "Hands-on projects and practical exercises",
      "Expert guidance and support throughout",
      "Lifetime access to course materials"
    ],
    "rating": 4.7,
    "color": 4294947051,
    "thumbnail_url": "https://example.com/images/flutter_course.jpg",
    "duration_hours": 40,
    "student_count": 1250,
    "price": 0,
    "lessons_count": 16,
    "chapters_count": 4
  }
]
```

**Data Points:**
- `id` (string, required) - Unique course identifier (needed for API operations)
- `title` (string, required)
- `description` (string, required) - **Used for "ABOUT THIS COURSE" section**
- `what_youll_learn` (array of strings, required) - **List of learning points for "WHAT YOU'LL LEARN" section**
  - Example: `["Comprehensive curriculum covering all fundamentals", "Hands-on projects and practical exercises", "Expert guidance and support throughout", "Lifetime access to course materials"]`
- `rating` (number, 0-5) - Average rating
- `color` (number) - Color value as integer (for UI theming, e.g., 0xFFFF6B6B = 4294947051)
- `thumbnail_url` (string, nullable) - **Course image URL (used for course display)**
- `duration_hours` (number, nullable) - **Total course duration in hours (displayed in stats)**
- `student_count` (number, nullable) - **Number of enrolled students (displayed in stats)**
- `price` (number) - **Course price (0 for free courses)**
- `lessons_count` (number) - **Total number of lessons in the course**
- `chapters_count` (number) - **Total number of chapters in the course**

---

### **GET /api/courses/:courseId** (Get Course Details)
**Headers:**
- `Authorization: Bearer {token}` (optional)

**Response:**
- All fields from "Get All Courses" plus:
- `is_enrolled` (boolean) - Whether current user is enrolled (only if authenticated)
- `progress_percentage` (number, 0-100) - User's progress (only if enrolled)

---

## 🎓 **3. Course Enrollment**

### **GET /api/users/:userId/courses** (Get User's Enrolled Courses)
**Headers:**
- `Authorization: Bearer {token}`

**Response:**
```json
[
  {
    "id": "enrollment_123",
    "course": {
      "id": "course_123",
      "title": "Flutter Basics",
      "description": "Build beautiful cross-platform apps with Flutter...",
      "what_youll_learn": ["..."],
      "rating": 4.7,
      "color": 4294947051,
      "thumbnail_url": "https://example.com/images/flutter_course.jpg",
      "duration_hours": 40,
      "student_count": 1250,
      "price": 0,
      "lessons_count": 16,
      "chapters_count": 4
    },
    "enrolled_at": "2024-01-20T10:00:00Z",
    "progress_percentage": 45.5,
    "last_accessed_at": "2024-02-15T14:30:00Z"
  }
]
```

**Data Points:**
- `id` (string) - Enrollment ID
- `course` (object) - Full course object (same structure as course detail)
- `enrolled_at` (string) - Enrollment date
- `progress_percentage` (number, 0-100) - User's progress in the course
- `last_accessed_at` (string, nullable) - Last time user accessed the course

---

### **POST /api/users/:userId/courses** (Join/Enroll in Course)
**Headers:**
- `Authorization: Bearer {token}`
- `Content-Type: application/json`

**Request Body:**
- `course_id` (string, required)

**Response:**
- Same as enrollment object from "Get User's Enrolled Courses"

---

### **DELETE /api/users/:userId/courses/:courseId** (Leave Course)
**Headers:**
- `Authorization: Bearer {token}`

**Response:**
- `message` (string) - Success message

---

## 📖 **4. Course Chapters & Lessons**

### **GET /api/courses/:courseId/chapters** (Get Course Chapters)
**Headers:**
- `Authorization: Bearer {token}` (optional)

**Response:**
```json
[
  {
    "id": "chapter_123",
    "course_id": "course_123",
    "title": "Intro to Flutter",
    "order": 1,
    "is_completed": false
  }
]
```

**Data Points:**
- `id` (string) - Chapter ID
- `course_id` (string) - Parent course ID
- `title` (string) - Chapter name
- `order` (number) - Display order (1, 2, 3...)
- `is_completed` (boolean) - Whether user completed chapter (only if user is enrolled)

---

### **GET /api/chapters/:chapterId/lessons** (Get Chapter Lessons)
**Headers:**
- `Authorization: Bearer {token}` (optional)

**Response:**
```json
[
  {
    "id": "lesson_123",
    "chapter_id": "chapter_123",
    "title": "Introduction to Flutter",
    "order": 1,
    "is_completed": false,
    "is_locked": false
  }
]
```

**Data Points:**
- `id` (string) - Lesson ID
- `chapter_id` (string) - Parent chapter ID
- `title` (string) - Lesson name
- `order` (number) - Display order within chapter
- `is_completed` (boolean) - Completion status (only if user is enrolled)
- `is_locked` (boolean) - Whether lesson is locked (prerequisite not met)

---

## 🎥 **5. Lesson Videos**

### **GET /api/lessons/:lessonId/videos** (Get Lesson Videos)
**Headers:**
- `Authorization: Bearer {token}` (required if lesson is locked)

**Response:**
```json
[
  {
    "id": "video_123",
    "lesson_id": "lesson_123",
    "name": "Video 1: What is Flutter?",
    "order": 1,
    "vimeo_id": "357274789",  // Vimeo video ID
    "duration_seconds": 600,
    "thumbnail_url": "https://example.com/thumbnails/video_123.jpg",
    "is_watched": false,  // Only if user is enrolled
    "watched_duration_seconds": 0,  // How much user has watched
    "last_watched_at": null  // Last time user watched this video
  }
]
```

**Data Points:**
- `id` (string) - Video ID
- `lesson_id` (string) - Parent lesson ID
- `name` (string) - Video title/name
- `order` (number) - Display order
- `vimeo_id` (string) - Vimeo video ID (number from URL)
- `duration_seconds` (number) - Video length
- `thumbnail_url` (string, nullable) - Video thumbnail
- `is_watched` (boolean) - Whether user watched video (if enrolled)
- `watched_duration_seconds` (number) - Progress in seconds
- `last_watched_at` (string, nullable) - Last watch timestamp

---

### **POST /api/videos/:videoId/watch** (Mark Video as Watched)
**Headers:**
- `Authorization: Bearer {token}`

**Request Body:**
- `watched_duration_seconds` (number, optional) - How much was watched
- `is_completed` (boolean, optional) - Whether video was fully watched

**Response:**
- `message` (string) - Success message
- `progress` (object) - Updated progress data

---

## 📄 **6. Course Materials (PDFs)**

### **GET /api/courses/:courseId/materials** (Get Course Materials)
**Headers:**
- `Authorization: Bearer {token}` (optional)

**Response:**
```json
[
  {
    "id": "material_123",
    "course_id": "course_123",
    "name": "Flutter Widgets Guide",
    "url": "https://example.com/materials/widgets_guide.pdf",
    "size_bytes": 1258291,
    "size_label": "1.2 MB",
    "file_type": "pdf",
    "uploaded_at": "2024-01-15T10:00:00Z"
  }
]
```

**Data Points:**
- `id` (string) - Material ID
- `course_id` (string) - Parent course ID
- `name` (string) - Material name/title
- `url` (string) - Direct download/view URL
- `size_bytes` (number) - File size in bytes
- `size_label` (string) - Human-readable size (e.g., "1.2 MB")
- `file_type` (string) - File type (usually "pdf")
- `uploaded_at` (string) - Upload date

---

### **GET /api/lessons/:lessonId/materials** (Get Lesson Materials)
**Headers:**
- `Authorization: Bearer {token}` (optional)

**Response:**
- Same structure as course materials, but filtered by lesson

---

## 📅 **7. Live Classes / Scheduled Classes**

### **GET /api/classes** (Get Upcoming/Live Classes)
**Headers:**
- `Authorization: Bearer {token}` (optional)

**Query Parameters:**
- `status` (string, optional) - Filter: "upcoming", "live", "completed"
- `course_id` (string, optional) - Filter by course

**Response:**
```json
[
  {
    "id": "class_123",
    "course_id": "course_123",
    "title": "Live Q&A Session",
    "teacher": "John Doe",
    "start_time": "2024-02-20T14:00:00Z",
    "end_time": "2024-02-20T15:30:00Z",
    "video_url": "https://example.com/live/stream_123",
    "thumbnail_url": "https://example.com/thumbnails/class_123.jpg",
    "status": "upcoming"
  }
]
```

**Data Points:**
- `id` (string) - Class ID
- `course_id` (string, nullable) - Associated course (if any)
- `title` (string) - Class title
- `teacher` (string) - Teacher/instructor name
- `start_time` (string, ISO 8601) - Class start time
- `end_time` (string, ISO 8601) - Class end time
- `video_url` (string, nullable) - Live stream URL or recording URL
- `thumbnail_url` (string, nullable) - Class thumbnail
- `status` (string) - "upcoming", "live", or "completed"

---

### **POST /api/classes/:classId/register** (Register for Class)
**Headers:**
- `Authorization: Bearer {token}`

**Response:**
- `message` (string) - Success message
- `class` (object) - Updated class object with `is_registered: true`

---

## 📊 **8. Progress & Analytics** (Optional but Recommended)

### **GET /api/users/:userId/progress** (Get User Progress)
**Headers:**
- `Authorization: Bearer {token}`

**Response:**
```json
{
  "total_courses_enrolled": 5,
  "total_lessons_completed": 32,
  "completion_percentage": 45.5
}
```

**Note:** This endpoint is optional and can be implemented later if needed.

---

## 🔔 **9. Notifications** (Optional - Not Currently Used)

**Note:** This feature is not currently implemented in the app. Can be added in future updates.

---

## 📝 **10. Error Responses**

All endpoints should return consistent error responses:

**Error Response Format:**
```json
{
  "error": true,
  "message": "Error message here",
  "code": "ERROR_CODE",  // Optional: Error code
  "details": {}  // Optional: Additional error details
}
```

**Common HTTP Status Codes:**
- `200` - Success
- `201` - Created (for POST requests)
- `400` - Bad Request (validation errors)
- `401` - Unauthorized (invalid/missing token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `500` - Internal Server Error

---

## 🔑 **11. Authentication Headers**

All protected endpoints require:
```
Authorization: Bearer {jwt_token}
```

Token should be included in request headers for:
- User-specific data
- Enrollment actions
- Progress tracking
- Profile updates

---

## 📌 **Summary Checklist**

✅ **Authentication:**
- [ ] Register endpoint
- [ ] Login endpoint
- [ ] Logout endpoint
- [ ] Token refresh endpoint
- [ ] JWT token generation

✅ **User Management:**
- [ ] Get user profile
- [ ] Update user profile
- [ ] Profile image upload

✅ **Courses:**
- [ ] Get all courses
- [ ] Get course details
- [ ] Course enrollment
- [ ] Get enrolled courses
- [ ] Leave course

✅ **Content:**
- [ ] Get course chapters
- [ ] Get chapter lessons
- [ ] Get lesson videos
- [ ] Get course materials
- [ ] Get lesson materials
- [ ] Video watch tracking

✅ **Classes:**
- [ ] Get live/upcoming classes
- [ ] Register for class

✅ **Optional:**
- [ ] User progress/analytics
- [ ] Notifications
- [ ] Search functionality
- [ ] Course reviews/ratings

---

## 🎯 **Priority Order for Implementation**

1. **Authentication** (Login/Register) - Required first
2. **Courses** (List & Details) - Core functionality
3. **Enrollment** - User can join courses
4. **Chapters & Lessons** - Course content structure
5. **Videos** - Video playback
6. **Materials** - PDF access
7. **Classes** - Live classes feature
8. **Progress** - User analytics (can be added later)

---

**Note:** All date/time fields should be in ISO 8601 format (e.g., `"2024-02-15T14:30:00Z"`).

**Image URLs:** Should be publicly accessible URLs or require authentication token in headers.

**File URLs:** PDF and video URLs should be direct download/stream URLs or use signed URLs with expiration.

