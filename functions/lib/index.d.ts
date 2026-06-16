export { getCoachDocumentDownloadUrls, uploadCoachDocument } from './coach_documents.js';
export declare const notifyAthleteOnCoachWorkout: import("firebase-functions/core").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2/firestore").QueryDocumentSnapshot | undefined, {
    athleteId: string;
    workoutId: string;
}>>;
export declare const notifyCoachOnWellbeingOrCompetition: import("firebase-functions/core").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2/firestore").Change<import("firebase-functions/v2/firestore").DocumentSnapshot> | undefined, {
    athleteId: string;
    workoutId: string;
}>>;
export declare const notifyCoachOnCompetitionSwim: import("firebase-functions/core").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2/firestore").QueryDocumentSnapshot | undefined, {
    athleteId: string;
    swimId: string;
}>>;
export declare const notifyAthleteOnGoal: import("firebase-functions/core").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2/firestore").QueryDocumentSnapshot | undefined, {
    athleteId: string;
    goalId: string;
}>>;
export declare const clearFcmToken: import("firebase-functions/v2/https").CallableFunction<any, Promise<void>, unknown>;
//# sourceMappingURL=index.d.ts.map