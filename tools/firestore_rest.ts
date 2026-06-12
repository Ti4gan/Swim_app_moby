import type { GoogleAuth } from 'google-auth-library';

const PROJECT_ID = 'swim-app-moby';
const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

type JsonValue =
  | string
  | number
  | boolean
  | null
  | Date
  | JsonValue[]
  | { [k: string]: JsonValue | unknown };

function encodeValue(v: JsonValue): Record<string, unknown> {
  if (v === null) return { nullValue: null };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') {
    return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  }
  if (Array.isArray(v)) return { arrayValue: { values: v.map((x) => encodeValue(x as JsonValue)) } };
  const fields: Record<string, unknown> = {};
  for (const [k, val] of Object.entries(v as Record<string, unknown>)) {
    fields[k] = encodeValue(val as JsonValue);
  }
  return { mapValue: { fields } };
}

export function encodeFields(data: Record<string, JsonValue>): Record<string, unknown> {
  const fields: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(data)) {
    fields[k] = encodeValue(v);
  }
  return fields;
}

export class FirestoreRest {
  constructor(private readonly auth: GoogleAuth) {}

  private async token(): Promise<string> {
    const t = await this.auth.getAccessToken();
    if (!t) throw new Error('access token missing');
    return t;
  }

  async setDoc(docPath: string, data: Record<string, JsonValue>): Promise<void> {
    const token = await this.token();
    const url = `${BASE}/${docPath}`;
    const res = await fetch(url, {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ fields: encodeFields(data) }),
    });
    if (!res.ok) {
      throw new Error(`Firestore set ${docPath}: ${res.status} ${await res.text()}`);
    }
  }
}
