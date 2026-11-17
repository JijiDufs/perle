// Appelle l'API App Store Connect avec la clé d'équipe (fichier .p8 hors du dépôt).
// Usage : node scripts/asc.mjs [chemin API, ex. /v1/apps]
import { readFileSync } from 'node:fs';
import { createPrivateKey, sign } from 'node:crypto';
import { homedir } from 'node:os';

const KEY_ID = '2BH29LC72C';
const ISSUER_ID = '79d2e436-8678-4f0d-87cb-49c6bd379f70';
const P8_PATH = `${homedir()}/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8`;

export function token() {
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  const head = `${b64({ alg: 'ES256', kid: KEY_ID, typ: 'JWT' })}.${b64({ iss: ISSUER_ID, iat: now, exp: now + 1200, aud: 'appstoreconnect-v1' })}`;
  const key = createPrivateKey(readFileSync(P8_PATH));
  const sig = sign('sha256', Buffer.from(head), { key, dsaEncoding: 'ieee-p1363' }).toString('base64url');
  return `${head}.${sig}`;
}

export async function asc(path, init = {}) {
  const res = await fetch(`https://api.appstoreconnect.apple.com${path}`, {
    ...init,
    headers: { Authorization: `Bearer ${token()}`, 'Content-Type': 'application/json', ...init.headers },
  });
  if (!res.ok) throw new Error(`${res.status} ${await res.text()}`);
  return res.json();
}

if (process.argv[1] === import.meta.filename) {
  const data = await asc(process.argv[2] ?? '/v1/apps');
  console.log(JSON.stringify(data, null, 2));
}
