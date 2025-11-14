# API Fields Summary - What's Available and What's Needed

Based on the API response from `https://lms.natdemy.com/api/home/?format=json`, here's what's available and what needs to be added to the app:

## ✅ **Currently Implemented in App:**

### 1. **Courses** (`data.courses`)
- ✅ `id` - Course ID
- ✅ `title` - Course title
- ✅ `description` - Course description
- ✅ `thumbnail` - Course thumbnail image
- ✅ `rating` - Course rating
- ✅ `duration_hours` - Duration in hours
- ✅ `duration` - Duration (alternative field) - **NEWLY ADDED**
- ✅ `students_count` / `student_count` - Student count - **HANDLES BOTH**
- ✅ `price` - Course price
- ✅ `lessons_count` - Number of lessons
- ✅ `chapters_count` - Number of chapters
- ✅ `what_youll_learn` - Learning points array
- ✅ `topics` - Course topics - **NEWLY ADDED**

### 2. **Students** (`data.students`)
- ✅ `id` - Student ID
- ✅ `student_id` - Student ID string
- ✅ `name` - Student name
- ✅ `email` - Student email
- ✅ `phone` - Phone number
- ✅ `photo` - Profile photo URL
- ✅ `course` - Enrolled course object
- ✅ `created_at` - Creation date

### 3. **Materials** (`data.materials`) - **NEWLY ADDED**
- ✅ `id` - Material ID
- ✅ `course_id` - Course ID
- ✅ `name` - Material name
- ✅ `url` - Material URL
- ✅ `size_bytes` - File size in bytes
- ✅ `size_label` - Human-readable size
- ✅ `file_type` - File type (pdf, etc.)
- ✅ `uploaded_at` - Upload date

## 📋 **Available in API but NOT Yet Implemented:**

### 1. **Banners** (`data.banners`)
- ⚠️ Currently empty array in API
- **Potential Use**: Home screen banners/carousel
- **Fields Expected** (based on common patterns):
  - `id` - Banner ID
  - `title` - Banner title
  - `image_url` - Banner image
  - `link_url` - Click destination
  - `order` - Display order
  - `is_active` - Active status

### 2. **WhatsApp** (`data.whatsapp`)
- ⚠️ Currently empty array in API
- **Potential Use**: WhatsApp group links/info
- **Fields Expected**:
  - `group_link` - WhatsApp group link
  - `number` - WhatsApp number
  - `description` - Group description

### 3. **Contacts** (`data.contacts`)
- ⚠️ Currently empty array in API
- **Note**: ContactService already exists but uses `/api/contact/` endpoint
- **Potential Use**: Contact information display
- **Fields Expected**:
  - `email` - Contact email
  - `phone` - Contact phone
  - `whatsapp_number` - WhatsApp number
  - `whatsapp_group_link` - WhatsApp group link
  - `website` - Website URL
  - `address` - Physical address
  - `social_media` - Social media links

### 4. **Enrollments** (`data.enrollments`)
- ⚠️ Currently empty array in API
- **Potential Use**: Track user enrollments with additional metadata
- **Fields Expected**:
  - `id` - Enrollment ID
  - `student_id` - Student ID
  - `course_id` - Course ID
  - `enrolled_at` - Enrollment date
  - `progress_percentage` - Progress percentage
  - `last_accessed_at` - Last access date
  - `completed_at` - Completion date (if completed)

## 🎯 **Recommendations for Implementation Priority:**

### **High Priority:**
1. ✅ **Materials** - **DONE** - Now fetches from API
2. **Enrollments** - Would provide better enrollment tracking
3. **Banners** - Could enhance home screen UX

### **Medium Priority:**
4. **WhatsApp** - Could be integrated with existing contact service
5. **Contacts** - Already partially implemented via ContactService

### **Low Priority:**
6. Additional course metadata if needed
7. Analytics/progress tracking if enrollments are implemented

## 📝 **Notes:**

- The API response structure is: `{"data": {"banners": [], "courses": [], "whatsapp": [], "contacts": [], "students": [], "enrollments": [], "materials": []}}`
- Most arrays are currently empty, so the app should handle empty arrays gracefully
- All new fields should have fallback values when API data is unavailable
- The app should continue to work offline with cached/hardcoded data






