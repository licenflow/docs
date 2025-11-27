# Direct Payment Collection API

## Overview

The Direct Payment Collection API allows developers to generate payment links for their customers to purchase licenses directly. This feature enables:

- **Automated License Delivery**: Licenses are automatically created upon successful payment
- **Bitcoin Payments**: Integration with Lightning Network for BitCoin BTC payments
- **Commission Tracking**: Automatic calculation and tracking of platform commissions
- **Renewal Management**: Support for subscription-based and one-time payments

## Architecture

Products in LicenFlow are **globally accessible** - any authenticated developer can create payment links for any product. The security model is:

- **Products**: No user ownership - accessible to all developers
- **Licenses**: Bound to specific `user_id` (the developer) and `product` name
- **Payment Tokens**: Created by authenticated developers via Sanctum API tokens
- **Validation**: License keys are only valid for the specific product they were purchased for

> **Important**: A license key is validated against both the `license_key` AND `product` name. This prevents license reuse across different products, even from the same developer.

## Getting Started

### Prerequisites

1. Enable Direct Payment Collection feature in your account settings
2. Configure your commission settings (default: 15%)
3. Set up your renewal type (monthly, annual, or perpetual)
4. Obtain your API access token (Bearer token via Laravel Sanctum)

### Step 1: Enable Direct Payment Feature

Navigate to your settings and enable Direct Payment Collection. Configure:

- **Renewal Type**: `monthly`, `annual`, or `perpetual`
- **Commission Percentage**: Platform commission (default 15%)
- **Auto-approval**: Whether commissions are auto-approved or require manual review

## API Endpoints

### 1. Create Payment Token

Generate a payment link for your customer to purchase a license.

**Endpoint:**
```
POST /api/v1/direct-payment/tokens
```

**Headers:**
```
Authorization: Bearer YOUR_API_TOKEN
Content-Type: application/json
Accept: application/json
```

**Request Body:**
```json
{
  "product_id": 1,
  "amount": 100.00,
  "currency": "USD",
  "end_user_email": "customer@example.com",
  "end_user_name": "John Doe",
  "idempotency_key": "unique-key-123",
  "expires_in_hours": 24,
  "metadata": {
    "custom_field": "value"
  }
}
```

**Parameters:**
- `product_id` (required): The ID of the product being purchased
- `amount` (required): Total amount in USD
- `currency` (optional): Currency code (default: USD)
- `end_user_email` (required): Customer's email address
- `end_user_name` (optional): Customer's full name
- `idempotency_key` (optional): Unique key to prevent duplicate payments
- `expires_in_hours` (optional): Payment link expiration time
- `metadata` (optional): Custom metadata to attach to the license

**Response:**
```json
{
  "success": true,
  "data": {
    "payment_token_id": "9d3f8a7b-1c4e-4f5a-8b2c-3d4e5f6a7b8c",
    "payment_url": "https://app.licenflow.com/pay/9d3f8a7b-1c4e-4f5a-8b2c-3d4e5f6a7b8c",
    "amount_breakdown": {
      "total": 100.00,
      "developer_share": 85.00,
      "commission": 15.00,
      "currency": "USD"
    },
    "expires_at": "2025-11-27T22:00:00.000000Z"
  }
}
```

**Error Responses:**
```json
{
  "success": false,
  "message": "Direct payment feature is not enabled for this user"
}
```

```json
{
  "success": false,
  "message": "Product does not belong to this developer"
}
```

### 2. Create Payment Token for Renewal

To create a payment link for renewing an existing license:

**Request Body:**
```json
{
  "product_id": 1,
  "amount": 100.00,
  "end_user_email": "customer@example.com",
  "license_id": 42,
  "metadata": {
    "renewal": true
  }
}
```

**Parameters:**
- `license_id` (optional): Existing license ID to renew
- All other parameters same as new purchase

**Response:**
```json
{
  "success": true,
  "data": {
    "payment_token_id": "9d3f8a7b-1c4e-4f5a-8b2c-3d4e5f6a7b8c",
    "payment_url": "https://app.licenflow.com/pay/9d3f8a7b-1c4e-4f5a-8b2c-3d4e5f6a7b8c",
    "renewal": true,
    "existing_license_key": "XXXX-XXXX-XXXX-XXXX",
    "amount_breakdown": {
      "total": 100.00,
      "developer_share": 85.00,
      "commission": 15.00
    },
    "expires_at": "2025-11-27T22:00:00.000000Z"
  }
}
```

