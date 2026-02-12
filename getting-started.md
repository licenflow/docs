# Getting Started with LicenFlow API

## Quick Start

### 1. Register Your Application
1. Log in to your LicenFlow account
2. Navigate to the Developer Portal
3. Create a new application
4. Note your Client ID and Client Secret

### 2. Get Your Access Token
```bash
curl -X POST https://api.licenflow.com/oauth/token \
  -H "Content-Type: application/json" \
  -d '{
    "client_id": "your_client_id",
    "client_secret": "your_client_secret",
    "grant_type": "client_credentials"
  }'
```

Response:
```json
{
  "access_token": "your_access_token",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

### 3. Make Your First API Call
```bash
curl -X GET https://api.licenflow.com/v1/licenses/validate \
  -H "Authorization: Bearer your_access_token" \
  -H "Content-Type: application/json" \
  -d '{
    "license_key": "your_license_key"
  }'
```

## Authentication Basics

### OAuth2 Flow
1. Obtain Client Credentials
2. Request Access Token
3. Use Token in API Requests
4. Refresh Token when Expired

### Token Management
- Tokens expire after 1 hour
- Store tokens securely
- Implement token refresh
- Handle token errors

## Next Steps
- Learn about [License Validation](integration.md#license-validation)
- Review [Error Handling](troubleshooting.md#error-handling)
- Check [Best Practices](best-practices.md) for secure implementation

## Initial Integration: Creating and Updating a License

Before you can validate a license, you need to create one using the API. Here is how you can do it:

### Create a License

**Endpoint:**
```
POST /api/licenses
```

**Headers:**
```
Authorization: Bearer YOUR_API_KEY
Content-Type: application/json
Accept: application/json
```

**Request body:**
```json
{
  "product": "WordPress Plugin",
  "status": "active",
  "valid_until": "2025-12-31",
  "max_activations": 1,
  "metadata": {
    "license_type": "subscription",
    "plugin_version": "1.0.0",
    "wordpress_version": "6.0+"
  }
}
```

**Response:**
```json
{
  "data": {
    "key": "XXXX-XXXX-XXXX-XXXX",
    "user_id": 1,
    "product": "WordPress Plugin",
    "status": "active",
    "valid_until": "2025-12-31T00:00:00.000000Z",
    "max_activations": 1,
    "current_activations": 0,
    "metadata": {
      "license_type": "subscription",
      "plugin_version": "1.0.0",
      "wordpress_version": "6.0+"
    },
    "updated_at": "2025-05-13T09:22:25.000000Z",
    "created_at": "2025-05-13T09:22:25.000000Z",
    "id": 6,
    "key": "XXXX-XXXX-XXXX-XXXX"   // <--- This is the Key you must use in the URL for updates
  },
  "message": "License created successfully"
}
```

> **Tip:** Save the `key` from the response for license validation, updates, and deletions.

### Update a License

To update an existing license, use the `PUT` method and specify the license `key` in the URL. Only the license owner or an admin can update a license.

**Headers:**
```
PUT /api/licenses/XXXX-XXXX-XXXX-XXXX
Authorization: Bearer YOUR_API_KEY
Content-Type: application/json
Accept: application/json
```

**Request body:**
```json
{
  "product": "WordPress Plugin",
  "status": "active",
  "valid_until": "2025-11-30",
  "max_activations": 1,
  "metadata": {
    "license_type": "subscription",
    "plugin_version": "1.0.0",
    "wordpress_version": "6.0+"
  }
}
```

**Response:**
```json
{
  "data": {
    "id": 4,
    "key": "92D7D3-EA259C-10EFFB-1E5B68", // <--- This is the license Key used in the URL
    "user_id": 1,
    "product": "WordPress Plugin",
    "status": "active",
    "valid_until": "2025-11-30T00:00:00.000000Z",
    "max_activations": 1,
    "current_activations": 0,
    "last_check": null,
    "metadata": {
      "license_type": "subscription",
      "plugin_version": "1.0.0",
      "wordpress_version": "6.0+"
    },
    "created_at": "2025-05-13T06:16:20.000000Z",
    "updated_at": "2025-05-13T10:34:15.000000Z",
    "customer_id": null,
    "product_id": null
  },
  "message": "License updated successfully"
}
```

> **Note:** The `key` field in the response is the one you must use in the URL for future updates or deletions of this license. 