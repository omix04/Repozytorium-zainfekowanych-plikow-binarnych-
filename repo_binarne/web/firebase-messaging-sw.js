importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDQNuoSKUa1Syu8kLW3Zfg8qfj0ib1yWAk",
  authDomain: "sem5-sala.firebaseapp.com",
  projectId: "sem5-sala",
  storageBucket: "sem5-sala.firebasestorage.app",
  messagingSenderId: "1032885556733",
  appId: "1:1032885556733:web:c96ca8fb87f3ce8e7b6cf7",
  measurementId: "G-0MGDV2F7SX"
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
