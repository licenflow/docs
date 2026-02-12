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

### 3. License Activation & Deactivation
- After validating a license, you may want to control which devices or users are actively using it. LicenFlow provides endpoints to activate (register) and deactivate (release) license instances. This is essential for controlling how many devices/users can use a license simultaneously, and for letting end users or your customers manage their own activations.

### 4. Usage Tracking
- Set up usage reporting
- Implement usage limits
- Handle usage restrictions

## Code Samples

These examples show how to validate a license key in your distributed software. The license key should be provided by your end user.

> **⚠️ CRITICAL: Product Name Must Match Exactly**
> The `product` parameter must match the EXACT product name from your license in LicenFlow.
> Valid values include: `Desktop Application`, `Web Application`, `Mobile Application`, `WordPress Plugin`, or `SaaS Application`.
> You can find your product name by:
> 1. Logging into your LicenFlow dashboard
> 2. Going to the Licenses page
> 3. Looking at the "Product" column for your license
>
> **Common Error:** Using custom names that don't match your license's product field will result in a `400 Bad Request` error with message: `"Invalid license key or product"`

### REST API (Vanilla JavaScript)
```javascript
// Step 1: Get user's license key
const userLicenseKey = getUserLicenseKey();
const productName = 'Desktop Application';  // ⚠️ MUST match your license's product name EXACTLY
const instanceId = generateInstanceId();

// Step 2: Validate the license
fetch('https://api.licenflow.com/api/v1/validate-license', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    license_key: userLicenseKey,
    product: productName,  // ⚠️ This must be an exact match!
    instance_id: instanceId,
    feature_used: 'Core Application'  // Optional: Track which feature is being used
  })
})
.then(res => res.json())
.then(data => {
  if (data.valid) {
    // License is valid - start your application
    startApplication();
  } else {
    // Show error to user
    showLicenseError(data.message);
  }
});
```

### Node.js
```javascript
const axios = require('axios');

// Step 1: Get user's license key
const userLicenseKey = getUserLicenseKey();
const productName = 'Desktop Application';  // ⚠️ MUST match your license's product name EXACTLY
const instanceId = generateInstanceId();

// Step 2: Validate the license
const response = await axios.post(
  'https://api.licenflow.com/api/v1/validate-license',
  {
    license_key: userLicenseKey,
    product: productName,  // ⚠️ This must be an exact match!
    instance_id: instanceId,
    feature_used: 'Core Application'  // Optional: Track which feature is being used
  }
);

if (response.data.valid) {
  // License is valid - start your application
  startApplication();
} else {
  // Show error to user
  showLicenseError(response.data.message);
}
```

### PHP
```php
<?php
// Step 1: Prepare the request data
$userLicenseKey = getUserLicenseKey();
$productName = 'Desktop Application';  // ⚠️ MUST match your license's product name EXACTLY
$instanceId = generateInstanceId();

$data = [
    'license_key' => $userLicenseKey,
    'product' => $productName,  // ⚠️ This must be an exact match!
    'instance_id' => $instanceId,
    'feature_used' => 'Core Application'  // Optional: Track which feature is being used
];

// Step 2: Validate the license
$ch = curl_init('https://api.licenflow.com/api/v1/validate-license');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

$response = curl_exec($ch);
$result = json_decode($response, true);

if ($result['valid']) {
    // License is valid - start your application
    startApplication();
} else {
    // Show error to user
    showLicenseError($result['message']);
}
```

### Python
```python
import requests

# Step 1: Prepare the request data
user_license_key = get_user_license_key()
product_name = 'Desktop Application'  # ⚠️ MUST match your license's product name EXACTLY
instance_id = generate_instance_id()

data = {
    'license_key': user_license_key,
    'product': product_name,  # ⚠️ This must be an exact match!
    'instance_id': instance_id,
    'feature_used': 'Core Application'  # Optional: Track which feature is being used
}

# Step 2: Validate the license
response = requests.post(
    'https://api.licenflow.com/api/v1/validate-license',
    json=data
)

result = response.json()

if result['valid']:
    # License is valid - start your application
    start_application()
else:
    # Show error to user
    show_license_error(result['message'])
```

### Go
```go
import (
    "bytes"
    "encoding/json"
    "net/http"
)

// Step 1: Prepare the request
userLicenseKey := getUserLicenseKey()

data := map[string]string{
    "license_key": userLicenseKey,
    "product":     "Desktop Application",  // ⚠️ MUST match your license's product name EXACTLY
    "instance_id": generateInstanceId(),
    "feature_used": "Core Application",  // Optional: Track which feature is being used
}

// Step 2: Validate the license
jsonData, _ := json.Marshal(data)
resp, err := http.Post(
    "https://api.licenflow.com/api/v1/validate-license",
    "application/json",
    bytes.NewBuffer(jsonData),
)
defer resp.Body.Close()

var result map[string]interface{}
json.NewDecoder(resp.Body).Decode(&result)

if result["valid"].(bool) {
    // License is valid - start your application
    startApplication()
} else {
    // Show error to user
    showLicenseError(result["message"].(string))
}
```

