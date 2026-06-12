import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { GoogleAuth } from 'google-auth-library';

const PROJECT_ID = 'swim-app-moby';
const CLIENT_ID = '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';

async function main(): Promise<void> {
  const cfg = JSON.parse(
    readFileSync(join(homedir(), '.config/configstore/firebase-tools.json'), 'utf8'),
  ) as { tokens?: { refresh_token?: string } };
  const refreshToken = cfg.tokens?.refresh_token;
  if (!refreshToken) throw new Error('Выполните: npx firebase-tools login');

  const auth = new GoogleAuth({
    credentials: {
      type: 'authorized_user',
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      refresh_token: refreshToken,
    },
    scopes: ['https://www.googleapis.com/auth/identitytoolkit'],
  });

  const token = await auth.getAccessToken();
  if (!token) throw new Error('access token missing');

  const users: { localId: string; email?: string }[] = [];
  let pageToken: string | undefined;
  do {
    const body: Record<string, unknown> = { returnUserInfo: true, maxResults: 1000 };
    if (pageToken) body.pageToken = pageToken;
    const res = await fetch(
      `https://identitytoolkit.googleapis.com/v1/projects/${PROJECT_ID}/accounts:query`,
      {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      },
    );
    const json = (await res.json()) as {
      userInfo?: { localId: string; email?: string }[];
      nextPageToken?: string;
    };
    users.push(...(json.userInfo ?? []));
    pageToken = json.nextPageToken;
  } while (pageToken);

  if (users.length === 0) {
    console.log('Auth: пользователей нет');
    return;
  }

  for (const u of users) {
    const res = await fetch(
      `https://identitytoolkit.googleapis.com/v1/projects/${PROJECT_ID}/accounts:delete`,
      {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ localId: u.localId }),
      },
    );
    if (!res.ok) {
      throw new Error(`delete ${u.email}: ${res.status} ${await res.text()}`);
    }
    console.log(`Auth удалён: ${u.email ?? u.localId}`);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
