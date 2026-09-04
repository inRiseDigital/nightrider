// The one place that picks which AdminDataSource implementation backs the
// five new admin sections (plus Dashboard). Every hook in those sections
// should import `dataSource` from here — never `mockAdminDataSource` or a
// future Firestore-backed implementation directly.
//
// Wiring phase: swap this one import for a Firestore-backed AdminDataSource
// (built the same way lib/admin/firestore.ts backs the existing org-apps
// hooks) and nothing else changes — every hook, view model, and filter
// function in lib/admin/{view-models,filters}/** is already written against
// the AdminDataSource interface in ./data-source.ts, not against this file.

import { mockAdminDataSource } from "./mock";
import type { AdminDataSource } from "./data-source";

export const dataSource: AdminDataSource = mockAdminDataSource;
