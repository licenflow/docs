# Integration Best Practices

## Security Considerations

### API Credentials Management

**Never hardcode credentials in distributed software**

When integrating LicenFlow into your application, distinguish between two types of credentials:

1. **End-user license keys**: These should be entered by your customers and validated against the API
2. **Your API authentication**: These should NEVER be included in client-side or distributed software

```javascript
// ❌ WRONG - Never do this in distributed software
const API_KEY = "sk_live_abc123...";

// ✅ CORRECT - License keys come from the end user
const userLicenseKey = getUserInput(); // From UI or config
validateLicense(userLicenseKey); // No API key needed for validation
```

For administrative operations (creating, updating licenses), use environment variables on your server:

```bash
# .env file (never commit to version control)
LICENFLOW_API_KEY=your_api_key_here
LICENFLOW_SECRET=your_secret_here
```

### Secure License Storage

Store validated licenses securely in your application:

```javascript
// Encrypt license data before storing locally
const encryptedLicense = encrypt(licenseData);
localStorage.setItem('app_license', encryptedLicense);

// Decrypt when needed
const licenseData = decrypt(localStorage.getItem('app_license'));
```

### HTTPS Only

Always use HTTPS endpoints for all API requests. LicenFlow API only accepts HTTPS connections to ensure data encryption in transit.

## Performance Optimization

### Cache Validation Results

Reduce API calls by caching validation responses with appropriate Time-To-Live (TTL):

```javascript
const CACHE_TTL = 24 * 60 * 60 * 1000; // 24 hours

async function validateLicenseWithCache(licenseKey) {
  const cached = getCachedValidation(licenseKey);

  if (cached && (Date.now() - cached.timestamp < CACHE_TTL)) {
    return cached.result;
  }

  const result = await validateLicense(licenseKey);
  saveCachedValidation(licenseKey, result);
  return result;
}
```

**Recommendation**: For production applications, cache validation results for 12-24 hours and re-validate on application restart.

### Offline Validation Support

For desktop applications, implement a grace period for offline scenarios:

```javascript
async function validateWithGracePeriod(licenseKey) {
  try {
    return await validateLicense(licenseKey);
  } catch (networkError) {
    // Allow 72-hour grace period for network issues
    const lastValidation = getLastValidationTime(licenseKey);
    const gracePeriod = 72 * 60 * 60 * 1000; // 72 hours

    if (Date.now() - lastValidation < gracePeriod) {
      return { valid: true, offline: true };
    }
    throw networkError;
  }
}
```

### Instance ID Generation

Generate consistent instance IDs to track activations properly:

```javascript
function generateInstanceId() {
  // Use hardware identifiers that persist across restarts
  const machineId = getMachineId(); // CPU ID, MAC address, etc.
  const appId = 'your-app-name';
  return hashSHA256(`${appId}-${machineId}`);
}
```

## Error Handling Best Practices

### Handle All Response Scenarios

The validation endpoint returns different responses based on license status:

```javascript
async function handleLicenseValidation(licenseKey, product, instanceId) {
  try {
    const response = await fetch('https://api.licenflow.com/api/v1/validate-license', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ license_key: licenseKey, product, instance_id: instanceId })
    });

    const data = await response.json();

    if (data.valid) {
      return { success: true, license: data };
    } else {
      // Handle specific error cases
      switch (data.message) {
        case 'License not found':
          showError('Invalid license key');
          break;
        case 'License has expired':
          showError('Your license has expired. Please renew.');
          break;
        case 'Maximum activations reached':
          showError('License limit reached. Deactivate other devices first.');
          break;
        default:
          showError('License validation failed: ' + data.message);
      }
      return { success: false, reason: data.message };
    }
  } catch (error) {
    console.error('Validation error:', error);
    return { success: false, reason: 'Network error', error };
  }
}
```

### Implement Retry Logic with Exponential Backoff

Handle temporary network issues gracefully:

