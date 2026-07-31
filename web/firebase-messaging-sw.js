// commentaire //

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

  const data = payload.data ?? {};

  const notificationTitle =
    payload.notification?.title ?? 'Synkro';

  const notificationOptions = {
    body:
      payload.notification?.body ??
      'Vous avez reçu un nouveau message.',

    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',

    tag:
      data.conversation_id
        ? `synkro-conversation-${data.conversation_id}`
        : 'synkro-message',

    renotify: true,

    data: {
      ...data,
      url: data.conversation_id
        ? `/communications?conversation_id=${encodeURIComponent(
            data.conversation_id
          )}`
        : '/communications',
    },
  };

  return self.registration.showNotification(
    notificationTitle,
    notificationOptions
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const notificationData =
    event.notification.data ?? {};

  const targetUrl =
    notificationData.url ?? '/communications';

  event.waitUntil(
    self.clients
      .matchAll({
        type: 'window',
        includeUncontrolled: true,
      })
      .then(async (clientList) => {
        for (const client of clientList) {
          const clientUrl = new URL(client.url);

          if (clientUrl.origin === self.location.origin) {
            await client.focus();

            client.postMessage({
              type: 'SYNKRO_NOTIFICATION_CLICK',
              data: notificationData,
            });

            return client;
          }
        }

        return self.clients.openWindow(targetUrl);
      })
  );
});