### 3. Get Payment Token Status

Check the status of a payment token.

**Endpoint:**
```
GET /api/v1/direct-payment/tokens/{token_id}
```

**Headers:**
```
Authorization: Bearer YOUR_API_TOKEN
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "9d3f8a7b-1c4e-4f5a-8b2c-3d4e5f6a7b8c",
    "status": "pending",
    "amount_total": 100.00,
    "amount_developer": 85.00,
    "amount_commission": 15.00,
    "currency": "USD",
    "end_user_email": "customer@example.com",
    "end_user_name": "John Doe",
    "expires_at": "2025-11-27T22:00:00.000000Z",
    "created_at": "2025-11-26T22:00:00.000000Z"
  }
}
```

**Status Values:**
- `pending`: Payment link created, awaiting payment
- `processing`: Payment received, license being generated
- `completed`: Payment successful, license delivered
- `failed`: Payment failed or expired
- `expired`: Payment link expired

## Payment Flow

### Customer Payment Process

1. **Developer generates payment link** via API
2. **Customer receives payment URL** via email or direct link
3. **Customer visits payment page** and sees:
   - Product name and description
   - Total amount in USD and BTC
   - Bitcoin Lightning invoice QR code
4. **Customer pays** via Bitcoin Lightning Network
5. **System automatically**:
   - Confirms payment via LN Lightning Network BitCoin BTC webhook
   - Generates new license or renews existing license
   - Records transaction and commission
   - Sends license key to customer email
6. **Developer receives notification** of successful sale

### License Generation

Upon successful payment:

**New Purchase:**
```json
{
  "license_key": "XXXX-XXXX-XXXX-XXXX",
  "product": "Your Product Name",
  "user_id": 123,
  "status": "active",
  "license_type": "monthly",
  "valid_until": "2025-12-26T22:00:00.000000Z",
  "metadata": {
    "payment_token_id": "9d3f8a7b...",
    "end_user_email": "customer@example.com",
    "end_user_name": "John Doe",
    "purchase_date": "2025-11-26T22:00:00.000000Z"
  }
}
```

**Renewal:**
- Existing license `valid_until` date is extended
- `renewal_count` incremented in metadata
- `last_renewal_date` updated

## Commission System

### Commission Calculation

Commissions are automatically calculated based on your Direct Payment Feature settings:

```
Total Amount: $100.00
Commission (15%): $15.00
Developer Share: $85.00
```

### Commission Lifecycle

1. **Created**: Commission record created on payment completion
2. **Pending**: Awaiting approval (manual review if required)
3. **Approved**: Approved for payout
4. **Paid**: Included in a payout batch

### Viewing Commissions

Access your commissions via the developer dashboard:
- Total pending commissions
- Approved commissions ready for payout
- Payment history

## Webhooks

LicenFlow uses webhooks to notify you of payment events:

### Payment Completed
```json
{
  "event": "payment.completed",
  "payment_token_id": "9d3f8a7b-1c4e-4f5a-8b2c-3d4e5f6a7b8c",
  "transaction_id": 456,
  "license": {
    "id": 789,
    "key": "XXXX-XXXX-XXXX-XXXX",
    "product": "Your Product",
    "valid_until": "2025-12-26T22:00:00.000000Z"
  },
  "amount": 100.00,
  "currency": "USD",
  "timestamp": "2025-11-26T22:00:00.000000Z"
}
```

### Payment Failed
```json
{
  "event": "payment.failed",
  "payment_token_id": "9d3f8a7b-1c4e-4f5a-8b2c-3d4e5f6a7b8c",
  "reason": "expired",
  "timestamp": "2025-11-26T22:00:00.000000Z"
}
```

## Best Practices

### Security

1. **Validate product ownership**: Although products are global, always verify the product_id matches your expected product
2. **Use idempotency keys**: Prevent duplicate payments by providing unique idempotency_key
3. **Set expiration times**: Use `expires_in_hours` to limit payment link validity
4. **Verify webhooks**: Validate webhook signatures to ensure authenticity

### User Experience

1. **Email notifications**: Send payment links via email with clear instructions
2. **Custom metadata**: Include relevant information in metadata for tracking
3. **Clear product descriptions**: Ensure products have detailed descriptions
4. **Support contact**: Provide support email in payment page

### Error Handling

