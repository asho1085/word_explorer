import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// The Firebase project's database was created with the ID "default", not the
// SDK's implicit "(default)". firebase.json deploys rules to the same ID.
const cloudDatabaseId = 'default';

FirebaseFirestore get cloudDb => FirebaseFirestore.instanceFor(
  app: Firebase.app(),
  databaseId: cloudDatabaseId,
);
