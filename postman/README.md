# Postman Collection - IELTS Learning Platform

## 📦 Files
- `IELTS_Platform_API.postman_collection.json` - Complete API collection with automated scripts
- `IELTS_Platform_Local.postman_environment.json` - Local environment variables

## 🚀 Quick Start

### 1. Import Collection
1. Open Postman
2. Click **Import** button
3. Select both files:
   - `IELTS_Platform_API.postman_collection.json`
   - `IELTS_Platform_Local.postman_environment.json`

### 2. Select Environment
1. Click environment dropdown (top right)
2. Select **"IELTS Platform - Local"**

### 3. Run Tests
1. Start with **Health Check** to verify service is running
2. Run **Register Student** to create test account
3. Use **Login** to get fresh tokens
4. Test other endpoints with auto-managed tokens

## 🤖 Automated Features

### 1. Automatic Token Management
```javascript
// Pre-request script automatically:
- Checks if access token is expired
- Refreshes token if expires in < 5 minutes
- Updates environment variables
- No manual intervention needed
```

### 2. Auto-Save Tokens
All authentication endpoints automatically save tokens to environment:
- `access_token` - JWT access token
- `refresh_token` - JWT refresh token
- `token_expiry` - Token expiration timestamp
- `user_id` - Current user ID

### 3. Test Automation
Every request includes automatic tests:
- Response time validation (< 2000ms)
- Content-Type verification
- Status code checks
- Response structure validation

### 4. Dynamic Test Data
Registration endpoints auto-generate random emails:
```javascript
student_1234@test.com
instructor_5678@test.com
```

## 📊 Pagination Testing

### All List Endpoints Support Pagination

**Query Parameters:**
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 20, max: 100)
- `pageSize` - Alternative to limit (followers/following endpoints)

**Response Format:**
```json
{
  "success": true,
  "data": {
    "items": [...],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100,
      "total_pages": 5
    }
  }
}
```

**Endpoints với Pagination:**
- ✅ `GET /api/v1/courses?page=1&limit=20`
- ✅ `GET /api/v1/exercises?page=1&limit=20`
- ✅ `GET /api/v1/courses/:id/reviews?page=1&limit=20`
- ✅ `GET /api/v1/courses/my-courses?page=1&limit=20`
- ✅ `GET /api/v1/videos/history?page=1&limit=20`
- ✅ `GET /api/v1/users/me/history?page=1&limit=20`
- ✅ `GET /api/v1/notifications?page=1&limit=20`
- ✅ `GET /api/v1/leaderboard?page=1&limit=50`
- ✅ `GET /api/v1/users/:id/followers?page=1&pageSize=20`
- ✅ `GET /api/v1/users/:id/following?page=1&pageSize=20`

**Auto-Validation Tests:**
All pagination endpoints include automatic tests for:
- ✅ Pagination object exists
- ✅ Contains: page, limit, total, total_pages
- ✅ Values are correct types (numbers)
- ✅ Page >= 1, Limit <= max

## 📋 Collection Structure

### Auth Service (15 endpoints)
1. **Health Check** - Verify service status
2. **Register Student** - Create student account
3. **Register Instructor** - Create instructor account
4. **Login** - Authenticate user
5. **Validate Token** - Verify JWT token
6. **Refresh Token** - Get new access token
7. **Change Password** - Update password
8. **Logout** - Invalidate refresh token
9. **Forgot Password** - Send 6-digit reset code via email (expires 15 min)
10. **Reset Password By Code** - Reset password using 6-digit code
11. **Reset Password (Legacy)** - Reset password using long token from email link
12. **Verify Email By Code** - Verify email using 6-digit code (expires 24 hours)
13. **Verify Email (Legacy)** - Verify email using long token from email link
14. **Resend Verification Code** - Send new 6-digit verification code via email

### User Service (14+ endpoints)
1. **Health Check** - Verify service status
2. **Get Profile** - Get current user profile
3. **Update Profile** - Update user information
4. **Upload Avatar** - Upload profile picture
5. **Get User Stats** - Get learning statistics
6. **Update Preferences** - Update user preferences
7. **Update Progress** - Update learning progress
8. **Get Progress History** - Get study session history

#### Social Features (6 endpoints)
9. **Get Public User Profile** - View another user's public profile (optional auth)
10. **Get Public User Achievements** - View user's public achievements
11. **Follow User** - Follow another user (auth required)
12. **Unfollow User** - Unfollow a user (auth required)
13. **Get User Followers** - Get list of followers (public, paginated)
14. **Get User Following** - Get list of following users (public, paginated)

