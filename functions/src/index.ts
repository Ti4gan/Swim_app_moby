import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

initializeApp();

export const notifyCoachOnNewResult = onDocumentCreated('results/{resultId}', async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const result = snapshot.data() as {
    athleteUserId?: string;
    trainingPlanId?: string;
    distanceMeters?: number;
    timeValue?: string;
  };

  const trainingPlanId = result.trainingPlanId;
  if (!trainingPlanId) return;

  const db = getFirestore();
  const planSnap = await db.collection('trainingPlans').doc(trainingPlanId).get();
  if (!planSnap.exists) return;

  const plan = planSnap.data() as {
    coachId?: string;
    title?: string;
  };

  const coachId = plan.coachId;
  if (!coachId) return;

  const coachUserSnap = await db.collection('users').doc(coachId).get();
  if (!coachUserSnap.exists) return;

  const coachUser = coachUserSnap.data() as { fcmToken?: string; fullName?: string };
  const token = coachUser.fcmToken;
  if (!token) return;

  const athleteName = await (async () => {
    const athleteUserId = result.athleteUserId;
    if (!athleteUserId) return 'Спортсмен';
    const athleteUserSnap = await db.collection('users').doc(athleteUserId).get();
    const athleteUser = athleteUserSnap.data() as { fullName?: string } | undefined;
    return athleteUser?.fullName ?? 'Спортсмен';
  })();

  const title = 'Новый результат';
  const body = `${athleteName}: ${plan.title ?? 'тренировка'} — ${String(result.distanceMeters ?? 0)} м, ${result.timeValue ?? ''}`;

  await getMessaging().send({
    token,
    notification: { title, body },
    data: {
      trainingPlanId,
      resultId: snapshot.id,
    },
  });
});
