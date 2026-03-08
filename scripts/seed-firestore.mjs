import admin from 'firebase-admin';

function requireEnv(name) {
  const v = process.env[name];
  if (!v) throw new Error(`Missing env var: ${name}`);
  return v;
}

// Auth options:
// 1) FIREBASE_SERVICE_ACCOUNT_JSON: full JSON string
// 2) GOOGLE_APPLICATION_CREDENTIALS: path to a service account json file
if (!admin.apps.length) {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    const json = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
    admin.initializeApp({
      credential: admin.credential.cert(json)
    });
  } else {
    // Falls back to Application Default Credentials (works if GOOGLE_APPLICATION_CREDENTIALS is set)
    admin.initializeApp();
  }
}

const db = admin.firestore();

const now = admin.firestore.FieldValue.serverTimestamp();

function yyyyMm(d = new Date()) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  return `${y}-${m}`;
}

// ----- Sample IDs (stable) -----
const propertyAId = 'propertyA';
const propertyBId = 'propertyB';

const unitFlatId = 'unit_flat';
const unitRoom1Id = 'unit_room1';
const unitRoom2Id = 'unit_room2';
const unitRoom3Id = 'unit_room3';

const leaseFlatId = 'lease_flat';
const leaseRoom1Id = 'lease_room1';
const leaseRoom2Id = 'lease_room2';
const leaseRoom3Id = 'lease_room3';

// Lease codes are stored as document IDs.
// Give these to tenants.
const codeFlat = 'KARB-FLAT-1430';
const codeRoom1 = 'KARB-R1-0765';
const codeRoom2 = 'KARB-R2-0700';
const codeRoom3 = 'KARB-R3-0800';

async function upsert(coll, id, data) {
  await db.collection(coll).doc(id).set(
    {
      ...data,
      updatedAt: now,
      createdAt: data.createdAt ?? now
    },
    { merge: true }
  );
}

async function main() {
  // Optional: set project explicitly just for display/logging
  const projectId = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || '(default)';
  console.log(`Seeding Firestore (project: ${projectId})...`);

  // Properties
  await upsert('properties', propertyAId, {
    name: 'Property A',
    address: 'Sample Street 1, 12345 City',
    notes: 'Full flat (single unit)'
  });

  await upsert('properties', propertyBId, {
    name: 'Property B',
    address: 'Sample Street 2, 12345 City',
    notes: '3 rooms (Room 1–3)'
  });

  // Units
  await upsert('units', unitFlatId, {
    propertyId: propertyAId,
    label: 'Flat'
  });
  await upsert('units', unitRoom1Id, {
    propertyId: propertyBId,
    label: 'Room 1'
  });
  await upsert('units', unitRoom2Id, {
    propertyId: propertyBId,
    label: 'Room 2'
  });
  await upsert('units', unitRoom3Id, {
    propertyId: propertyBId,
    label: 'Room 3'
  });

  // Leases
  const dueDay = 27;
  await upsert('leases', leaseFlatId, {
    unitId: unitFlatId,
    rentAmountEur: 1430,
    dueDay
  });
  await upsert('leases', leaseRoom1Id, {
    unitId: unitRoom1Id,
    rentAmountEur: 765,
    dueDay
  });
  await upsert('leases', leaseRoom2Id, {
    unitId: unitRoom2Id,
    rentAmountEur: 700,
    dueDay
  });
  await upsert('leases', leaseRoom3Id, {
    unitId: unitRoom3Id,
    rentAmountEur: 800,
    dueDay
  });

  // Lease docs (placeholders; you still need to upload actual PDFs to Storage)
  await upsert('leaseDocs', 'doc_flat_welcome', {
    leaseId: leaseFlatId,
    filename: 'Welcome.pdf',
    storagePath: 'leaseDocs/lease_flat/Welcome.pdf',
    contentType: 'application/pdf'
  });

  // Rent ledger (current month)
  const month = yyyyMm();
  await upsert('rentLedger', `rent_${leaseFlatId}_${month}`, {
    leaseId: leaseFlatId,
    month,
    status: 'unpaid'
  });
  await upsert('rentLedger', `rent_${leaseRoom1Id}_${month}`, {
    leaseId: leaseRoom1Id,
    month,
    status: 'paid',
    paidAt: now,
    note: 'Seeded as paid example'
  });
  await upsert('rentLedger', `rent_${leaseRoom2Id}_${month}`, {
    leaseId: leaseRoom2Id,
    month,
    status: 'unpaid'
  });
  await upsert('rentLedger', `rent_${leaseRoom3Id}_${month}`, {
    leaseId: leaseRoom3Id,
    month,
    status: 'unpaid'
  });

  // Lease codes
  const makeCode = (leaseId) => ({
    leaseId,
    active: true,
    redeemedByUid: null,
    redeemedAt: null
  });

  await upsert('leaseCodes', codeFlat, makeCode(leaseFlatId));
  await upsert('leaseCodes', codeRoom1, makeCode(leaseRoom1Id));
  await upsert('leaseCodes', codeRoom2, makeCode(leaseRoom2Id));
  await upsert('leaseCodes', codeRoom3, makeCode(leaseRoom3Id));

  console.log('Done. Lease codes:');
  console.log(`- Flat:  ${codeFlat}`);
  console.log(`- Room1: ${codeRoom1}`);
  console.log(`- Room2: ${codeRoom2}`);
  console.log(`- Room3: ${codeRoom3}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