#### Social Features - Test Scenarios (5 scenarios, 15+ test cases)
Comprehensive test scenarios based on verified test results:
- **Scenario 1: Initial State Check** - Verify empty state
- **Scenario 2: Follow Flow** - Complete follow workflow with verifications
- **Scenario 3: Unfollow Flow** - Complete unfollow workflow
- **Scenario 4: Edge Cases** - Self-follow prevention, unfollow when not following, idempotency
- **Scenario 5: Pagination** - Pagination parameter validation

### Course Service (16 endpoints)

#### Public APIs (3 endpoints)
1. **Get All Courses** - List courses with filters and pagination (no auth required)
   - Params: `page`, `limit`, `skill_type`, `level`, `enrollment_type`, `is_featured`, `search`
   - Response: includes `pagination` object with `total_pages`
2. **Get Course Detail** - View course with modules/lessons (no auth required)
3. **Get Lesson Detail** - View lesson with videos/materials (no auth required)

#### Student APIs (4 endpoints)
4. **Enroll in Course** - Enroll in a course (requires auth)
5. **Get My Enrollments** - List user's enrolled courses with pagination (`page`, `limit`)
6. **Get Enrollment Progress** - View detailed progress per module
7. **Update Lesson Progress** - Track lesson completion and time spent

#### Instructor APIs (5 endpoints)
8. **Create Course** - Create new course (draft status)
9. **Update Course** - Update own course details
10. **Create Module** - Add module to own course
11. **Create Lesson** - Add lesson to own course
12. **Publish Course** - Publish draft course

#### Admin APIs (2 endpoints)
13. **Delete Course** - Soft delete any course (admin only)
14. **Update Any Course** - Update any course regardless of ownership

## 🔧 Environment Variables

