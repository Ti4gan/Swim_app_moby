import { onDocumentCreated } from 'firebase-functions/v2/firestore';
export { getCoachDocumentDownloadUrls, uploadCoachDocument } from './coach_documents.js';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
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
export const notifyAthleteOnCoachWorkout = onDocumentCreated('users/{athleteId}/workouts/{workoutId}', async (event) => {
    const snapshot = event.data;
    if (!snapshot)
        return;
    const workout = snapshot.data();
    const coachId = workout.coachId;
    if (!coachId)
        return;
    const enteredByCoach = workout.recordMeta?.enteredByCoach === true;
    if (!enteredByCoach)
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
    const workoutTitle = workout.title?.trim() || 'Тренировка';
    const meters = Math.round(workout.distanceMeters ?? 0);
    await sendPush(token, 'Новая тренировка', `${coachName} добавил: «${workoutTitle}» — ${meters} м`, {
        type: 'coach_workout',
        athleteId,
        workoutId: snapshot.id,
    });
});
//# sourceMappingURL=index.js.map