### Java
```java
import java.net.http.*;
import java.net.URI;
import org.json.JSONObject;

// Step 1: Prepare the request
String userLicenseKey = getUserLicenseKey();

JSONObject data = new JSONObject();
data.put("license_key", userLicenseKey);
data.put("product", "Desktop Application");  // ⚠️ MUST match your license's product name EXACTLY
data.put("instance_id", generateInstanceId());
data.put("feature_used", "Core Application");  // Optional: Track which feature is being used

// Step 2: Validate the license
HttpClient client = HttpClient.newHttpClient();
HttpRequest request = HttpRequest.newBuilder()
    .uri(URI.create("https://api.licenflow.com/api/v1/validate-license"))
    .header("Content-Type", "application/json")
    .POST(HttpRequest.BodyPublishers.ofString(data.toString()))
    .build();

HttpResponse<String> response = client.send(request, 
    HttpResponse.BodyHandlers.ofString());

JSONObject result = new JSONObject(response.body());

if (result.getBoolean("valid")) {
    // License is valid - start your application
    startApplication();
} else {
    // Show error to user
    showLicenseError(result.getString("message"));
}
```

> **Important Security Note:** 
> - The `license_key` should come from your end user (not hardcoded)
> - The `product` name is hardcoded in your distributed software
> - Never include your LicenFlow API keys or authentication tokens in distributed software

## Next Steps
- Review [API Documentation](getting-started.md) for detailed endpoint information
- Check [Best Practices](best-practices.md) for integration recommendations
- Consult [Troubleshooting Guide](troubleshooting.md) for error handling and common issues

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
<p>
    <strong>Note:</strong> The `key` field in the response is the one you must use in the URL for future updates or deletions of this license.
</p>

### Updating a License

To update an existing license, send a PUT request to `/api/licenses/{key}` with the fields you want to update:

```json
PUT /api/licenses/XXXX-XXXX-XXXX-XXXX
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

## License Activation & Deactivation

After validating a license, you may want to control which devices or users are actively using it. LicenFlow provides endpoints to activate (register) and deactivate (release) license instances. This is essential for controlling how many devices/users can use a license simultaneously, and for letting end users or your customers manage their own activations.

### Purpose
License activation allows you to register ("activate") a license on a specific device or instance, and deactivation allows you to release that activation. Each activation is tracked as an "instance". You can view and manage all active instances for a license from the LicenFlow portal, and you can also deactivate (disconnect) any instance via the API or the portal. This gives your customers full control over their license usage.

> **Note:** To update an existing license, use the `PUT` method and specify the license `key` in the URL. Only the license owner or an admin can update a license. Here is an example:
</p>
<p class="text-gray-600 mb-2">Headers:</p>
<div class="bg-gray-100 p-4 rounded-md font-mono text-sm mb-4">
<pre>
PUT /api/licenses/XXXX-XXXX-XXXX-XXXX
Authorization: Bearer YOUR_API_KEY
Content-Type: application/json
Accept: application/json
</pre>
</div>

**Request body:**
```json
{
  "license_key": "XXXX-XXXX-XXXX-XXXX",
  "product": "Desktop Application",
  "instance_name": "My_PC"
}
```

**Response:**
```json
{
  "success": true,
  "message": "License successfully activated on instance My_PC",
  "instance_id": "b57a5945a033986448567f93219d46be"
}
```

### Deactivate a License Instance

**Endpoint:**
```
POST /api/licenses/deactivate
```

**Headers:**
```
Authorization: Bearer YOUR_API_KEY
Content-Type: application/json
```

**Request body:**
```json
{
  "license_key": "XXXX-XXXX-XXXX-XXXX",
  "instance_id": "b57a5945a033986448567f93219d46be"
}
```

**Response:**
```json
{
  "success": true,
  "message": "License successfully deactivated on this instance."
}
```

### Instance Control
- Each activation is tracked as an instance.
- You can view and manage all active instances for a license from the LicenFlow portal.
- You can deactivate (disconnect) any instance via the API or the portal.
- Both your end users (from your software) and your customers (from their own scripts or integrations) can use these endpoints to manage activations.
- You can also manage activations manually from the LicenFlow portal.

**Best practice:** Always deactivate an instance when uninstalling or moving your software to a new device, to free up activations for other devices. 