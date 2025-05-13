# Integration Guide

## Getting Started

### Prerequisites
- Valid LicenFlow account
- API credentials (Client ID and Secret)
- Development environment with HTTP client capabilities

### Initial Setup
1. Register your application in the LicenFlow portal
2. Obtain your API credentials
3. Configure your development environment
4. Test the connection with a simple validation request

## Integration Steps

### 1. Authentication
- Obtain access token using OAuth2
- Include token in all API requests
- Handle token expiration and refresh

### 2. License Validation
- Implement validation endpoint calls
- Handle different validation scenarios
- Manage validation responses

### 3. Usage Tracking
- Set up usage reporting
- Implement usage limits
- Handle usage restrictions

## Code Samples

### PHP Example
```php
<?php
$client = new LicenFlowClient([
    'client_id' => 'your_client_id',
    'client_secret' => 'your_client_secret'
]);

try {
    $license = $client->validateLicense('your_license_key');
    if ($license->isValid()) {
        // Proceed with application
    }
} catch (LicenFlowException $e) {
    // Handle error
}
```

### Python Example
```python
from licenflow import Client

client = Client(
    client_id='your_client_id',
    client_secret='your_client_secret'
)

try:
    license = client.validate_license('your_license_key')
    if license.is_valid:
        # Proceed with application
except LicenFlowError as e:
    # Handle error
```

### JavaScript Example
```javascript
const LicenFlow = require('licenflow');

const client = new LicenFlow.Client({
    clientId: 'your_client_id',
    clientSecret: 'your_client_secret'
});

client.validateLicense('your_license_key')
    .then(license => {
        if (license.isValid) {
            // Proceed with application
        }
    })
    .catch(error => {
        // Handle error
    });
```

## Next Steps
- Review [API Documentation](../api/overview.md) for detailed endpoint information
- Check [Best Practices](../guides/best-practices.md) for integration recommendations
- Consult [Troubleshooting Guide](../guides/troubleshooting.md) for error handling and common issues

## Allowed values for Product and License Type

When creating or updating a license via the API, the following fields only accept the values listed below. If you send any other value, the request will be rejected.

### Product

The `product` field must match exactly one of the predefined values. You can retrieve the list of valid products by calling the following endpoint:

```
GET /api/products
```

Example response:
```json
{
  "data": [
    { "id": 1, "name": "WordPress Plugin" },
    { "id": 2, "name": "Desktop Application" },
    { "id": 3, "name": "Mobile Application" },
    { "id": 4, "name": "Web Application" },
    { "id": 5, "name": "SaaS Application" }
  ]
}
```

> **Note:** You must use the exact value from the `name` field. If your organization has custom products, they will appear in this list.

If the products table is empty, the following default values are used:

| Value                | Description                    |
|----------------------|--------------------------------|
| WordPress Plugin     | Plugin for WordPress sites      |
| Desktop Application  | Standalone desktop software     |
| Mobile Application   | App for mobile devices          |
| Web Application      | Web-based application           |
| SaaS Application     | Software as a Service           |

Example usage:
```json
{
  "product": "Web Application"
}
```

### License Type

The `license_type` field only accepts the following values:

| Value        | Description                                         |
|--------------|-----------------------------------------------------|
| trial        | Trial - Free use during a limited period            |
| subscription | Subscription - Recurring fee for access             |
| perpetual    | Perpetual - One-time payment for indefinite use     |
| freemium     | Freemium - Basic free version with premium features |
| usage        | Usage-based - Payment based on actual usage         |
| floating     | Floating - Limited number of simultaneous users     |
| node-locked  | Node-locked - Tied to specific device or user       |
| api          | API - Access for integration with other applications|

Example:

```json
{
  "license_type": "subscription"
}
```

Make sure to send exactly one of the allowed values. Any other value will be rejected by the system.

## Example: Creating a License

To create a license, send a POST request to `/api/licenses` with the required fields:

```json
POST /api/licenses
{
  "product": "Web Application",
  "license_type": "subscription",
  "status": "active",
  "valid_until": "2025-12-31",
  "max_activations": 5,
  "metadata": {
    "end_user": {
      "email": "user@example.com",
      "name": "John Doe"
    }
  }
}
```

The response will include the created license:

```json
{
    "data": {
        "key": "XXXX-XXXX-XXXX-XXXX",
        "user_id": 1,
        "product": "Web Application",
        "license_type": "subscription",
        "status": "active",
        "valid_until": "2025-12-31T00:00:00.000000Z",
        "max_activations": 5,
        "current_activations": 0,
        "metadata": {
            "end_user": {
                "email": "user@example.com",
                "name": "John Doe"
            }
        },
        "updated_at": "2025-05-13T21:30:13.000000Z",
        "created_at": "2025-05-13T21:30:13.000000Z",
        "id": 15
    },
    "message": "License created successfully"
}
```

### Updating a License

To update an existing license, send a PUT request to `/api/licenses/{id}` with the fields you want to update:

```json
PUT /api/licenses/15
{
  "product": "Web Application",
  "license_type": "subscription",
  "status": "active",
  "valid_until": "2025-11-30",
  "max_activations": 5,
  "metadata": {
    "end_user": {
      "email": "user@example.com",
      "name": "John Doe"
    }
  }
}
```

The response will include the updated license:

```json
{
    "data": {
        "id": 15,
        "key": "XXXX-XXXX-XXXX-XXXX",
        "user_id": 1,
        "product": "Web Application",
        "license_type": "subscription",
        "status": "active",
        "valid_until": "2025-11-30T00:00:00.000000Z",
        "max_activations": 5,
        "current_activations": 0,
        "metadata": {
            "end_user": {
                "email": "user@example.com",
                "name": "John Doe"
            }
        },
        "created_at": "2025-05-13T21:30:13.000000Z",
        "updated_at": "2025-05-13T21:35:20.000000Z"
    },
    "message": "License updated successfully"
}
```

> **Note:** You must include a valid access token in the Authorization header for all API requests. 