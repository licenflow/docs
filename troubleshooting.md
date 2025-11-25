# Troubleshooting Guide

## Common HTTP Status Codes

| Code | Description | Typical Cause | Solution |
|------|-------------|---------------|----------|
| 400 | Bad Request | Invalid or missing request parameters | Verify all required fields are present and correctly formatted |
| 401 | Unauthorized | Missing or invalid API credentials | Check your API key and ensure it's included in the Authorization header |
| 404 | Not Found | Invalid endpoint or license key not found | Verify the endpoint URL and that the license key exists |
| 422 | Unprocessable Entity | Validation error on submitted data | Check the error response for specific field validation failures |
| 429 | Too Many Requests | Rate limit exceeded | Implement exponential backoff and reduce request frequency |
| 500 | Internal Server Error | Server-side issue | Retry the request; if persistent, contact support |

## License Validation Issues

### Issue: "License not found"

**Symptom:** API returns `{"valid": false, "message": "License not found"}`

**Possible Causes:**
1. License key is incorrect or has typos
2. License was deleted from the system
3. License key format is invalid (missing dashes, etc.)

**Solutions:**
```javascript
// Verify license key format before sending
function isValidLicenseFormat(key) {
  // LicenFlow format: XXXXXX-XXXXXX-XXXXXX-XXXXXX
  const pattern = /^[A-Z0-9]{6}-[A-Z0-9]{6}-[A-Z0-9]{6}-[A-Z0-9]{6}$/;
  return pattern.test(key);
}

if (!isValidLicenseFormat(licenseKey)) {
  showError('Invalid license key format');
  return;
}
```

### Issue: "License has expired"

**Symptom:** API returns `{"valid": false, "message": "License has expired"}`

**Cause:** The `valid_until` date has passed

**Solutions:**

1. **For end users**: Prompt them to renew their license
```javascript
if (response.message === 'License has expired') {
  showRenewalDialog({
    message: 'Your license expired on ' + response.expired_date,
    renewalUrl: 'https://yourdomain.com/renew'
  });
}
```

2. **For administrators**: Update the license expiration date via API
```bash
curl -X PUT https://api.licenflow.com/api/licenses/{license_id} \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{"valid_until": "2026-12-31"}'
```

### Issue: "Maximum activations reached"

**Symptom:** API returns `{"success": false, "message": "This license has reached the maximum number of allowed activations"}`

**Cause:** The license is already activated on the maximum number of devices specified by `max_activations`

**Solutions:**

1. **Ask user to deactivate an old device:**
```javascript
async function handleMaxActivations(licenseKey) {
  const message = `
    This license is already active on the maximum number of devices.
    Please deactivate the license on another device first, or contact support.
  `;

  const action = await showDialog({
    title: 'Activation Limit Reached',
    message: message,
    buttons: ['Manage Devices', 'Contact Support', 'Cancel']
  });

  if (action === 'Manage Devices') {
    openUrl('https://yourdomain.com/my-licenses');
  }
}
```

