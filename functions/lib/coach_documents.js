import { google } from 'googleapis';
import { randomUUID } from 'node:crypto';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { defineString } from 'firebase-functions/params';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
const coachDocumentsDriveFolderId = defineString('COACH_DOCUMENTS_DRIVE_FOLDER_ID', {
    default: '',
});
const GDRIVE_PREFIX = 'gdrive:';
const MAX_UPLOAD_BYTES = 10 * 1024 * 1024;
function storageDownloadUrl(bucketName, objectPath, token) {
    return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(objectPath)}?alt=media&token=${token}`;
}
async function ensureStorageDownloadUrl(objectPath) {
    const bucket = getStorage().bucket();
    const file = bucket.file(objectPath);
    const [meta] = await file.getMetadata();
    const custom = meta.metadata ?? {};
    let token = custom.firebaseStorageDownloadTokens;
    if (typeof token !== 'string' || token.length === 0) {
        token = randomUUID();
        await file.setMetadata({
            metadata: {
                ...custom,
                firebaseStorageDownloadTokens: token,
            },
        });
    }
    return storageDownloadUrl(bucket.name, objectPath, token);
}
function safeFileName(raw) {
    const trimmed = raw.trim();
    const dot = trimmed.lastIndexOf('.');
    const ext = dot > 0 ? trimmed.substring(dot).replace(/[^a-zA-Z0-9.]/g, '') : '';
    const base = (dot > 0 ? trimmed.substring(0, dot) : trimmed)
        .replace(/[^a-zA-Z0-9_-]+/g, '_')
        .replace(/_+/g, '_')
        .replace(/^_+|_+$/g, '');
    const fallback = 'document';
    return `${base.length > 0 ? base : fallback}_${Date.now()}${ext}`;
}
function parseGdriveRef(ref) {
    if (!ref.startsWith(GDRIVE_PREFIX))
        return null;
    const rest = ref.slice(GDRIVE_PREFIX.length);
    const pipe = rest.indexOf('|');
    if (pipe === -1) {
        return { fileId: rest };
    }
    return { fileId: rest.slice(0, pipe), fileName: rest.slice(pipe + 1) };
}
async function getDrive() {
    const auth = new google.auth.GoogleAuth({
        scopes: ['https://www.googleapis.com/auth/drive.readonly'],
    });
    return google.drive({ version: 'v3', auth });
}
async function isAdmin(uid) {
    const snap = await getFirestore().collection('users').doc(uid).get();
    return snap.data()?.role === 'admin';
}
async function assertCoachOwnsRef(uid, ref) {
    const snap = await getFirestore().collection('coach_registration_requests').doc(uid).get();
    const urls = snap.data()?.certificateUrls ?? [];
    if (!urls.includes(ref)) {
        throw new HttpsError('permission-denied', 'Нет доступа к файлу');
    }
}
export const uploadCoachDocument = onCall({
    timeoutSeconds: 120,
    memory: '512MiB',
}, async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'Требуется вход в аккаунт');
    }
    const uid = request.auth.uid;
    const fileName = request.data?.fileName;
    const contentType = request.data?.contentType?.trim() || 'application/octet-stream';
    const dataBase64 = request.data?.dataBase64;
    if (!fileName?.trim()) {
        throw new HttpsError('invalid-argument', 'fileName обязателен');
    }
    if (!dataBase64?.trim()) {
        throw new HttpsError('invalid-argument', 'dataBase64 обязателен');
    }
    const buffer = Buffer.from(dataBase64, 'base64');
    if (buffer.length === 0) {
        throw new HttpsError('invalid-argument', 'Пустой файл');
    }
    if (buffer.length > MAX_UPLOAD_BYTES) {
        throw new HttpsError('invalid-argument', 'Файл больше 10 МБ');
    }
    const name = safeFileName(fileName);
    const objectPath = `coach_documents/${uid}/${name}`;
    const bucket = getStorage().bucket();
    const downloadToken = randomUUID();
    await bucket.file(objectPath).save(buffer, {
        metadata: {
            contentType,
            metadata: {
                uploadedBy: uid,
                firebaseStorageDownloadTokens: downloadToken,
            },
        },
    });
    const downloadUrl = storageDownloadUrl(bucket.name, objectPath, downloadToken);
    return { ref: objectPath, downloadUrl };
});
export const getCoachDocumentDownloadUrls = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'Требуется вход в аккаунт');
    }
    const uid = request.auth.uid;
    const refs = request.data?.refs;
    if (!Array.isArray(refs) || refs.length === 0) {
        throw new HttpsError('invalid-argument', 'refs обязателен');
    }
    if (refs.length > 50) {
        throw new HttpsError('invalid-argument', 'Слишком много файлов за один запрос');
    }
    const admin = await isAdmin(uid);
    const urls = {};
    const gdriveRefs = [];
    const storagePaths = [];
    for (const raw of refs) {
        const ref = raw.trim();
        if (!ref)
            continue;
        if (ref.startsWith('http://') || ref.startsWith('https://')) {
            urls[ref] = ref;
            continue;
        }
        if (ref.startsWith('coach_documents/')) {
            storagePaths.push(ref);
            continue;
        }
        if (parseGdriveRef(ref)) {
            gdriveRefs.push(ref);
        }
    }
    for (const objectPath of storagePaths) {
        if (!admin) {
            await assertCoachOwnsRef(uid, objectPath);
        }
        urls[objectPath] = await ensureStorageDownloadUrl(objectPath);
    }
    if (gdriveRefs.length === 0) {
        return { urls };
    }
    if (!coachDocumentsDriveFolderId.value().trim()) {
        throw new HttpsError('failed-precondition', 'Старые файлы в Google Drive недоступны. Загрузите документы заново.');
    }
    try {
        const drive = await getDrive();
        for (const ref of gdriveRefs) {
            const parsed = parseGdriveRef(ref);
            if (!admin) {
                await assertCoachOwnsRef(uid, ref);
            }
            const file = await drive.files.get({
                fileId: parsed.fileId,
                fields: 'webViewLink, webContentLink',
                supportsAllDrives: true,
            });
            const link = file.data.webViewLink ?? file.data.webContentLink;
            if (!link) {
                throw new HttpsError('not-found', 'Ссылка на файл не найдена');
            }
            urls[ref] = link;
        }
        return { urls };
    }
    catch (err) {
        if (err instanceof HttpsError)
            throw err;
        console.error('coach_documents_drive_error', err);
        throw new HttpsError('internal', 'Ошибка чтения старых файлов Google Drive');
    }
});
//# sourceMappingURL=coach_documents.js.map