### Base Configuration
- `base_url` - API base URL (default: http://localhost:8081)

### Authentication
- `access_token` - Current JWT access token
- `refresh_token` - Current refresh token
- `token_expiry` - Token expiration ISO timestamp
- `user_id` - Current user UUID

### Test Accounts
- `test_student_email` - Auto-generated student email
- `test_student_password` - Student password
- `test_instructor_email` - Auto-generated instructor email
- `test_instructor_password` - Instructor password
- `instructor_access_token` - Instructor JWT token
- `instructor_refresh_token` - Instructor refresh token
- `instructor_token` - Instructor token for Course Service
- `admin_token` - Admin token for privileged operations

### Service URLs
- `user_service_url` - User Service URL (default: http://localhost:8082)
- `course_service_url` - Course Service URL (default: http://localhost:8083)

### Course Service Test Data
- `test_course_id` - Sample course ID (auto-saved from Get All Courses)
- `test_module_id` - Sample module ID (auto-saved from Get Course Detail)
- `test_lesson_id` - Sample lesson ID (auto-saved from Get Course Detail)
- `test_enrollment_id` - User's enrollment ID (auto-saved from Enroll)
- `instructor_course_id` - Course created by instructor (auto-saved)
- `instructor_module_id` - Module created by instructor (auto-saved)
- `instructor_lesson_id` - Lesson created by instructor (auto-saved)
- `course_to_delete` - Course ID for deletion testing

## 🧪 Testing Workflows

### Complete Registration Flow
```
1. Register Student (201 Created)
   → Auto-saves: access_token, refresh_token, user_id
2. Validate Token (200 OK)
   → Verifies token is valid
3. Change Password (200 OK)
   → Updates password
4. Logout (200 OK)
   → Clears all tokens
```

### Token Refresh Flow
```
1. Login (200 OK)
   → Saves tokens with expiry
2. Wait or manually expire token
3. Any authenticated request
   → Pre-request script auto-refreshes token
4. Request proceeds with fresh token
```

### Multi-User Testing
```
1. Register Student
   → Saves to: access_token, user_id
2. Register Instructor
   → Saves to: instructor_access_token
3. Test student endpoints with access_token
4. Test instructor endpoints with instructor_access_token
```

### Password Reset Flow (New - Code-Based)
```
1. Forgot Password (200 OK)
   → Sends 6-digit code to email (expires 15 min)
   → Check email for code
2. Reset Password By Code (200 OK)
   → Input: code + new_password
   → Revokes all refresh tokens for security
3. Login with New Password (200 OK)
   → Verify password changed successfully
```

### Email Verification Flow (New - Code-Based)
```
1. Register Student (201 Created)
   → Account created but email unverified
   → Auto-sends 6-digit verification code (expires 24 hours)
   → Check email for code
2. Verify Email By Code (200 OK)
   → Input: code
   → Marks email as verified
3. Resend Verification Code (200 OK, if needed)
   → Sends new 6-digit code to email
```

### Legacy Token-Based Flows (Backward Compatibility)
```
# Password Reset (Legacy)
1. Forgot Password → Sends long token to email
2. Reset Password → Input: token + new_password

# Email Verification (Legacy)
1. Register → Sends long token to email
2. Verify Email (GET) → Query param: ?token=xxx
```

## 📊 Test Assertions

### Common Tests (All Requests)
```javascript
✓ Response time is less than 2000ms
✓ Response has JSON content type
```

### Registration Tests
```javascript
✓ Status code is 201
✓ Response contains user_id
✓ Response contains access_token
✓ Response contains refresh_token
✓ Role matches requested role
```

### Login Tests
```javascript
✓ Status code is 200
✓ Tokens are present and valid
✓ Environment variables updated
```

### Validation Tests
```javascript
✓ Token is valid
✓ User data is present
✓ Role information correct
```

## 🔐 Security Notes

1. **Token Expiry**: Access tokens expire in 15 minutes by default
2. **Refresh Tokens**: Valid for 7 days
3. **Auto-Refresh**: Triggers 5 minutes before expiry
4. **Logout**: Revokes refresh token immediately
5. **Secrets**: Tokens stored as secret type in environment

## 📝 Scripts Explanation

### Pre-Request Script (Collection Level)
```javascript
// Runs before EVERY request
// Checks token expiry
// Auto-refreshes if needed
// Updates environment variables
```

### Test Script (Collection Level)
```javascript
// Runs after EVERY response
// Validates response time
// Validates content type
// Can be overridden at request level
```

### Request-Specific Scripts
Each endpoint has custom tests for:
- Expected status codes
- Response data structure
- Business logic validation
- Environment variable management

## 🎯 Testing Scenarios

### Course Creation Workflow (Instructor)
```
1. Login as Instructor
   → Saves instructor_token
2. Create Course (POST /admin/courses)
   → Auto-saves instructor_course_id
   → Course status: draft
3. Create Module (POST /admin/modules)
   → Auto-saves instructor_module_id
4. Create Lesson (POST /admin/lessons)
   → Auto-saves instructor_lesson_id
5. Publish Course (POST /admin/courses/:id/publish)
   → Course status: published
```

### Student Enrollment Workflow
```
1. Login as Student
   → Saves access_token
2. Browse Courses (GET /courses)
   → Auto-saves test_course_id
3. View Course Detail (GET /courses/:id)
   → Auto-saves test_module_id, test_lesson_id
4. Enroll in Course (POST /enrollments)
   → Auto-saves test_enrollment_id
5. View My Enrollments (GET /enrollments/my)
   → See all enrolled courses
6. Update Lesson Progress (PUT /progress/lessons/:id)
   → Track completion and time
7. Check Progress (GET /enrollments/:id/progress)
   → View per-module completion
```

### Permission Testing
```
1. Instructor creates course A
2. Different instructor tries to update course A
   → Should fail with 403 Forbidden
3. Admin updates course A
   → Should succeed (admin has full permissions)
4. Instructor tries to delete course A
   → Should fail with 403 Forbidden
5. Admin deletes course A
   → Should succeed (soft delete)
```

## 🎯 Next Steps

### Add More Services
As new microservices are implemented, add folders:
- ✅ Auth Service (Completed)
- ✅ User Service (Completed)
- ✅ Course Service (Completed)
- ✅ Exercise Service (Completed with pagination)
- ✅ Notification Service (Completed with pagination)
- AI Service (Coming soon)

### Environment Setup
Create additional environments:
- `IELTS Platform - Dev` (port 8081)
- `IELTS Platform - Staging` (staging URL)
- `IELTS Platform - Production` (production URL)
- `IELTS Platform - Production` (prod URL)

### CI/CD Integration
```bash
# Run collection with Newman CLI
newman run IELTS_Platform_API.postman_collection.json \
  -e IELTS_Platform_Local.postman_environment.json \
  --reporters cli,json
```

## 🐛 Troubleshooting

### Token Not Refreshing
- Check `refresh_token` exists in environment
- Verify `token_expiry` format is ISO 8601
- Check console logs for errors

### 401 Unauthorized
- Run **Login** to get fresh tokens
- Check token hasn't been revoked (logout)
- Verify environment is selected

### Random Emails Not Generating
- Check pre-request script is enabled
- Verify JavaScript console for errors
- Manually set email if needed

## 📖 References
- [Postman Documentation](https://learning.postman.com/)
- [JWT Best Practices](https://jwt.io/introduction)
- [Collection Scripts](https://learning.postman.com/docs/writing-scripts/intro-to-scripts/)
