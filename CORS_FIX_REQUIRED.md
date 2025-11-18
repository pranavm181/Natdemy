# 🔴 CORS Configuration Required for Web Browser Support

## Problem
The Flutter web app cannot make API requests to `https://lms.natdemy.com` because the server is not sending the required CORS (Cross-Origin Resource Sharing) headers. This causes all API requests to fail in web browsers with the error:

```
ClientException: Failed to fetch
```

## Affected Endpoints
All API endpoints are affected, including:
- `/api/home/` - Home page data
- `/api/students/register/` - User registration
- `/api/students/login/` - User login
- `/api/courses/` - Course listings
- All other API endpoints

## Solution: Backend Configuration

The backend server at `https://lms.natdemy.com` needs to send CORS headers in all responses.

### For Django (Recommended)

1. **Install django-cors-headers:**
   ```bash
   pip install django-cors-headers
   ```

2. **Add to `settings.py`:**
   ```python
   INSTALLED_APPS = [
       ...
       'corsheaders',
       ...
   ]

   MIDDLEWARE = [
       'corsheaders.middleware.CorsMiddleware',  # Must be near the top
       'django.middleware.common.CommonMiddleware',
       ...
   ]

   # For development (allow all origins)
   CORS_ALLOW_ALL_ORIGINS = True

   # OR for production (specify allowed origins)
   CORS_ALLOWED_ORIGINS = [
       "https://your-flutter-app-domain.com",
       "http://localhost:50000",  # For local development
       "http://127.0.0.1:50000",  # For local development
   ]

   # Allow credentials (cookies, authorization headers)
   CORS_ALLOW_CREDENTIALS = True

   # Allow specific headers
   CORS_ALLOW_HEADERS = [
       'accept',
       'accept-encoding',
       'authorization',
       'content-type',
       'dnt',
       'origin',
       'user-agent',
       'x-csrftoken',
       'x-requested-with',
   ]

   # Allow specific methods
   CORS_ALLOW_METHODS = [
       'DELETE',
       'GET',
       'OPTIONS',
       'PATCH',
       'POST',
       'PUT',
   ]
   ```

3. **Restart the Django server**

### For Other Backend Frameworks

The server must send these HTTP headers in all responses:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH
Access-Control-Allow-Headers: Content-Type, Authorization, Accept
Access-Control-Allow-Credentials: true
```

**Important:** For `OPTIONS` requests (preflight), the server must respond with status `200` or `204` and include the CORS headers.

### Manual Header Addition (If using middleware)

If you're using a different framework, you can add these headers manually:

**Python (Flask example):**
```python
from flask import Flask
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes
```

**Node.js (Express example):**
```javascript
const cors = require('cors');
app.use(cors());
```

## Testing

After implementing CORS:

1. Open browser DevTools (F12)
2. Go to Network tab
3. Try making a request from the Flutter web app
4. Check the response headers - you should see:
   - `Access-Control-Allow-Origin: *` (or your domain)
   - `Access-Control-Allow-Methods: ...`
   - `Access-Control-Allow-Headers: ...`

## Current Workaround

The Flutter app currently uses a fallback (`course_id: 1`) when course fetching fails due to CORS, but the registration endpoint itself still fails. **CORS must be enabled on the backend for the web app to work.**

## Priority

🔴 **CRITICAL** - Without CORS configuration, the Flutter web app cannot function in browsers.









