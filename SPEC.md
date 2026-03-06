# Karberg Properties — MVP v1 Spec

## Roles
- staff: `landlord` | `manager`
- tenant: `tenant`

## Domain
- 2 properties
  - Property A: full flat (single unit)
  - Property B: 3 rooms (units: Room 1, Room 2, Room 3)

## Rent
- Due day: 27
- Rent amounts per lease:
  - Flat: 1430
  - Room 1: 765
  - Room 2: 700
  - Room 3: 800
- Manual mark-as-paid (no bank integration in v1)

## Tenant onboarding (self sign-up)
- Tenant signs up (email+password) → enters Lease Code
- App redeems code and links user → leaseId

## Docs
- Multiple PDFs per lease
- Tenant can view + download

## Tickets
- Categories (pick list): plumbing, electrical, heating, appliances, pests, other
- Multi-photo upload
- Statuses: submitted, acknowledged, in_progress, done, rejected
- No push notifications in v1

## UI (high-level)
### Staff
- Dashboard: unpaid rents (this month), open tickets
- Properties → Units → Lease
- Lease: docs, rent ledger, tenant email
- Tickets: list/detail, update status, notes

### Tenant
- My Lease: docs, basic lease info
- Report issue: category, description, photos
- My tickets: list/detail
