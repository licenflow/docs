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
- Learn about [License Validation](../guides/integration.md#license-validation)
- Review [Error Handling](../guides/troubleshooting.md#error-handling)
- Check [Best Practices](../guides/best-practices.md) for secure implementation 