import { initializeApp } from "firebase/app";
import { getFirestore, collection, getDocs, deleteDoc } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyDH89thE4JWwkrbjinEknp3BYalXnOdrQ0",
  authDomain: "auditgemma-ca1bb.firebaseapp.com",
  projectId: "auditgemma-ca1bb",
  storageBucket: "auditgemma-ca1bb.firebasestorage.app",
  messagingSenderId: "124362139239",
  appId: "1:124362139239:web:27639faaa318a895db16c2"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function clearCollection(name) {
  const coll = collection(db, name);
  const snapshot = await getDocs(coll);
  console.log(`Found ${snapshot.size} docs in ${name}`);
  for (const doc of snapshot.docs) {
    await deleteDoc(doc.ref);
  }
  console.log(`Cleared ${name}`);
}

async function run() {
  try {
    await clearCollection("cases");
    await clearCollection("audit_log");
    console.log("Done");
    process.exit(0);
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
}
run();