2. **Increase activation limit** (if you're the license owner):
```bash
curl -X PUT https://api.licenflow.com/api/licenses/{license_id} \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{"max_activations": 5}'
```

### Issue: "License is not active"

**Symptom:** API returns `{"valid": false, "message": "This license is not active and cannot be used"}`

**Cause:** License status is set to `expired`, `suspended`, or another non-active state

**Solutions:**

1. Check the license status via API:
```bash
curl -X GET https://api.licenflow.com/api/licenses \
  -H "Authorization: Bearer YOUR_API_KEY"
```

2. Reactivate the license (if you have permissions):
```bash
curl -X PUT https://api.licenflow.com/api/licenses/{license_id} \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{"status": "active"}'
```

## Activation & Deactivation Issues

### Issue: Unable to deactivate license

**Symptom:** Deactivation endpoint returns `{"success": false, "message": "Instance not found"}`

**Cause:** The `instance_id` provided doesn't match any active instance for that license

**Solutions:**

1. **Ensure you're using the correct instance_id:**
```javascript
// Store instance_id when activating
async function activateLicense(licenseKey, product, instanceName) {
  const instanceId = generateInstanceId();

  const response = await fetch('https://api.licenflow.com/api/licenses/activate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ license_key: licenseKey, product, instance_name: instanceName })
  });

  const result = await response.json();

  if (result.success) {
    // IMPORTANT: Save this for later deactivation
    localStorage.setItem('license_instance_id', result.instance_id);
  }

  return result;
}

// Retrieve the same instance_id when deactivating
async function deactivateLicense(licenseKey) {
  const instanceId = localStorage.getItem('license_instance_id');

  if (!instanceId) {
    console.error('Instance ID not found');
    return;
  }

  const response = await fetch('https://api.licenflow.com/api/licenses/deactivate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ license_key: licenseKey, instance_id: instanceId })
  });

  return await response.json();
}
```

2. **List all active instances** (requires admin access):
```bash
curl -X GET https://api.licenflow.com/api/licenses/{license_id}/instances \
  -H "Authorization: Bearer YOUR_API_KEY"
```

## Network and Connectivity Issues

### Issue: Connection timeout or network errors

**Symptom:** Requests fail with network errors, timeouts, or no response

**Causes:**
1. No internet connection
2. Firewall blocking outbound HTTPS
3. DNS resolution failure
4. API server temporarily unavailable

**Solutions:**

1. **Implement timeout and retry logic:**
```javascript
async function validateWithTimeout(licenseKey, timeoutMs = 10000) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch('https://api.licenflow.com/api/v1/validate-license', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ license_key: licenseKey, product: 'Your Product' }),
      signal: controller.signal
    });

    clearTimeout(timeout);
    return await response.json();
  } catch (error) {
    clearTimeout(timeout);

    if (error.name === 'AbortError') {
      throw new Error('Request timed out after ' + timeoutMs + 'ms');
    }
    throw error;
  }
}
```

2. **Implement offline grace period:**
```javascript
async function validateWithGracePeriod(licenseKey) {
  try {
    const result = await validateLicense(licenseKey);
    // Save successful validation timestamp
    localStorage.setItem('last_validation', Date.now());
    localStorage.setItem('last_validation_result', JSON.stringify(result));
    return result;
  } catch (networkError) {
    // Check if we have a recent successful validation
    const lastValidation = localStorage.getItem('last_validation');
    const gracePeriod = 72 * 60 * 60 * 1000; // 72 hours

    if (lastValidation && (Date.now() - lastValidation < gracePeriod)) {
      const cachedResult = JSON.parse(localStorage.getItem('last_validation_result'));
      console.warn('Using cached validation (offline mode)');
      return { ...cachedResult, offline: true };
    }

    throw networkError;
  }
}
```

3. **Check firewall and proxy settings:**
- Ensure outbound HTTPS (port 443) is allowed
- Verify DNS can resolve `api.licenflow.com`
- Check if corporate proxy requires configuration

### Issue: CORS errors in browser

**Symptom:** Browser console shows CORS errors when calling the API

**Cause:** LicenFlow API should not be called directly from browser JavaScript in production

**Solution:**

For browser-based applications, validate licenses through your own backend:

```javascript
// ❌ WRONG - Direct API call from browser exposes credentials
fetch('https://api.licenflow.com/api/licenses', {
  headers: { 'Authorization': 'Bearer YOUR_API_KEY' } // Exposed to users!
});

// ✅ CORRECT - Call your own backend
fetch('https://your-backend.com/api/validate-license', {
  method: 'POST',
  body: JSON.stringify({ license_key: userLicenseKey })
});
```

Then on your backend:
```javascript
// your-backend/api/validate-license
app.post('/api/validate-license', async (req, res) => {
  const { license_key } = req.body;

  const response = await fetch('https://api.licenflow.com/api/v1/validate-license', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.LICENFLOW_API_KEY}`, // Secure
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      license_key,
      product: 'Your Product Name',
      instance_id: generateInstanceId(req)
    })
  });

  const result = await response.json();
  res.json(result);
});
```

## Product and Validation Errors

### Issue: "Product does not match"

**Symptom:** License validation fails even though the key is correct

**Cause:** The `product` field in the validation request doesn't match the product assigned to the license

**Solution:**

```javascript
// Ensure product name matches EXACTLY (case-sensitive)
const PRODUCT_NAME = 'WordPress Plugin'; // Must match the value in LicenFlow