```javascript
async function validateWithRetry(licenseKey, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await validateLicense(licenseKey);
    } catch (error) {
      if (i === maxRetries - 1) throw error;

      const delay = Math.pow(2, i) * 1000; // 1s, 2s, 4s
      await sleep(delay);
    }
  }
}
```

## Activation Management

### Proper Activation Flow

Always activate a license before regular use and provide deactivation options:

```javascript
async function setupLicense(licenseKey, product) {
  const instanceId = generateInstanceId();
  const instanceName = getComputerName();

  // Step 1: Activate the license on this device
  const activation = await activateLicense({
    license_key: licenseKey,
    product: product,
    instance_name: instanceName
  });

  if (!activation.success) {
    handleActivationError(activation.message);
    return false;
  }

  // Step 2: Store instance_id for future deactivation
  saveInstanceId(instanceId);

  return true;
}
```

### Cleanup on Uninstall

Always deactivate licenses when your application is uninstalled:

```javascript
async function uninstallCleanup() {
  const licenseKey = getStoredLicense();
  const instanceId = getStoredInstanceId();

  if (licenseKey && instanceId) {
    await deactivateLicense({
      license_key: licenseKey,
      instance_id: instanceId
    });
  }

  clearLocalStorage();
}
```

## User Experience

### Provide Clear Feedback

Always inform users about license status:

```javascript
function displayLicenseStatus(validation) {
  if (validation.valid) {
    showNotification(`License active until ${validation.valid_until}`, 'success');
  } else {
    showNotification(validation.message, 'error');
    showLicenseInputDialog();
  }
}
```

### Allow Manual Deactivation

Give users control over their activations:

```javascript
async function deactivateCurrentDevice() {
  const confirmed = await showConfirmDialog(
    'Deactivate License',
    'This will free up an activation slot. You will need to reactivate to use this application.'
  );

  if (confirmed) {
    const result = await deactivateLicense({
      license_key: getLicenseKey(),
      instance_id: getInstanceId()
    });

    if (result.success) {
      clearLicenseData();
      showLicenseInputDialog();
    }
  }
}
```

## Testing Recommendations

### Test All License States

Ensure your integration handles all license scenarios:

1. Valid active license
2. Expired license
3. Suspended license
4. Invalid license key
5. Maximum activations reached
6. Network failures
7. Offline mode

### Use Test Environment

Create test licenses in your LicenFlow dashboard for development and testing purposes. Never use production licenses during development.

## Monitoring and Logging

### Log License Events

Track license operations for troubleshooting:

```javascript
function logLicenseEvent(event, data) {
  const logEntry = {
    timestamp: new Date().toISOString(),
    event: event,
    data: data,
    user: getCurrentUser(),
    instance: getInstanceId()
  };

  // Log to your analytics or monitoring service
  sendToAnalytics('license_event', logEntry);
}

// Usage
logLicenseEvent('validation_success', { license_key: 'XXX...XXX' });
logLicenseEvent('activation_failed', { error: errorMessage });
```

### Monitor Validation Patterns

Track failed validations to detect potential issues:

- High failure rates may indicate user confusion
- Repeated failures from same instance may indicate technical issues
- Failed activations may indicate license limit problems

## Product and License Type Values

### Use Exact Product Names

Product names must match exactly with those configured in your LicenFlow account. Retrieve available products programmatically:

```javascript
// On application setup, fetch valid products
const products = await fetch('https://api.licenflow.com/api/products');
const validProducts = await products.json();

// Use exact product name in validation
const productName = 'Web Application'; // Must match exactly
```

### Supported License Types

When creating licenses via API, use these exact values for `license_type`:

- `trial` - Free trial with expiration date
- `subscription` - Recurring payment license
- `perpetual` - One-time payment, indefinite use
- `freemium` - Basic features free, premium paid
- `usage` - Pay per use or quota-based
- `floating` - Shared license pool
- `node-locked` - Device-specific license
- `api` - API access license

These values are enforced by the API and case-sensitive. 