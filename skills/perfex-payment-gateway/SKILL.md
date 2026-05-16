---
name: perfex-payment-gateway
description: Use whenever the user is creating, modifying, or debugging a Perfex CRM payment gateway module — a class extending `App_gateway` in `modules/<module>/libraries/<Id>_gateway.php`, calling `setId`, `setName`, `setSettings`, implementing `process_payment($data)`, or registering via `register_payment_gateway`. Also trigger when the user says "create a payment gateway for Perfex", "my gateway webhook gets CSRF blocked", "process_payment not firing", "Stripe/PayPal/Mollie integration for Perfex", "payment gateway settings not saving", "encrypted setting", or "how do I handle the payment callback in Perfex". Covers the App_gateway lifecycle, settings encryption, webhook CSRF exclusion, and the Stripe API (Basil) changes in Perfex 3.3.0.
license: MIT
metadata:
  author: yasserstudio
  version: "1.4.0"
---

# Perfex Payment Gateway Development

You are a Perfex CRM payment-gateway engineer. Your job is to build gateway modules that extend `App_gateway` correctly — with encrypted secrets, proper webhook CSRF exclusion, and defensive callback handling — so payments process reliably across Stripe API updates and concurrent invoice payments.

Perfex supports custom payment gateways as modules since **v2.3.4**. A gateway is a class in `modules/<module>/libraries/<Id>_gateway.php` that extends `App_gateway` and implements `process_payment($data)`.

## File structure

```
modules/my_gateway/
├── my_gateway.php                    # module entry (hooks, register_payment_gateway)
├── install.php                       # optional: module-owned tables (transaction log, webhook log)
├── libraries/
│   └── My_gateway_gateway.php        # class My_gateway_gateway extends App_gateway
├── controllers/
│   └── My_gateway_webhook.php        # webhook receiver (CSRF-excluded)
├── views/
│   └── payment_form.php              # optional inline payment form
└── language/
    └── english/
        └── my_gateway_lang.php
```

The library filename **must** end with `_gateway.php`. Class name must match filename (capitalized first letter).

## Gateway class skeleton

```php
<?php
defined('BASEPATH') or exit('No direct script access allowed');

class My_gateway_gateway extends App_gateway
{
    public function __construct()
    {
        parent::__construct();

        $this->setId('my_gateway');

        $this->setName('My Gateway');

        $this->setSettings([
            [
                'name'      => 'api_key',
                'encrypted' => true,
                'label'     => 'API Key',
                'type'      => 'input',
            ],
            [
                'name'      => 'api_secret',
                'encrypted' => true,
                'label'     => 'API Secret',
                'type'      => 'input',
            ],
            [
                'name'      => 'test_mode',
                'label'     => 'Test Mode',
                'type'      => 'yes_no',
                'default_value' => '1',
            ],
            [
                'name'          => 'currencies',
                'label'         => 'settings_paymentmethod_currencies',
                'default_value' => 'USD,EUR',
            ],
        ]);
    }

    public function process_payment($data)
    {
        // $data contains: invoice object, amount, currency, redirect URLs
        // Option 1: redirect to external checkout
        // Option 2: render inline form (load a view)
        // Option 3: call gateway API and redirect

        $invoice  = $data['invoice'];
        $amount   = $data['amount'];
        $currency = $data['currency'];

        // Build the charge via your gateway's API
        $api_key = $this->decryptSetting('api_key');

        // ... gateway-specific logic ...

        // Redirect to gateway checkout page
        redirect($checkout_url);
    }
}
```

## Registration (module entry file)

```php
// my_gateway.php
register_payment_gateway('my_gateway_gateway', 'my_gateway');
```

First param: class name (lowercase). Second param: module system name. After activation, the gateway appears in **Setup → Settings → Payment Gateways**.

## Settings system

| Type | Renders as | Stored as |
|---|---|---|
| `input` | Text input | Plain or encrypted string |
| `textarea` | Multi-line input | Plain or encrypted string |
| `yes_no` | Toggle switch | `'1'` or `'0'` |
| *(no type)* | Text input | Plain string |

### Encrypted settings

Set `'encrypted' => true` on any setting holding secrets (API keys, webhook signing keys). Perfex encrypts at rest using the application encryption key. Access via `$this->decryptSetting('name')` — never read directly from DB.

```php
// ✅ Correct — decrypts automatically
$secret = $this->decryptSetting('api_secret');

// ❌ Wrong — returns encrypted gibberish
$secret = $this->getSetting('api_secret');
```

### Reading non-encrypted settings

```php
$mode = $this->getSetting('test_mode');  // '1' or '0'
$currencies = explode(',', $this->getSetting('currencies'));
```

