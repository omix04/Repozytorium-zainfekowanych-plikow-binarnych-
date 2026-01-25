importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBfc-8jKM7_VG_Seqw5xUNd1SC2bTHSFJs",
  authDomain: "repozytorium-binarne.firebaseapp.com",
  projectId: "repozytorium-binarne",
  storageBucket: "repozytorium-binarne.firebasestorage.app",
  messagingSenderId: "309976053778",
  appId: "1:309976053778:web:2b8c9b9e4541dd250600cb",
  measurementId: "G-LFG9TDS9ZZ"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