// Validate with exact product name
const response = await fetch('https://api.licenflow.com/api/v1/validate-license', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    license_key: userLicenseKey,
    product: PRODUCT_NAME, // Exact match required
    instance_id: instanceId
  })
});
```

Retrieve valid products programmatically:
```bash
curl -X GET https://api.licenflow.com/api/products \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Issue: Invalid license_type when creating license

**Symptom:** API returns validation error: "The license type field must be one of: trial, subscription, perpetual..."

**Cause:** Using an invalid or misspelled value for `license_type`

**Solution:**

Use only these exact values (case-sensitive):

```javascript
const VALID_LICENSE_TYPES = [
  'trial',
  'subscription',
  'perpetual',
  'freemium',
  'usage',
  'floating',
  'node-locked',
  'api'
];

// When creating a license
const licenseData = {
  product: 'Web Application',
  license_type: 'subscription', // Must be one of the values above
  status: 'active',
  valid_until: '2026-12-31',
  max_activations: 3
};
```

## Debugging Tips

### Enable Verbose Logging

Add detailed logging to troubleshoot issues:

```javascript
function logLicenseOperation(operation, data, result) {
  const log = {
    timestamp: new Date().toISOString(),
    operation: operation,
    request: data,
    response: result,
    environment: getEnvironmentInfo()
  };

  console.log('[LicenFlow]', JSON.stringify(log, null, 2));

  // Send to your logging service
  if (process.env.NODE_ENV === 'production') {
    sendToLogService(log);
  }
}

// Usage
const result = await validateLicense(licenseKey);
logLicenseOperation('validate', { license_key: licenseKey }, result);
```

### Test with cURL

Isolate issues by testing directly with cURL:

```bash
# Test license validation
curl -v -X POST https://api.licenflow.com/api/v1/validate-license \
  -H "Content-Type: application/json" \
  -d '{
    "license_key": "XXXXXX-XXXXXX-XXXXXX-XXXXXX",
    "product": "Your Product Name",
    "instance_id": "test-instance-123"
  }'

# Test license activation
curl -v -X POST https://api.licenflow.com/api/licenses/activate \
  -H "Content-Type: application/json" \
  -d '{
    "license_key": "XXXXXX-XXXXXX-XXXXXX-XXXXXX",
    "product": "Your Product Name",
    "instance_name": "Test Device"
  }'
```

The `-v` flag shows detailed request/response headers for debugging.

### Check API Response Format

Always check the structure of error responses:

```javascript
async function validateLicenseWithErrorHandling(licenseKey) {
  try {
    const response = await fetch('https://api.licenflow.com/api/v1/validate-license', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ license_key: licenseKey, product: 'Your Product' })
    });

    const data = await response.json();

    // Log full response for debugging
    console.log('Response status:', response.status);
    console.log('Response data:', JSON.stringify(data, null, 2));

    if (!response.ok) {
      console.error('HTTP error:', response.status, data);
      return { valid: false, error: data };
    }

    return data;
  } catch (error) {
    console.error('Request failed:', error);
    throw error;
  }
}
```

## Getting Help

If you're still experiencing issues after trying these solutions:

1. **Check API Status**: Verify the API is operational
2. **Review Documentation**: Consult the [Integration Guide](integration.md) and [Best Practices](best-practices.md)
3. **Contact Support**: Provide the following information:
   - Exact error message or HTTP status code
   - Request payload (without sensitive credentials)
   - Expected vs. actual behavior
   - Steps to reproduce the issue
   - Your integration environment (language, framework, OS) 