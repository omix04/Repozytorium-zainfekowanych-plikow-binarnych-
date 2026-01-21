const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getStorage} = require("firebase-admin/storage");
const {getFirestore} = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

initializeApp();

exports.manualMd5Check = onCall({region: "europe-west2"}, async (request) => {
  // 1. Sprawdzenie autoryzacji
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Brak autoryzacji.");
  }

  const {storagePath, docId} = request.data;
  
  // Logowanie danych wejściowych dla łatwiejszego debugowania
  logger.log(`Weryfikacja dla docId: ${docId}, ścieżka: ${storagePath}`);

  try {
    // 2. POPRAWKA: Dostęp do nazwanej bazy danych 'sala'
    const db = getFirestore("sala"); 
    const bucket = getStorage().bucket();
    const file = bucket.file(storagePath);

    // Sprawdzenie czy plik istnieje przed pobraniem metadanych
    const [exists] = await file.exists();
    if (!exists) {
      logger.error(`Plik nie istnieje w Storage: ${storagePath}`);
      throw new HttpsError("not-found", "Plik nie został znaleziony w Storage.");
    }

    // 3. Pobranie metadanych
    const [metadata] = await file.getMetadata();
    const md5Hex = Buffer.from(metadata.md5Hash, "base64").toString("hex");

    // 4. Aktualizacja Firestore (baza 'sala')
    await db.collection("binary_items").doc(docId).update({
      md5: md5Hex,
      lastVerified: new Date().toISOString(),
      status: "verified",
    });

    return { success: true, md5: md5Hex };
  } catch (error) {
    // Logowanie szczegółów błędu w konsoli Firebase
    logger.error("Błąd krytyczny funkcji manualMd5Check:", error);
    
    // Zwrócenie bardziej szczegółowego błędu do Fluttera
    throw new HttpsError("internal", error.message || "Błąd serwera.");
  }
});