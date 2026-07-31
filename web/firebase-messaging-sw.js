importScripts(
  'https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js'
);

importScripts(
  'https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js'
);

const firebaseConfig = {
  apiKey: 'AIzaSyDJEsk9a_N_dYNYPYGoUIFHsOaW2G1wO6E',
  authDomain: 'pointagepro-izs.firebaseapp.com',
  projectId: 'pointagepro-izs',
  storageBucket: 'pointagepro-izs.firebasestorage.app',
  messagingSenderId: '651818546130',
  appId: '1:651818546130:web:d151485e3767aa788f4e0b',
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log(
    '[firebase-messaging-sw.js] Message reçu en arrière-plan :',
    payload
  );

  const notificationTitle =
    payload.notification?.title ?? 'PointagePro';

  const notificationOptions = {
    body:
      payload.notification?.body ??
      'Vous avez reçu un nouveau message.',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data ?? {},
  };

  self.registration.showNotification(
    notificationTitle,
    notificationOptions
  );
});