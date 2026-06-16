import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
export { getCoachDocumentDownloadUrls, uploadCoachDocument } from './coach_documents.js';
initializeApp();
async function sendPush(token, title, body, data) {
    await getMessaging().send({
        token,
        notification: { title, body },
        data,
        android: {
            priority: 'high',
            notification: { channelId: 'coach_workouts' },
        },
        apns: {
            payload: {
                aps: {
                    sound: 'default',
                },
            },
        },
    });
}
async function ensureCoachToken(db, coachId) {
    const snap = await db.collection('users').doc(coachId).get();
    if (!snap.exists)
        return null;
    const d = snap.data();
    return d?.fcmToken ?? null;
}
export const notifyAthleteOnCoachWorkout = onDocumentCreated('users/{athleteId}/workouts/{workoutId}', async (event) => {
    const snapshot = event.data;
    if (!snapshot)
        return;
    const workout = snapshot.data();
    const athleteId = event.params.athleteId;
    const db = getFirestore();
    const athleteSnap = await db.collection('users').doc(athleteId).get();
    if (!athleteSnap.exists)
        return;
    const athlete = athleteSnap.data();
    const token = athlete.fcmToken;
    if (!token)
        return;
    const coachId = athlete.coachId;
    if (!coachId)
        return;
    const coachSnap = await db.collection('users').doc(coachId).get();
    const coach = coachSnap.data();
    const coachName = coach?.displayName?.trim() || coach?.fullName?.trim() || 'Тренер';
    const workoutTitle = workout.title?.trim() || 'Тренировка';
    const meters = Math.round(workout.distanceMeters ?? 0);
    await sendPush(token, 'Новая тренировка', `${coachName} добавил: «${workoutTitle}» — ${meters} м`, {
        type: 'coach_workout',
        athleteId,
        workoutId: snapshot.id,
    });
});
export const notifyCoachOnWellbeingOrCompetition = onDocumentWritten('users/{athleteId}/workouts/{workoutId}', async (event) => {
    const change = event.data;
    if (!change)
        return;
    const beforeData = change.before.data();
    const afterData = change.after.data();
    if (!afterData)
        return;
    const wasAlreadySaved = beforeData?.recordMeta?.wellbeingSaved === true;
    const nowSaved = afterData.recordMeta?.wellbeingSaved === true;
    if (wasAlreadySaved || !nowSaved)
        return;
    const coachId = afterData.coachId;
    if (!coachId)
        return;
    const meta = afterData.recordMeta ?? {};
    const athleteId = event.params.athleteId;
    const db = getFirestore();
    const coachToken = await ensureCoachToken(db, coachId);
    if (!coachToken)
        return;
    const athleteSnap = await db.collection('users').doc(athleteId).get();
    const athlete = athleteSnap.data();
    const athleteName = athlete?.displayName?.trim() || athlete?.fullName?.trim() || 'Пловец';
    const title = afterData.title?.trim() || 'Тренировка';
    const meters = Math.round(afterData.distanceMeters ?? 0);
    const moodLabel = (() => {
        const m = meta.mood;
        if (m == null)
            return null;
        const n = Number(m);
        if (Number.isNaN(n))
            return null;
        if (n <= 3)
            return 'плохое';
        if (n <= 6)
            return 'нормальное';
        return 'хорошее';
    })();
    const bodyParts = [];
    if (moodLabel != null)
        bodyParts.push(`настроение: ${moodLabel}`);
    if (typeof meta.fatigue === 'number')
        bodyParts.push(`утомление: ${meta.fatigue}/10`);
    const bodyText = bodyParts.length > 0 ? bodyParts.join(', ') : undefined;
    await sendPush(coachToken, `Настроение после тренировки`, `${athleteName}: «${title}» — ${meters} м${bodyText != null ? ` (${bodyText})` : ''}`, {
        type: 'coach_wellbeing',
        athleteId,
        workoutId: change.after.id,
    });
});
export const notifyCoachOnCompetitionSwim = onDocumentCreated('users/{athleteId}/competition_swims/{swimId}', async (event) => {
    const snapshot = event.data;
    if (!snapshot)
        return;
    const swim = snapshot.data();
    const distanceMeters = swim.distanceMeters ?? 0;
    const strokeKey = swim.strokeKey ?? 'free';
    const eventDate = swim.eventDate;
    let dateLabel = '';
    if (eventDate) {
        const ts = typeof eventDate === 'number' ? eventDate : eventDate.seconds;
        if (typeof ts === 'number' && ts > 0) {
            const d = new Date(ts * 1000);
            dateLabel = d.toLocaleDateString('ru-RU', { day: 'numeric', month: 'long' });
        }
    }
    const athleteId = event.params.athleteId;
    const db = getFirestore();
    const athleteSnap = await db.collection('users').doc(athleteId).get();
    if (!athleteSnap.exists)
        return;
    const userDoc = athleteSnap.data();
    const coachId = userDoc.coachId;
    if (!coachId)
        return;
    const coachToken = await ensureCoachToken(db, coachId);
    if (!coachToken)
        return;
    const athlete = athleteSnap.data();
    const athleteName = athlete?.displayName?.trim() || athlete?.fullName?.trim() || 'Пловец';
    const strokeLabels = {
        free: 'вольный стиль',
        breast: 'брасс',
        back: 'на спине',
        fly: 'баттерфляй',
        im: 'комплекс',
    };
    const strokeLabel = strokeLabels[strokeKey] || strokeKey;
    await sendPush(coachToken, 'Новый результат соревнования', `${athleteName} — ${distanceMeters} м, ${strokeLabel}${dateLabel.length > 0 ? ` (${dateLabel})` : ''}`, {
        type: 'coach_competition',
        athleteId,
        swimId: snapshot.id,
    });
});
export const notifyAthleteOnGoal = onDocumentCreated('users/{athleteId}/performance_goal/{goalId}', async (event) => {
    const snapshot = event.data;
    if (!snapshot)
        return;
    const goal = snapshot.data();
    const coachId = goal.coachId;
    if (!coachId)
        return;
    const athleteId = event.params.athleteId;
    const db = getFirestore();
    const athleteSnap = await db.collection('users').doc(athleteId).get();
    if (!athleteSnap.exists)
        return;
    const athlete = athleteSnap.data();
    const token = athlete.fcmToken;
    if (!token)
        return;
    const coachSnap = await db.collection('users').doc(coachId).get();
    const coach = coachSnap.data();
    const coachName = coach?.displayName?.trim() || coach?.fullName?.trim() || 'Тренер';
    const strokeLabels = {
        free: 'вольный стиль',
        breast: 'брасс',
        back: 'на спине',
        fly: 'баттерфляй',
        im: 'комплекс',
    };
    const strokeLabel = strokeLabels[goal.strokeKey ?? 'free'] || goal.strokeKey;
    await sendPush(token, 'Новая цель от тренера', `${coachName} поставил цель на ${goal.distanceMeters} м, ${strokeLabel}`, {
        type: 'coach_goal',
        athleteId,
        goalId: snapshot.id,
    });
});
export const clearFcmToken = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { userId } = request.data;
    if (!userId || typeof userId !== 'string') {
        throw new HttpsError('invalid-argument', 'userId is required');
    }
    const db = getFirestore();
    await db
        .collection('users')
        .doc(userId)
        .set({
        fcmToken: FieldValue.delete(),
        fcmTokenUpdatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
});
//# sourceMappingURL=index.js.map