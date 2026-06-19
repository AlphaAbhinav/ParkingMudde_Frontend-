importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyA-e0Sa-45NIOitC3C_C256EmjyYuQptQ4",
  authDomain: "parking-mudde-f14b2.firebaseapp.com",
  projectId: "parking-mudde-f14b2",
  storageBucket: "parking-mudde-f14b2.firebasestorage.app",
  messagingSenderId: "806232833396",
  appId: "1:806232833396:web:4e52e2721fd43b85e60021"
});

const messaging = firebase.messaging();
