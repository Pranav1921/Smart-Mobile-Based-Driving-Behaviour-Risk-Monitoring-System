# Implementation Plan - Zone-Based Driver Filtering & Dashboard Fixes

Fix the "Live Field Operators" count on the dashboard, resolve the Redis connection error, and ensure real-time telemetry is correctly displayed.

## User Review Required

> [!IMPORTANT]
> I will re-enable the test drivers in the database seed to facilitate debugging of the dashboard roster and filtering. If you prefer to keep the database empty for production-like testing, please let me know.

## Proposed Changes

### Backend

#### [MODIFY] [seed.ts](file:///C:/Users/prana/projects/Major%20project/backend/src/database/seed.ts)
- Uncomment David Driver and Sarah Speedy profiles.
- Ensure all test users are in the `puttur_taluk` zone for consistency.
- Re-enable vehicle assignment for David Driver.

#### [MODIFY] [driver.controller.ts](file:///C:/Users/prana/projects/Major%20project/backend/src/controllers/driver.controller.ts)
- Ensure the `isOnline` flag and telemetry data are correctly injected into the driver list even if the DB record is static.
- Standardize status casing (lowercase) to match frontend expectations.

#### [MODIFY] [queue.ts](file:///C:/Users/prana/projects/Major%20project/backend/src/jobs/queue.ts)
- Add fallback logic or improved error logging for Redis connection.

### Dashboard

#### [MODIFY] [Dashboard.tsx](file:///C:/Users/prana/projects/Major%20project/dashboard/src/pages/Dashboard.tsx)
- Debug and fix the `onlineCount` calculation to ensure it matches the roster when drivers are active.

## Verification Plan

### Automated Tests
- Run `npx ts-node seed.ts` to verify DB population.
- Run `npx ts-node test_redis.ts` to verify Redis connectivity.

### Manual Verification
- Check the Dashboard to see if "Active Intelligence" count is updated.
- Verify the "Operator Roster" page shows the seeded drivers.
- Simulate a telemetry update via a script or mobile app and verify the dashboard reflects the "Live" status.
