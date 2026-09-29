import { createHash, createHmac, timingSafeEqual } from 'node:crypto';

export const SCOPE = 'discord.read';
export function baseUrl(req) {
  const configured = String(process.env.PUBLIC_BASE_URL || '').replace(/\/$/, '');
  if (configured) return configured;
  const proto = String(req.headers?.['x-forwarded-proto'] || 'https').split(',')[0].trim();
  const host = String(req.headers?.['x-forwarded-host'] || req.headers?.host || '').split(',')[0].trim();
  if (!host) throw new Error('request host unavailable');
  return proto + '://' + host;
}
export function need(name, min = 1) {
  const v = process.env[name];
  if (!v || v.length < min) throw new Error(name + ' is not configured correctly');
  return v;
}
function key() {
  const explicit = String(process.env.OAUTH_SIGNING_SECRET || '');
  if (explicit.length >= 32) return explicit;
  return createHash('sha256').update('discord-reader-oauth-v1:' + need('CONNECT_PASSWORD', 16)).digest('hex');
}
function sig(s) { return createHmac('sha256', key()).update(s).digest('base64url'); }
export function sign(prefix, payload) {
  const body = Buffer.from(JSON.stringify(payload)).toString('base64url');
  return prefix + '.' + body + '.' + sig(prefix + '.' + body);
}
export function verify(token, prefix) {
  const p = String(token || '').split('.');
  if (p.length !== 3 || p[0] !== prefix) throw new Error('invalid token');
  const a = Buffer.from(sig(p[0] + '.' + p[1]));
  const b = Buffer.from(p[2]);
  if (a.length !== b.length || !timingSafeEqual(a, b)) throw new Error('invalid token signature');
  const payload = JSON.parse(Buffer.from(p[1], 'base64url').toString('utf8'));
  if (payload.exp && payload.exp < Math.floor(Date.now()/1000)) throw new Error('expired token');
  return payload;
}
export function passwordOk(input) {
  const expected = Buffer.from(need('CONNECT_PASSWORD', 16));
  const got = Buffer.from(String(input || ''));
  return expected.length === got.length && timingSafeEqual(expected, got);
}
export function pkce(v) { return createHash('sha256').update(String(v || '')).digest('base64url'); }
export function issueAccess(client, resource, scope=SCOPE) {
  const now = Math.floor(Date.now()/1000);
  return sign('dr_at', {typ:'access', client_id:client, resource, scope, iat:now, exp:now+86400*30});
}
export function verifyAccess(req) {
  const h = String(req.headers?.authorization || '');
  if (!h.startsWith('Bearer ')) throw new Error('missing bearer');
  const p = verify(h.slice(7), 'dr_at');
  if (p.typ !== 'access' || !String(p.scope||'').split(/\s+/).includes(SCOPE)) throw new Error('invalid access');
  return p;
}
export async function readBody(req) {
  const chunks=[]; for await (const c of req) chunks.push(c);
  return Buffer.concat(chunks).toString('utf8');
}
export async function readJson(req) { const s=await readBody(req); return s ? JSON.parse(s) : {}; }
export async function readForm(req) { return Object.fromEntries(new URLSearchParams(await readBody(req)).entries()); }
export function esc(s) { return String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
