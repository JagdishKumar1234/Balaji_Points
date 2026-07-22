// Firebase Cloud Messaging Service Worker
// Handles push notifications for web app

// Initialize Firebase (copy config from web/index.html)
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging.js');

// Firebase configuration (same as in web/index.html)
const firebaseConfig = {
  apiKey: "AIzaSyAr7q3N0EqWh-MZ1zcVPFvLsS-3P5jZGqY",
  authDomain: "balajipoints.firebaseapp.com",
  projectId: "balajipoints",
  storageBucket: "balajipoints.appspot.com",
  messagingSenderId: "53571317085",
  appId: "1:53571317085:web:bf8e5031a99a928f158cb4",
  measurementId: "G-FZNJF59L3K"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Get messaging instance
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message:', payload);

  const notificationTitle = payload.notification?.title || 'Balaji Points';
  const notificationOptions = {
    body: payload.notification?.body || 'You have a new notification',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    image: payload.notification?.image || undefined,
    data: payload.data || {},
    tag: 'balaji-points-notification',
    requireInteraction: false,
  };

  return self.registration.showNotification(
    notificationTitle,
    notificationOptions
  );
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification clicked:', event.notification.title);

  event.notification.close();

  // Open app or focus window
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // Check if app is already open
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if (client.url === '/' && 'focus' in client) {
          return client.focus();
        }
      }
      // If not open, open the app
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});

// Periodic sync (optional, for queued notifications)
self.addEventListener('sync', (event) => {
  if (event.tag === 'balaji-points-sync') {
    event.waitUntil(
      // Sync pending notifications if needed
      Promise.resolve()
    );
  }
});

console.log('[firebase-messaging-sw.js] Service worker initialized for Balaji Points');
