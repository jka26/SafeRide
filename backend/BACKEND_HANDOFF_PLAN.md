# SafeRide Backend Execution Plan (Two Halves)

## Scope
Backend only (NestJS + PostgreSQL + Better Auth). No frontend responsibilities in this plan.

## Half 1 - Alvin (Foundation and Core Data)

### 1) Project Foundation
- [x] Create `backend/` workspace
- [x] Add NestJS base project and module boundaries
- [x] Add global environment config and validation
- [x] Add `/api` global prefix and health endpoint

### 2) Domain Module Boundaries
- [x] `auth`
- [x] `users`
- [x] `students`
- [x] `buses`
- [x] `trips`
- [x] `attendance`
- [x] `notifications`
- [x] `csv-import`
- [x] `dashboard`
- [x] `common`
- [x] `database`

### 3) Database Ownership (Alvin)
- [x] Final relational schema for:
  - users, roles
  - parents, students
  - drivers, buses, trips
  - attendance
  - notifications
- [x] Migrations
- [x] Indexes and constraints
- [x] Seed script (admin + sample driver + sample parent + sample students)

### 4) Auth and Access Baseline (Alvin)
- [x] Auth/session lifecycle baseline (token + DB-backed session)
- [x] Auth guard for protected routes
- [x] Roles guard for route-level authorization
- [x] Current-user context helper/decorator

### 5) Core Data APIs (Alvin)
- [x] Admin CRUD baseline:
  - students
  - buses
  - trips
- [x] CSV student import baseline:
  - upload endpoint
  - parse + row validation
  - dry-run preview response
  - commit valid rows

## Half 2 - Teammate (Business Workflows and Finalization)

### 1) Role-specific Data Delivery
- [ ] `dashboard` endpoints for:
  - admin operational summary
  - driver trip + roster view
  - parent child-specific view

### 2) Attendance Workflow
- [ ] Driver marks student present/absent
- [ ] Attendance retrieval by trip/date
- [ ] Permission checks: only assigned driver/admin can modify

### 3) Notification Workflow
- [ ] Store notifications
- [ ] Fetch notifications by role/user
- [ ] Mark as read

### 4) Hardening + Quality
- [ ] Unified error response format
- [ ] Input validation for all public endpoints
- [ ] Integration/e2e tests for auth, CSV, attendance, dashboards
- [ ] API docs and deployment handoff notes

## Handoff Rules
- Alvin hands off only after schema, migrations, auth guards, and core admin data APIs are stable.
- Teammate should not change base schema contracts without syncing first.
- Shared API response contracts should be documented in DTOs before teammate expansion.