## Webhook handling

External gateways POST payment confirmations to your callback URL. Two requirements:

### 1. CSRF exclusion

Perfex's global CSRF protection blocks external POSTs. Exclude your webhook route in `application/config/config.php`:

```php
$config['csrf_exclude_uris'] = array_merge(
    $config['csrf_exclude_uris'] ?? [],
    ['my_gateway_webhook/handle']
);
```

Or via hook in your module entry:

```php
hooks()->add_filter('csrf_exclude_uris', function ($uris) {
    $uris[] = 'my_gateway_webhook/handle';
    return $uris;
});
```

### 2. Webhook controller

```php
<?php
defined('BASEPATH') or exit('No direct script access allowed');

class My_gateway_webhook extends CI_Controller
{
    public function handle()
    {
        $payload = file_get_contents('php://input');
        $sig     = $this->input->get_request_header('X-Signature');

        // Verify signature using webhook signing secret
        $secret = $this->my_gateway_gateway->decryptSetting('webhook_secret');
        if (!$this->verify_signature($payload, $sig, $secret)) {
            log_message('error', 'my_gateway: webhook signature mismatch');
            $this->output->set_status_header(401);
            return;
        }

        $event = json_decode($payload, true);

        if ($event['type'] === 'payment.completed') {
            $this->process_successful_payment($event);
        }

        $this->output->set_status_header(200);
    }

    private function process_successful_payment($event)
    {
        $invoice_id = $event['metadata']['invoice_id'];

        // Use Perfex's payment recording
        $this->load->model('payments_model');
        $payment_data = [
            'invoiceid'        => $invoice_id,
            'amount'           => $event['amount'] / 100,  // cents to dollars
            'paymentmode'      => 'my_gateway',
            'transactionid'    => $event['transaction_id'],
            'date'             => date('Y-m-d'),
        ];
        $this->payments_model->add($payment_data);
    }

    private function verify_signature($payload, $sig, $secret)
    {
        $expected = hash_hmac('sha256', $payload, $secret);
        return hash_equals($expected, $sig);
    }
}
```

## The `$data` array in `process_payment`

Perfex passes an array containing:

| Key | Type | Description |
|---|---|---|
| `invoice` | object | Full invoice row from `tblinvoices` |
| `amount` | float | Amount to charge (may be partial payment) |
| `currency` | object | Currency info (name, symbol, decimal_separator, etc.) |

Access the invoice ID as `$data['invoice']->id`. The amount respects partial-payment settings — don't assume it equals the invoice total.

## Stripe API (Basil) changes — Perfex 3.3.0+

Perfex 3.3.0 updated to Stripe API version "Basil". If your module wraps Stripe:

- **Webhooks must be recreated** after upgrading to 3.3.0 — event payload format changed
- Stripe now respects allowed payment methods from the Stripe Dashboard (no longer hardcoded in Perfex)
- The `after_invoice_added` hook now fires **before** email sending (changed in 3.2.0) — if your gateway listens to this hook to auto-charge, the invoice email may not have been sent yet

## Existing gateway reference

Study Perfex's built-in gateways for patterns:
- `application/libraries/gateways/` — Stripe, PayPal, 2Checkout, Mollie
- `application/controllers/gateways/` — webhook receivers for built-in gateways

## Common pitfalls

- **Filename must end with `_gateway.php`** — `My_gateway.php` alone won't be detected.
- **`setId()` must be alphanumeric only** — no hyphens, no underscores. Use snake_case in class name but plain string for ID.
- **Don't store card data** — let the external gateway handle PCI compliance. Your module only stores transaction IDs.
- **`process_payment` is called on every "Pay Now" click** — it must be idempotent or create a new checkout session each time. Don't create duplicate charges.
- **Test with multiple currencies** — the `currencies` setting is a comma-separated string that Perfex checks before showing the gateway as available for an invoice.
- **Webhook retries** — most gateways retry failed webhooks. Your handler must be idempotent (check if payment already recorded before inserting).

## Related skills

- **`perfex-security`** — CSRF exclusion mechanics, webhook signature verification, `app_generate_hash()` for nonces.
- **`perfex-module-dev`** — module lifecycle, `register_payment_gateway()` lives in the module entry file.
- **`perfex-database`** — if you add a `tbl<module>_transactions` table for logging.

## Upstream docs

- Perfex payment gateway guide: https://help.perfexcrm.com/module-as-payment-gateway/
- Perfex module basics: https://help.perfexcrm.com/module-basics/
- Stripe API changelog: https://stripe.com/docs/changelog
