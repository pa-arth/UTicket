# UTicket

Opening access to ticket reselling for University of Texas students

## Project Information

**Group number:** 3

**Team members:** Naveed Sadarulanum, Zaviyan Tharwani, Swarna Kadagadkai, Paarth Jamdagneya

**Name of project:** UTicket

## Dependencies

- **Xcode:** 16.30 (or later)
- **Swift:** 5.0
- **iOS Deployment Target:** iOS 13.0 or later

### Frameworks and Packages

The project uses Swift Package Manager (SPM) for dependency management. The following packages are required:

- **Firebase iOS SDK** (v12.4.0)
  - FirebaseAuth
  - FirebaseFirestore
  - FirebaseStorage
  - FirebaseCore
- **Kingfisher** (v8.6.2) - Image loading and caching library

### Special Instructions

1. **Opening the Project:**
   - Open `UTicket.xcodeproj` in Xcode
   - The project uses Swift Package Manager, so dependencies will be automatically resolved when you open the project

2. **Testing:**
   - Use an iPhone simulator (iPhone 12 or later recommended)
   - For authentication testing, create test accounts with `@utexas.edu` or `@my.utexas.edu` email domains
   - The app validates that users have a UT Austin email address

## Features

| Feature | Description | Release Planned | Release Actual | Deviations (if any) | Who/Percentage Worked On |
|---------|-------------|-----------------|----------------|---------------------|--------------------------|
| **Authentication & Onboarding** | User login, sign up, and role selection (Buyer/Seller). Includes email validation for UT Austin domains (@utexas.edu, @my.utexas.edu) | Alpha | Alpha | None | Paarth (60%), Naveed (30%), Zaviyan (10%) |
| **Profile Creation** | User profile setup with photo upload, full name, email, and password. Profile images stored in Firebase Storage | Alpha | Alpha | Password and confirm password fields do not use secure text entry for testing purposes (autofill causes issues on Mac) | Paarth (70%), Naveed (20%), Zaviyan (10%) |
| **Settings Screen** | Profile management, role switching between Buyer/Seller, password change, notification preferences, sign out, and profile image update | Alpha | Beta | None | Paarth (65%), Naveed (35%)|
| **Seller Dashboard** | View all listings created by the current seller. Displays tickets in a table view with image, event name, price, and details | Alpha | Alpha | None | Paarth (60%), Naveed (40%) |
| **Seller Listing Creation** | Create new ticket listings with image upload, event name, date, time, price, and seat details. Images stored in Firebase Storage, listings saved to Firestore | Alpha | Alpha | None | Naveed (60%), Paarth (40%) |
| **Explore Tickets (Buyer Flow)** | Browse all available ticket listings. Includes search functionality to filter by event name, seat details, price, date, and time. Real-time data fetching from Firestore | Alpha | Alpha | None | Zaviyan (60%), Paarth (30%), Naveed (10%) |
| **Ticket Details View** | Detailed view of individual ticket listings showing full event information, image, price, seat details, date, time, and location | Alpha | Final | None | Zaviyan (50%), Paarth (50%)|
| **Wishlist Functionality** | Add/remove tickets to wishlist. Wishlist items persist in Firestore and sync across app sessions | Alpha | Final | None | Paarth (60%), Naveed (40%) |
| **Search & Filter** | Real-time search functionality in Explore Tickets screen. Filters listings as user types, searches across event name, seat details, price, date, and time | Alpha | Final | None | Naveed (100%) |
| **Notifications System** | Real-time notifications for sellers when buyers show interest in their listings, and for buyers when new listings match their interests. Banner notifications displayed in-app | Beta | Final | None | Paarth (100%)|
| **Image Loading & Caching** | Efficient image loading using Kingfisher library. Images cached locally for improved performance. Used for profile pictures, ticket images, and listing thumbnails | Alpha | Beta | None | Naveed (60%), Paarth (40%)|
| **Base UI Components** | Reusable UI components including text field styling with active outline states, profile icon in navigation bar, and consistent color scheme (#BF5700) | Alpha | Alpha | UI not as polished as originally planned due to team member dropping the class; focus shifted to functionality over polish | Paarth (50%), Naveed (30%), Zaviyan (20%) |
| **Firebase Integration** | User authentication, Firestore database for listings and wishlists, Firebase Storage for images. User role management and profile data storage | Alpha | Beta | None | Paarth (60%), Naveed (35%), Zaviyan (5%) |
| **Payment Integration (Stripe)** | Stripe API configuration and setup | Beta | Final | Fully integrated as payment link. | Paarth (100%)|

## Deviations

1. **Password Field Security:** Password and confirm password fields in the Profile Creation screen do not use secure text entry (password masking) for testing purposes. This was done because autofill functionality causes issues on Mac simulators during development and testing.

2. **UI Polish:** The UI is not as polished as originally planned. This occurred because a team member (Zaviyan) dropped the class mid-project, and the remaining team prioritized core functionality over extensive UI refinement to ensure all essential features were completed.

3. **Stripe Payment Integration:** Payment processing is not fully implemented through Stripe API. Rather, we chose to use Stripe payment links for simplicity.
