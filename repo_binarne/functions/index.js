const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentCreated, onDocumentUpdated, onDocumentDeleted} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getStorage} = require("firebase-admin/storage");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
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

exports.onBinaryCreated = onDocumentCreated({
  region: "europe-west2",
  document: "binary_items/{docId}",
  database: "sala",
}, async (event) => {
  const data = event.data.data();

  logger.log("onBinaryCreated triggered!", {fileName: data.fileName, format: data.format});

  try {
    const result = await getMessaging().send({
      topic: "binary_updates",
      notification: {
        title: "Nowy plik w repozytorium",
        body: `Dodano: ${data.fileName} (${data.format})`,
      },
      data: {
        type: "new_binary",
        fileName: data.fileName || "",
        format: data.format || "",
      },
    });

    logger.log(`Notification sent successfully for new binary: ${data.fileName}`, {messageId: result});
  } catch (error) {
    logger.error("Failed to send notification:", error);
  }
});

exports.onBinaryUpdated = onDocumentUpdated({
  region: "europe-west2",
  document: "binary_items/{docId}",
  database: "sala",
}, async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  logger.log("onBinaryUpdated triggered!", {
    fileName: after.fileName,
    beforeMd5: before.md5,
    afterMd5: after.md5
  });

  if (before.md5 !== after.md5 && after.md5) {
    try {
      const result = await getMessaging().send({
        topic: "binary_updates",
        notification: {
          title: "Plik zweryfikowany",
          body: `${after.fileName} przeszedł weryfikację MD5`,
        },
        data: {
          type: "verified",
          fileName: after.fileName || "",
          md5: after.md5 || "",
        },
      });

      logger.log(`Verification notification sent successfully for: ${after.fileName}`, {messageId: result});
    } catch (error) {
      logger.error("Failed to send verification notification:", error);
    }
  }
});

exports.onBinaryDeleted = onDocumentDeleted({
  region: "europe-west2",
  document: "binary_items/{docId}",
  database: "sala",
}, async (event) => {
  const data = event.data.data();

  logger.log("onBinaryDeleted triggered!", {fileName: data.fileName, format: data.format});

  try {
    const result = await getMessaging().send({
      topic: "binary_updates",
      notification: {
        title: "Plik usunięty",
        body: `Usunięto: ${data.fileName} (${data.format})`,
      },
      data: {
        type: "deleted",
        fileName: data.fileName || "",
        format: data.format || "",
      },
    });

    logger.log(`Deletion notification sent successfully for: ${data.fileName}`, {messageId: result});
  } catch (error) {
    logger.error("Failed to send deletion notification:", error);
  }
});