# UML Diagrams & Use Cases - Event Booking System

This document contains UML diagrams and use case descriptions for the Event & Wedding Booking System (Munasabati).

---

## Table of Contents

1. [Actor Definitions](#actor-definitions)
2. [Consumer Use Cases](#consumer-use-cases)
3. [Provider Use Cases](#provider-use-cases)
4. [Admin Use Cases](#admin-use-cases)
5. [Sequence Diagrams](#sequence-diagrams)
6. [Class Diagram](#class-diagram)
7. [Activity Diagrams](#activity-diagrams)

---

## Actor Definitions

| Actor | Description |
|-------|-------------|
| **Consumer** | End user who books services for events (weddings, birthdays, corporate events) |
| **Provider** | Service provider offering halls, cars, photography, or entertainment services |
| **Admin** | System administrator managing users, providers, and platform settings |
| **System** | Automated backend processes (notifications, payments, availability checks) |

---

## Consumer Use Cases

### Use Case Diagram

```mermaid
graph TD
    A[Consumer] --> B[Register Account]
    A --> C[Login]
    A --> D[Search Services]
    A --> E[View Service Details]
    A --> F[Check Availability]
    A --> G[Add to Booking Cart]
    A --> H[Create Booking]
    A --> I[Make Payment]
    A --> J[View Bookings]
    A --> K[Cancel Booking]
    A --> L[Write Review]
    A --> M[Bookmark Services]
    A --> N[Manage Profile]
    A --> O[View Notifications]
    
    C --> P{Authenticated?}
    P -->|Yes| Q[Access Dashboard]
    P -->|No| B
    
    H --> R[Select Date & Time]
    R --> S[Apply Pricing Rules]
    S --> T[Confirm Booking]
    T --> I
    
    I --> U{Payment Successful?}
    U -->|Yes| V[Booking Confirmed]
    U -->|No| W[Retry Payment]
```

### Detailed Consumer Use Cases

#### UC-01: Register Account
**Actor:** Consumer  
**Description:** New user creates an account to access the platform  
**Preconditions:** None  
**Postconditions:** User account created, verification email sent  

**Main Flow:**
1. Consumer clicks "Sign Up" button
2. Consumer enters email, password, full name, phone number
3. Consumer agrees to Terms & Conditions
4. System validates input (email format, password strength)
5. System creates user account
6. System sends verification email
7. Consumer verifies email
8. Account activated

**Alternative Flows:**
- 4a. Email already exists → System displays error message
- 4b. Password too weak → System prompts for stronger password

---

#### UC-02: Login
**Actor:** Consumer  
**Description:** Existing user authenticates to access their account  
**Preconditions:** User account exists and is active  
**Postconditions:** User authenticated, JWT token issued  

**Main Flow:**
1. Consumer enters email and password
2. System validates credentials
3. System generates JWT access token
4. System stores refresh token securely
5. User redirected to dashboard

**Alternative Flows:**
- 2a. Invalid credentials → System displays error
- 2a. Account not verified → System prompts for verification

---

#### UC-03: Search Services
**Actor:** Consumer  
**Description:** Consumer searches for available services  
**Preconditions:** User authenticated  
**Postconditions:** List of matching services displayed  

**Main Flow:**
1. Consumer selects service type (Hall, Car, Photographer, Entertainer)
2. Consumer applies filters (price range, city, rating, date)
3. Consumer enters search keywords (optional)
4. System queries database
5. System displays filtered results with pagination

**Alternative Flows:**
- 5a. No results found → System displays "No services found" message
- 5a. Network error → System displays error with retry option

---

#### UC-04: View Service Details
**Actor:** Consumer  
**Description:** Consumer views detailed information about a service  
**Preconditions:** Service exists  
**Postconditions:** Service details displayed  

**Main Flow:**
1. Consumer clicks on a service from search results
2. System retrieves service details
3. System displays:
   - Service images/gallery
   - Description and features
   - Pricing information
   - Reviews and ratings
   - Availability calendar
   - Provider information

---

#### UC-05: Check Availability
**Actor:** Consumer  
**Description:** Consumer checks available time slots for a service  
**Preconditions:** Service selected  
**Postconditions:** Available slots displayed  

**Main Flow:**
1. Consumer selects date from calendar
2. System queries booked_slots table
3. System queries availability_templates
4. System calculates available slots
5. System displays available time slots

**Alternative Flows:**
- 5a. No slots available → System suggests nearby dates

---

#### UC-06: Create Booking
**Actor:** Consumer  
**Description:** Consumer creates a new booking with one or more services  
**Preconditions:** User authenticated, services selected  
**Postconditions:** Booking created in pending status  

**Main Flow:**
1. Consumer adds service to booking cart
2. Consumer selects event type (wedding, birthday, corporate)
3. Consumer selects event date
4. Consumer selects time slots for each service
5. System checks for conflicts
6. System applies dynamic pricing rules
7. Consumer enters special requests (optional)
8. Consumer reviews booking summary
9. Consumer confirms booking
10. System creates booking record
11. System locks slots in Redis (10-minute TTL)
12. Consumer redirected to payment

**Alternative Flows:**
- 6a. Conflict detected → System displays conflict message
- 6a. Slot already locked → System suggests alternative slot

---

#### UC-07: Make Payment
**Actor:** Consumer  
**Description:** Consumer pays for booking using Stripe  
**Preconditions:** Booking created, slots locked  
**Postconditions:** Payment processed, booking confirmed  

**Main Flow:**
1. Consumer selects payment method (card, bank transfer)
2. Consumer enters payment details
3. System creates Stripe PaymentIntent
4. Consumer confirms payment
5. Stripe processes payment
6. System receives webhook confirmation
7. System updates booking status to "confirmed"
8. System confirms booked_slots in database
9. System releases Redis lock
10. System sends confirmation email
11. System sends push notification to provider
12. System sends confirmation to consumer

**Alternative Flows:**
- 6a. Payment failed → System releases lock, displays error
- 6a. Payment timeout → System releases lock, displays timeout message

---

#### UC-08: View Bookings
**Actor:** Consumer  
**Description:** Consumer views all their bookings  
**Preconditions:** User authenticated  
**Postconditions:** List of bookings displayed  

**Main Flow:**
1. Consumer navigates to "My Bookings"
2. System retrieves user's bookings
3. System filters by status (pending, confirmed, completed, cancelled)
4. System displays booking cards with:
   - Service details
   - Date and time
   - Status
   - Total amount
   - Actions (cancel, view details)

---

#### UC-09: Cancel Booking
**Actor:** Consumer  
**Description:** Consumer cancels a booking  
**Preconditions:** Booking exists, not in progress/completed  
**Postconditions:** Booking cancelled, slots released  

**Main Flow:**
1. Consumer selects booking to cancel
2. System displays cancellation policy
3. Consumer confirms cancellation
4. System updates booking status to "cancelled"
5. System releases booked_slots
6. System processes refund (if applicable)
7. System sends cancellation email
8. System notifies provider

**Alternative Flows:**
- 3a. Cancellation not allowed (too close to event) → System displays policy

---

#### UC-10: Write Review
**Actor:** Consumer  
**Description:** Consumer writes a review for a completed booking  
**Preconditions:** Booking completed, not yet reviewed  
**Postconditions:** Review saved, provider rating updated  

**Main Flow:**
1. Consumer selects completed booking
2. Consumer selects rating (1-5 stars)
3. Consumer writes review text (optional)
4. Consumer uploads images (optional)
5. System saves review
6. System updates provider rating
7. System notifies provider

---

#### UC-11: Bookmark Services
**Actor:** Consumer  
**Description:** Consumer saves services for later reference  
**Preconditions:** User authenticated  
**Postconditions:** Service bookmarked  

**Main Flow:**
1. Consumer clicks "Bookmark" on service
2. System adds service to user's bookmarks
3. System displays "Bookmarked" indicator

**Alternative Flows:**
- 2a. Already bookmarked → System removes bookmark

---

#### UC-12: Manage Profile
**Actor:** Consumer  
**Description:** Consumer updates their profile information  
**Preconditions:** User authenticated  
**Postconditions:** Profile updated  

**Main Flow:**
1. Consumer navigates to Profile
2. Consumer edits:
   - Full name
   - Phone number
   - Avatar image
   - Preferences
3. Consumer saves changes
4. System updates user record
5. System displays success message

---

## Provider Use Cases

### Use Case Diagram

```mermaid
graph TD
    A[Provider] --> B[Register Provider Account]
    A --> C[Login]
    A --> D[View Dashboard]
    A --> E[Manage Services]
    A --> F[Add New Service]
    A --> G[Edit Service]
    A --> H[Delete Service]
    A --> I[Manage Availability]
    A --> J[Set Working Hours]
    A --> K[Block Dates]
    A --> L[Set Pricing Rules]
    A --> M[View Incoming Bookings]
    A --> N[Accept Booking]
    A --> O[Reject Booking]
    A --> P[View Analytics]
    A --> Q[Manage Profile]
    A --> R[Respond to Reviews]
    
    D --> S[Revenue Stats]
    D --> T[Booking Stats]
    D --> U[Rating Stats]
    
    M --> V{Booking Status?}
    V -->|Pending| N
    V -->|Confirmed| W[View Details]
    
    N --> X[Send Confirmation]
    O --> Y[Send Rejection with Reason]
```

### Detailed Provider Use Cases

#### UC-P01: Register Provider Account
**Actor:** Provider  
**Description:** Service provider creates a business account  
**Preconditions:** User account exists  
**Postconditions:** Provider profile created, pending verification  

**Main Flow:**
1. Provider navigates to "Become a Provider"
2. Provider enters business information:
   - Business name
   - Service type (Hall, Car, Photographer, Entertainer)
   - Description
   - Contact details
   - Address/location
3. Provider uploads business documents
4. Provider uploads logo and cover image
5. System creates provider profile
6. System sets status to "pending verification"
7. System notifies admin for verification

---

#### UC-P02: View Dashboard
**Actor:** Provider  
**Description:** Provider views analytics and overview  
**Preconditions:** Provider authenticated  
**Postconditions:** Dashboard displayed  

**Main Flow:**
1. Provider navigates to Dashboard
2. System retrieves provider data
3. System displays:
   - Total revenue (current month, year)
   - Number of bookings (by status)
   - Average rating
   - Upcoming bookings
   - Pending requests
   - Revenue charts
   - Booking trends

---

#### UC-P03: Manage Services
**Actor:** Provider  
**Description:** Provider manages their service listings  
**Preconditions:** Provider authenticated  
**Postconditions:** Service list displayed  

**Main Flow:**
1. Provider navigates to "My Services"
2. System retrieves provider's services
3. System displays service cards with:
   - Service name
   - Price
   - Status (active/inactive)
   - Number of bookings
   - Average rating
   - Actions (edit, delete, toggle status)

---

#### UC-P04: Add New Service
**Actor:** Provider  
**Description:** Provider adds a new service listing  
**Preconditions:** Provider authenticated  
**Postconditions:** Service created  

**Main Flow:**
1. Provider clicks "Add Service"
2. Provider enters service details:
   - Title
   - Description
   - Base price
   - Pricing model (flat, hourly, per event)
   - Capacity (for halls)
   - Features/amenities
   - Images (multiple)
   - Tags
3. Provider uploads images
4. System validates input
5. System creates service record
6. System displays success message

---

#### UC-P05: Manage Availability
**Actor:** Provider  
**Description:** Provider sets available time slots  
**Preconditions:** Service exists  
**Postconditions:** Availability templates updated  

**Main Flow:**
1. Provider selects service
2. Provider navigates to "Availability"
3. Provider sets working hours for each day:
   - Start time
   - End time
   - Break times
4. Provider blocks specific dates (holidays, maintenance)
5. System saves availability templates
6. System updates available slots

---

#### UC-P06: Set Pricing Rules
**Actor:** Provider  
**Description:** Provider creates dynamic pricing rules  
**Preconditions:** Service exists  
**Postconditions:** Pricing rules saved  

**Main Flow:**
1. Provider selects service
2. Provider navigates to "Pricing"
3. Provider creates pricing rule:
   - Rule type (weekend, seasonal, peak, early bird)
   - Multiplier (e.g., 1.5x for weekends)
   - Date range
   - Days of week
4. System saves pricing rule
5. System applies rule to future bookings

---

#### UC-P07: View Incoming Bookings
**Actor:** Provider  
**Description:** Provider views booking requests  
**Preconditions:** Provider authenticated  
**Postconditions:** Booking list displayed  

**Main Flow:**
1. Provider navigates to "Bookings"
2. System retrieves incoming bookings
3. System displays bookings with:
   - Consumer information
   - Service requested
   - Date and time
   - Special requests
   - Status (pending, confirmed, rejected)
   - Actions (accept, reject)

---

#### UC-P08: Accept Booking
**Actor:** Provider  
**Description:** Provider accepts a booking request  
**Preconditions:** Booking in pending status  
**Postconditions:** Booking confirmed, consumer notified  

**Main Flow:**
1. Provider views pending booking
2. Provider clicks "Accept"
3. System updates booking status to "confirmed"
4. System confirms booked_slots
5. System sends confirmation email to consumer
6. System sends push notification to consumer
7. System adds to provider's calendar

---

#### UC-P09: Reject Booking
**Actor:** Provider  
**Description:** Provider rejects a booking request  
**Preconditions:** Booking in pending status  
**Postconditions:** Booking rejected, slots released  

**Main Flow:**
1. Provider views pending booking
2. Provider clicks "Reject"
3. Provider enters rejection reason
4. System updates booking status to "cancelled"
5. System releases booked_slots
6. System sends rejection email to consumer
7. System processes refund (if payment made)

---

#### UC-P10: View Analytics
**Actor:** Provider  
**Description:** Provider views detailed analytics  
**Preconditions:** Provider authenticated  
**Postconditions:** Analytics displayed  

**Main Flow:**
1. Provider navigates to "Analytics"
2. System retrieves booking data
3. System displays:
   - Revenue by month (chart)
   - Bookings by service type
   - Customer demographics
   - Peak booking times
   - Cancellation rate
   - Rating trends

---

#### UC-P11: Respond to Reviews
**Actor:** Provider  
**Description:** Provider responds to customer reviews  
**Preconditions:** Review exists  
**Postconditions:** Response saved  

**Main Flow:**
1. Provider views review
2. Provider clicks "Respond"
3. Provider writes response
4. System saves response
5. System notifies consumer

---

## Admin Use Cases

### Use Case Diagram

```mermaid
graph TD
    A[Admin] --> B[Login]
    A --> C[View Dashboard]
    A --> D[Manage Users]
    A --> E[Verify Providers]
    A --> F[Suspend User]
    A --> G[Activate User]
    A --> H[View All Bookings]
    A --> I[View Analytics]
    A --> J[Manage Categories]
    A --> K[Manage Content]
    A --> L[Handle Disputes]
    A --> M[Send System Notifications]
    A --> N[Configure Settings]
    
    E --> O{Verification Decision}
    O -->|Approve| P[Activate Provider]
    O -->|Reject| Q[Send Rejection]
    
    I --> R[Platform Revenue]
    I --> S[User Growth]
    I --> T[Booking Trends]
    
    L --> U[Investigate Dispute]
    U --> V{Resolution}
    V -->|Refund| W[Process Refund]
    V -->|Penalty| X[Apply Penalty]
```

### Detailed Admin Use Cases

#### UC-A01: View Dashboard
**Actor:** Admin  
**Description:** Admin views platform-wide statistics  
**Preconditions:** Admin authenticated  
**Postconditions:** Dashboard displayed  

**Main Flow:**
1. Admin navigates to Dashboard
2. System retrieves platform data
3. System displays:
   - Total users
   - Total providers
   - Total bookings
   - Platform revenue
   - Active bookings
   - Pending provider verifications
   - Recent disputes
   - System health status

---

#### UC-A02: Verify Providers
**Actor:** Admin  
**Description:** Admin reviews and approves/rejects provider applications  
**Preconditions:** Provider in pending status  
**Postconditions:** Provider status updated  

**Main Flow:**
1. Admin navigates to "Provider Verifications"
2. Admin views pending applications
3. Admin reviews provider documents
4. Admin checks business information
5. Admin clicks "Approve" or "Reject"
6. If approved:
   - System sets provider status to "active"
   - System sends approval email
   - Provider can now accept bookings
7. If rejected:
   - Admin enters rejection reason
   - System sets provider status to "rejected"
   - System sends rejection email

---

#### UC-A03: Manage Users
**Actor:** Admin  
**Description:** Admin manages user accounts  
**Preconditions:** Admin authenticated  
**Postconditions:** User status updated  

**Main Flow:**
1. Admin navigates to "Users"
2. System displays user list with filters
3. Admin searches for specific user
4. Admin views user details:
   - Account information
   - Booking history
   - Payment history
   - Reports/flags
5. Admin performs actions:
   - Suspend account
   - Activate account
   - Delete account
   - Send warning
   - View activity log

---

#### UC-A04: View All Bookings
**Actor:** Admin  
**Description:** Admin views all platform bookings  
**Preconditions:** Admin authenticated  
**Postconditions:** Booking list displayed  

**Main Flow:**
1. Admin navigates to "All Bookings"
2. System retrieves all bookings
3. System applies filters (date range, status, provider, consumer)
4. System displays booking list with:
   - Booking ID
   - Consumer and provider info
   - Service details
   - Date and time
   - Amount
   - Status
   - Actions (view details, cancel, refund)

---

#### UC-A05: Handle Disputes
**Actor:** Admin  
**Description:** Admin resolves disputes between consumers and providers  
**Preconditions:** Dispute reported  
**Postconditions:** Dispute resolved  

**Main Flow:**
1. Admin navigates to "Disputes"
2. Admin views reported dispute
3. Admin reviews:
   - Booking details
   - Communication history
   - Evidence provided
   - Policies involved
4. Admin makes decision:
   - Refund to consumer
   - Partial refund
   - No action (uphold booking)
   - Apply penalty to provider
5. System executes decision
6. System notifies both parties
7. System updates dispute status to "resolved"

---

#### UC-A06: View Analytics
**Actor:** Admin  
**Description:** Admin views platform analytics  
**Preconditions:** Admin authenticated  
**Postconditions:** Analytics displayed  

**Main Flow:**
1. Admin navigates to "Analytics"
2. System retrieves platform data
3. System displays:
   - Revenue trends (monthly, yearly)
   - User growth chart
   - Booking volume by service type
   - Geographic distribution
   - Provider performance rankings
   - Consumer satisfaction metrics
   - Cancellation rates

---

#### UC-A07: Manage Categories
**Actor:** Admin  
**Description:** Admin manages service categories and tags  
**Preconditions:** Admin authenticated  
**Postconditions:** Categories updated  

**Main Flow:**
1. Admin navigates to "Categories"
2. System displays existing categories
3. Admin performs actions:
   - Add new category
   - Edit category name
   - Delete category
   - Add subcategories
   - Manage tags

---

#### UC-A08: Configure Settings
**Actor:** Admin  
**Description:** Admin configures platform settings  
**Preconditions:** Admin authenticated  
**Postconditions:** Settings updated  

**Main Flow:**
1. Admin navigates to "Settings"
2. Admin configures:
   - Platform fees (commission percentage)
   - Payment gateway settings
   - Email/SMS settings
   - Notification preferences
   - Security settings
   - API rate limits
3. Admin saves changes
4. System updates configuration

---

## Sequence Diagrams

### Sequence Diagram: Booking Flow

```mermaid
sequenceDiagram
    participant C as Consumer
    participant F as Flutter App
    participant API as Backend API
    participant Redis as Redis Cache
    participant DB as PostgreSQL
    participant Stripe as Stripe API
    participant P as Provider
    
    C->>F: Select service & date/time
    F->>API: POST /api/v1/bookings
    API->>Redis: Acquire slot lock (10min TTL)
    Redis-->>API: Lock acquired
    API->>DB: Check for conflicts
    DB-->>API: No conflicts
    API->>DB: Calculate pricing (apply rules)
    DB-->>API: Total price
    API->>DB: Create booking (pending)
    DB-->>API: Booking created
    API-->>F: Return booking ID & payment intent
    F->>C: Show payment screen
    
    C->>F: Enter payment details
    F->>Stripe: Create PaymentIntent
    Stripe-->>F: Client secret
    C->>Stripe: Confirm payment
    Stripe->>API: Webhook: payment succeeded
    API->>DB: Update booking to confirmed
    API->>DB: Confirm booked_slots
    API->>Redis: Release lock
    API->>P: Send notification (new booking)
    API->>C: Send confirmation email
    API->>C: Send push notification
    F->>C: Show booking confirmed
```

### Sequence Diagram: Provider Accepts Booking

```mermaid
sequenceDiagram
    participant P as Provider
    participant F as Flutter App
    participant API as Backend API
    participant DB as PostgreSQL
    participant C as Consumer
    
    P->>F: View pending bookings
    F->>API: GET /api/v1/provider/bookings
    API->>DB: Query pending bookings
    DB-->>API: Booking list
    API-->>F: Return bookings
    F->>P: Display bookings
    
    P->>F: Accept booking
    F->>API: PATCH /api/v1/provider/bookings/:id/status
    API->>DB: Update booking to confirmed
    API->>DB: Confirm booked_slots
    API->>C: Send email notification
    API->>C: Send push notification
    API-->>F: Success response
    F->>P: Show booking accepted
```

### Sequence Diagram: Authentication Flow

```mermaid
sequenceDiagram
    participant U as User
    participant F as Flutter App
    participant API as Backend API
    participant DB as PostgreSQL
    participant Storage as Secure Storage
    
    U->>F: Enter email & password
    F->>API: POST /api/v1/auth/login
    API->>DB: Verify credentials
    DB-->>API: User found
    API->>API: Generate JWT access token (15min)
    API->>API: Generate refresh token (7 days)
    API->>DB: Store refresh token hash
    API-->>F: Return tokens
    F->>Storage: Store tokens securely
    Storage-->>F: Stored
    F->>U: Navigate to dashboard
    
    Note over F,API: Token expires after 15min
    F->>API: API call with expired token
    API-->>F: 401 Unauthorized
    F->>Storage: Get refresh token
    F->>API: POST /api/v1/auth/refresh
    API->>DB: Verify refresh token
    DB-->>API: Valid
    API->>API: Generate new access token
    API-->>F: New access token
    F->>Storage: Update access token
    F->>API: Retry original request
```

---

## Class Diagram

```mermaid
classDiagram
    class User {
        +UUID id
        +String email
        +String password_hash
        +String phone
        +String full_name
        +String avatar_url
        +UserRole role
        +Boolean is_verified
        +Boolean is_active
        +JSONB preferences
        +DateTime created_at
        +DateTime updated_at
    }
    
    class RefreshToken {
        +UUID id
        +UUID user_id
        +String token_hash
        +DateTime expires_at
        +DateTime created_at
    }
    
    class Provider {
        +UUID id
        +UUID user_id
        +String business_name
        +String description
        +String logo_url
        +String cover_url
        +ServiceType service_type
        +Decimal rating
        +Integer review_count
        +Boolean is_verified
        +Boolean is_active
        +Point location
        +String address
        +String city
        +String country
        +String contact_phone
        +String contact_email
    }
    
    class Service {
        +UUID id
        +UUID provider_id
        +String title
        +String description
        +ServiceType service_type
        +Decimal base_price
        +String currency
        +PricingModel pricing_model
        +JSONB images
        +JSONB tags
        +JSONB attributes
        +Boolean is_available
        +Integer max_capacity
        +Decimal min_duration_hrs
        +Decimal max_duration_hrs
        +JSONB cancellation_policy
    }
    
    class AvailabilityTemplate {
        +UUID id
        +UUID service_id
        +Integer day_of_week
        +Time start_time
        +Time end_time
        +Boolean is_available
        +Date effective_from
        +Date effective_to
    }
    
    class BookedSlot {
        +UUID id
        +UUID service_id
        +UUID booking_id
        +Date date
        +Time start_time
        +Time end_time
        +SlotStatus status
    }
    
    class PricingRule {
        +UUID id
        +UUID service_id
        +RuleType rule_type
        +Decimal multiplier
        +Decimal fixed_adjustment
        +Date start_date
        +Date end_date
        +Integer day_of_week
        +Integer min_advance_days
        +Integer min_bookings
        +Integer priority
        +Boolean is_active
    }
    
    class Booking {
        +UUID id
        +UUID consumer_id
        +EventType event_type
        +Date event_date
        +String event_name
        +BookingStatus status
        +Decimal total_amount
        +String currency
        +Decimal deposit_amount
        +Boolean deposit_paid
        +String notes
        +String special_requests
    }
    
    class BookingItem {
        +UUID id
        +UUID booking_id
        +UUID service_id
        +UUID provider_id
        +Date date
        +Time start_time
        +Time end_time
        +Decimal duration_hours
        +Decimal unit_price
        +JSONB applied_pricing
        +Decimal subtotal
        +BookingItemStatus status
    }
    
    class Payment {
        +UUID id
        +UUID booking_id
        +Decimal amount
        +String currency
        +PaymentMethod payment_method
        +String stripe_payment_intent_id
        +PaymentStatus status
        +JSONB metadata
    }
    
    class Review {
        +UUID id
        +UUID booking_item_id
        +UUID consumer_id
        +UUID provider_id
        +Integer rating
        +String comment
        +JSONB images
        +Boolean is_anonymous
    }
    
    class Notification {
        +UUID id
        +UUID user_id
        +NotificationType type
        +String title
        +String body
        +JSONB data
        +Boolean is_read
    }
    
    class Bookmark {
        +UUID id
        +UUID user_id
        +UUID service_id
    }
    
    class UserPreferences {
        +UUID id
        +UUID user_id
        +JSONB preferred_hall_themes
        +JSONB preferred_car_types
        +JSONB preferred_photographer_styles
        +JSONB preferred_entertainer_types
        +JSONB budget_range
        +JSONB preferred_cities
        +JSONB notification_settings
    }
    
    %% Relationships
    User "1" -- "*" RefreshToken : has
    User "1" -- "1" Provider : is (if role=provider)
    User "1" -- "*" Booking : creates
    User "1" -- "*" Bookmark : creates
    User "1" -- "1" UserPreferences : has
    User "1" -- "*" Notification : receives
    
    Provider "1" -- "*" Service : offers
    Provider "1" -- "*" Review : receives
    
    Service "1" -- "*" AvailabilityTemplate : has
    Service "1" -- "*" BookedSlot : has
    Service "1" -- "*" PricingRule : has
    Service "1" -- "*" BookingItem : included in
    
    Booking "1" -- "*" BookingItem : contains
    Booking "1" -- "*" Payment : has
    
    BookingItem "1" -- "1" BookedSlot : creates
    BookingItem "1" -- "1" Review : can have
    
    BookingItem "1" -- "*" PricingRule : applies
```

---

## Activity Diagrams

### Activity Diagram: Consumer Booking Process

```mermaid
flowchart TD
    Start([Start]) --> Search[Search Services]
    Search --> ViewDetails[View Service Details]
    ViewDetails --> CheckAvail{Check Availability}
    CheckAvail -->|Available| SelectDate[Select Date & Time]
    CheckAvail -->|Not Available| Search
    
    SelectDate --> AddToCart[Add to Booking Cart]
    AddToCart --> MoreServices{Add More Services?}
    MoreServices -->|Yes| Search
    MoreServices -->|No| ReviewBooking[Review Booking]
    
    ReviewBooking --> ConfirmBooking{Confirm?}
    ConfirmBooking -->|No| Search
    ConfirmBooking -->|Yes| LockSlots[Lock Slots in Redis]
    
    LockSlots --> MakePayment[Make Payment]
    MakePayment --> PaymentSuccess{Payment Successful?}
    PaymentSuccess -->|No| ReleaseLock[Release Lock]
    ReleaseLock --> Search
    PaymentSuccess -->|Yes| ConfirmBookingDB[Confirm Booking in DB]
    
    ConfirmBookingDB --> ReleaseLock2[Release Lock]
    ReleaseLock2 --> SendNotifications[Send Notifications]
    SendNotifications --> End([End - Booking Confirmed])
```

### Activity Diagram: Provider Onboarding

```mermaid
flowchart TD
    Start([Start]) --> RegisterUser[Register User Account]
    RegisterUser --> NavigateProvider[Navigate to Become Provider]
    NavigateProvider --> EnterBusinessInfo[Enter Business Information]
    EnterBusinessInfo --> UploadDocs[Upload Documents]
    UploadDocs --> UploadImages[Upload Logo & Cover]
    UploadImages --> Submit[Submit Application]
    Submit --> Pending[Pending Verification]
    
    Pending --> AdminReview{Admin Review}
    AdminReview -->|Approved| Active[Provider Active]
    AdminReview -->|Rejected| NotifyRejection[Send Rejection Notification]
    
    Active --> SetupServices[Setup Services]
    SetupServices --> SetAvailability[Set Availability]
    SetAvailability --> SetPricing[Set Pricing Rules]
    SetPricing --> Ready([Ready to Accept Bookings])
    
    NotifyRejection --> End([End])
```

### Activity Diagram: Admin Dispute Resolution

```mermaid
flowchart TD
    Start([Start]) --> ViewDisputes[View Reported Disputes]
    ViewDisputes --> SelectDispute[Select Dispute]
    SelectDispute --> ReviewEvidence[Review Evidence]
    ReviewEvidence --> CheckPolicies[Check Policies]
    CheckPolicies --> MakeDecision{Make Decision}
    
    MakeDecision -->|Refund Consumer| ProcessRefund[Process Refund]
    MakeDecision -->|Partial Refund| ProcessPartial[Process Partial Refund]
    MakeDecision -->|No Action| NoAction[No Action Taken]
    MakeDecision -->|Penalty Provider| ApplyPenalty[Apply Penalty to Provider]
    
    ProcessRefund --> NotifyBoth[Notify Both Parties]
    ProcessPartial --> NotifyBoth
    NoAction --> NotifyBoth
    ApplyPenalty --> NotifyBoth
    
    NotifyBoth --> UpdateStatus[Update Dispute Status]
    UpdateStatus --> CloseDispute[Close Dispute]
    CloseDispute --> End([End - Dispute Resolved])
```

---

## Data Flow Diagrams

### Level 1 DFD: Consumer Booking

```mermaid
graph LR
    C[Consumer] -->|Search Request| P1[Process 1: Search Services]
    P1 --> DB[(Database)]
    DB --> P1
    P1 --> C
    
    C -->|Booking Request| P2[Process 2: Create Booking]
    P2 --> R[(Redis)]
    R --> P2
    P2 --> DB
    DB --> P2
    P2 --> C
    
    C -->|Payment| P3[Process 3: Process Payment]
    P3 --> S[Stripe]
    S --> P3
    P3 --> DB
    P3 --> C
    
    P3 -->|Notification| P4[Process 4: Send Notifications]
    P4 --> C
    P4 --> Pr[Provider]
```

---

## State Diagrams

### State Diagram: Booking Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Draft: Consumer creates booking
    Draft --> Pending: Consumer confirms
    Pending --> Confirmed: Provider accepts OR Payment successful
    Pending --> Cancelled: Consumer cancels OR Provider rejects
    Confirmed --> InProgress: Event date arrives
    InProgress --> Completed: Event finished
    InProgress --> Cancelled: Cancellation (with penalty)
    Completed --> [*]
    Cancelled --> [*]
    
    note right of Pending
        Slots locked in Redis
        Payment initiated
    end note
    
    note right of Confirmed
        Slots confirmed in DB
        Notifications sent
    end note
```

### State Diagram: Provider Verification

```mermaid
stateDiagram-v2
    [*] --> Pending: Provider submits application
    Pending --> UnderReview: Admin reviews
    UnderReview --> Approved: Admin approves
    UnderReview --> Rejected: Admin rejects
    Approved --> Active: Provider completes setup
    Rejected --> [*]
    Active --> Suspended: Admin suspends
    Suspended --> Active: Admin reactivates
    Active --> [*]
```

---

## Entity Relationship Diagram

```mermaid
erDiagram
    USER ||--o{ REFRESH_TOKEN : has
    USER ||--|| PROVIDER : "is (if provider)"
    USER ||--o{ BOOKING : creates
    USER ||--o{ BOOKMARK : creates
    USER ||--|| USER_PREFERENCES : has
    USER ||--o{ NOTIFICATION : receives
    USER ||--o{ REVIEW : writes
    
    PROVIDER ||--o{ SERVICE : offers
    PROVIDER ||--o{ REVIEW : receives
    
    SERVICE ||--o{ AVAILABILITY_TEMPLATE : has
    SERVICE ||--o{ BOOKED_SLOT : has
    SERVICE ||--o{ PRICING_RULE : has
    SERVICE ||--o{ BOOKING_ITEM : included in
    
    BOOKING ||--o{ BOOKING_ITEM : contains
    BOOKING ||--o{ PAYMENT : has
    
    BOOKING_ITEM ||--|| BOOKED_SLOT : creates
    BOOKING_ITEM ||--o| REVIEW : can have
    
    BOOKING_ITEM }o--|| PRICING_RULE : applies
    
    USER {
        uuid id PK
        string email UK
        string password_hash
        string phone
        string full_name
        string avatar_url
        varchar role
        boolean is_verified
        boolean is_active
        jsonb preferences
        timestamp created_at
        timestamp updated_at
    }
    
    PROVIDER {
        uuid id PK
        uuid user_id FK
        string business_name
        text description
        string logo_url
        string cover_url
        varchar service_type
        decimal rating
        integer review_count
        boolean is_verified
        boolean is_active
        point location
        text address
        varchar city
        varchar country
    }
    
    SERVICE {
        uuid id PK
        uuid provider_id FK
        string title
        text description
        varchar service_type
        decimal base_price
        varchar currency
        varchar pricing_model
        jsonb images
        jsonb tags
        jsonb attributes
        boolean is_available
        integer max_capacity
    }
    
    BOOKING {
        uuid id PK
        uuid consumer_id FK
        varchar event_type
        date event_date
        varchar status
        decimal total_amount
        varchar currency
        decimal deposit_amount
        boolean deposit_paid
    }
```

---

## Summary

This document provides comprehensive UML diagrams and use case documentation for the Event & Wedding Booking System. The system supports three main user types:

1. **Consumer** - End users who search, book, and pay for event services
2. **Provider** - Service providers who manage their offerings and accept bookings
3. **Admin** - Platform administrators who oversee operations and resolve disputes

The system uses a microservices-like architecture with:
- Flutter mobile app for consumers and providers
- Node.js backend with Fastify
- PostgreSQL for persistent data
- Redis for caching and slot locking
- Stripe for payment processing
- WebSocket for real-time notifications

All use cases include detailed flows, alternative paths, and error handling to ensure robust system behavior.
