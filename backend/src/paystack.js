const PAYSTACK_SECRET = process.env.PAYSTACK_SECRET_KEY || '';
const PAYSTACK_BASE = 'https://api.paystack.co';

async function paystackRequest(path, options = {}) {
  if (!PAYSTACK_SECRET) {
    throw new Error('PAYSTACK_SECRET_KEY not set on server. Add it to backend/.env');
  }
  const res = await fetch(`${PAYSTACK_BASE}${path}`, {
    ...options,
    headers: {
      Authorization: `Bearer ${PAYSTACK_SECRET}`,
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
  });
  const body = await res.json();
  if (!res.ok || !body.status) {
    throw new Error(body.message || 'Paystack request failed');
  }
  return body;
}

async function initializeTransaction({ email, amountNaira, reference, callbackUrl }) {
  const body = await paystackRequest('/transaction/initialize', {
    method: 'POST',
    body: JSON.stringify({
      email,
      amount: Math.round(amountNaira * 100),
      reference,
      callback_url: callbackUrl,
      currency: 'NGN',
      channels: ['card', 'bank', 'ussd', 'qr', 'mobile_money', 'bank_transfer'],
    }),
  });
  return {
    authorizationUrl: body.data.authorization_url,
    accessCode: body.data.access_code,
    reference: body.data.reference,
  };
}

async function verifyTransaction(reference) {
  const body = await paystackRequest(`/transaction/verify/${encodeURIComponent(reference)}`);
  return {
    status: body.data.status,
    reference: body.data.reference,
    amount: body.data.amount / 100,
    paidAt: body.data.paid_at,
    channel: body.data.channel,
  };
}

module.exports = { initializeTransaction, verifyTransaction, hasPaystackSecret: () => !!PAYSTACK_SECRET };
