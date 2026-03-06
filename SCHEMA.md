# Firestore schema (proposed)

All documents include: `createdAt`, `updatedAt` (server timestamps).

## users/{uid}
- role: "landlord" | "manager" | "tenant"
- email: string
- displayName?: string
- leaseId?: string (tenant only)

## properties/{propertyId}
- name: string
- address: string
- notes?: string

## units/{unitId}
- propertyId: string
- label: string ("Flat" or "Room 1" etc.)
- notes?: string

## leases/{leaseId}
- unitId: string
- tenantUid?: string
- tenantEmail?: string (optional convenience)
- rentAmountEur: number
- dueDay: number (27)
- startDate?: timestamp
- endDate?: timestamp (omitted for open-ended)

## leaseDocs/{docId}
(Separate collection for easy queries; could also be subcollection under lease.)
- leaseId: string
- filename: string
- storagePath: string
- contentType: string

## rentLedger/{entryId}
- leaseId: string
- month: string (YYYY-MM)
- status: "paid" | "unpaid"
- paidAt?: timestamp
- note?: string

## tickets/{ticketId}
- leaseId: string
- category: string
- description: string
- status: "submitted"|"acknowledged"|"in_progress"|"done"|"rejected"
- photos: array<{ storagePath, contentType, filename }>
- staffNote?: string
- createdByUid: string