```javascript
try {
  const response = await fetch('/api/v1/direct-payment/tokens', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(paymentData)
  });

  const result = await response.json();

  if (!result.success) {
    // Handle error
    console.error('Payment creation failed:', result.message);
    return;
  }

  // Send payment URL to customer
  sendPaymentEmail(result.data.payment_url, customerEmail);

} catch (error) {
  console.error('API request failed:', error);
}
```

## Example Integration

### PHP Example

```php
<?php

// Create payment token for customer
$apiToken = 'your_api_token_here';
$apiUrl = 'https://app.licenflow.com/api/v1/direct-payment/tokens';

$paymentData = [
    'product_id' => 1,
    'amount' => 99.99,
    'currency' => 'USD',
    'end_user_email' => 'customer@example.com',
    'end_user_name' => 'John Doe',
    'idempotency_key' => uniqid('payment_', true),
    'expires_in_hours' => 24,
    'metadata' => [
        'order_id' => '12345',
        'plan' => 'premium'
    ]
];

$ch = curl_init($apiUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($paymentData));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $apiToken,
    'Content-Type: application/json',
    'Accept: application/json'
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($httpCode === 200) {
    $result = json_decode($response, true);

    if ($result['success']) {
        // Send payment URL to customer
        $paymentUrl = $result['data']['payment_url'];
        sendEmailToCustomer($customerEmail, $paymentUrl);

        echo "Payment link created: " . $paymentUrl;
    } else {
        echo "Error: " . $result['message'];
    }
} else {
    echo "HTTP Error: " . $httpCode;
}
```

### JavaScript Example

```javascript
async function createPaymentLink(productId, amount, customerEmail, customerName) {
  const apiToken = 'your_api_token_here';
  const apiUrl = 'https://app.licenflow.com/api/v1/direct-payment/tokens';

  const paymentData = {
    product_id: productId,
    amount: amount,
    currency: 'USD',
    end_user_email: customerEmail,
    end_user_name: customerName,
    idempotency_key: `payment_${Date.now()}_${Math.random()}`,
    expires_in_hours: 24,
    metadata: {
      source: 'website',
      campaign: 'summer-sale'
    }
  };

  try {
    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiToken}`,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify(paymentData)
    });

    const result = await response.json();

    if (result.success) {
      console.log('Payment URL:', result.data.payment_url);
      console.log('Amount breakdown:', result.data.amount_breakdown);

      // Redirect or email customer
      return result.data;
    } else {
      console.error('Error:', result.message);
      throw new Error(result.message);
    }

  } catch (error) {
    console.error('Failed to create payment link:', error);
    throw error;
  }
}

// Usage
createPaymentLink(1, 99.99, 'customer@example.com', 'John Doe')
  .then(payment => {
    // Handle success
    window.location.href = payment.payment_url;
  })
  .catch(error => {
    // Handle error
    alert('Failed to create payment: ' + error.message);
  });
```

## Troubleshooting

### Common Issues

**Error: "Direct payment feature is not enabled for this user"**
- Solution: Enable Direct Payment Collection in your account settings

**Error: "Product does not belong to this developer"**
- Solution: This error should not occur as products are globally accessible. Ensure the product_id exists.

**Error: "License not found or does not belong to this developer/product"**
- Solution: When renewing, verify the license_id and ensure end_user_email matches the original license

**Payment link expired**
- Solution: Generate a new payment link. Default expiration is 24 hours.

**Customer didn't receive license email**
- Solution: Check spam folder, verify email address, check transaction status in dashboard

## FAQ

**Q: Can I customize the payment page?**
A: Currently the payment page design is standardized. Custom branding coming soon.

**Q: What payment methods are supported?**
A: Bitcoin via Lightning Network is currently supported. More payment methods coming soon.

**Q: How long does payment confirmation take?**
A: Bitcoin Lightning payments are instant. License delivery typically occurs within seconds.

**Q: Can I refund a payment?**
A: Contact support for refund requests. Refunds are processed manually.

**Q: Are there transaction fees?**
A: Platform commission is deducted automatically (default 15%). Bitcoin network fees are minimal with Lightning Network.

**Q: Can I test payments without real Bitcoin?**
A: Yes, use the staging environment with testnet Bitcoin for testing.

## Next Steps

- Review [License Validation](integration.md#license-validation) for validating purchased licenses
- Check [Best Practices](best-practices.md) for secure payment integration
- Set up [Webhooks](#webhooks) for automated license delivery
