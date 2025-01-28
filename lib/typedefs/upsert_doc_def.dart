import 'package:turbo_firestore_api/models/turbo_auth_vars.dart';

typedef UpsertDocDef<T> = T Function(T? current, TurboAuthVars vars);
