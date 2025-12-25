# Requirements Document

## Introduction

This document specifies the requirements for transforming the existing Flutter grocery app into a production-ready application with a Supabase backend, Cloudflare R2 image storage, role-based access control (Customer/Admin), comprehensive admin dashboard, and real-time delivery tracking using Google Maps API. The system will enable customers to browse products, place orders, and track deliveries, while administrators can manage products, orders, deliveries, users, and analytics.

## Glossary

- **Supabase**: Backend-as-a-Service platform providing PostgreSQL database, authentication, and real-time subscriptions
- **Cloudflare R2**: Object storage service for storing product images and user avatars
- **Customer**: A user role that can browse products, place orders, and track their own deliveries
- **Admin**: A user role with elevated privileges to manage products, orders, users, and deliveries
- **Order**: A collection of products purchased by a customer with delivery information
- **Delivery**: The fulfillment process of transporting an order from the store to the customer
- **Rider**: A delivery person assigned to transport orders to customers
- **RLS**: Row Level Security - Supabase feature for database-level access control
- **Real-time Tracking**: Live GPS-based location updates of delivery riders on a map

## Requirements

### Requirement 1: User Authentication and Authorization

**User Story:** As a user, I want to securely sign up, log in, and have my access controlled based on my role, so that I can use the app features appropriate to my account type.

#### Acceptance Criteria

1. WHEN a user submits valid email and password credentials THEN the Authentication_System SHALL create a new account and return authentication tokens
2. WHEN a user attempts to log in with valid credentials THEN the Authentication_System SHALL authenticate the user and establish a session
3. WHEN a user logs in THEN the Authentication_System SHALL retrieve the user role (Customer or Admin) from the database and store it in the session
4. WHILE a user session is active THEN the Authentication_System SHALL maintain authentication state across app restarts using secure token storage
5. WHEN an unauthenticated user attempts to access protected routes THEN the Navigation_System SHALL redirect the user to the login screen
6. WHEN a Customer user attempts to access Admin routes THEN the Authorization_System SHALL deny access and display an unauthorized message
7. WHEN a user requests password reset THEN the Authentication_System SHALL send a password reset email to the registered address

### Requirement 2: Product Management

**User Story:** As an admin, I want to manage the product catalog, so that I can add, update, and remove products available for customers to purchase.

#### Acceptance Criteria

1. WHEN an admin creates a new product with name, description, price, category, and image THEN the Product_Management_System SHALL store the product in the database and upload the image to Cloudflare R2
2. WHEN an admin updates product details THEN the Product_Management_System SHALL persist the changes and update the image in R2 if a new image is provided
3. WHEN an admin deletes a product THEN the Product_Management_System SHALL mark the product as inactive rather than permanently deleting it
4. WHEN an admin uploads a product image THEN the Image_Storage_System SHALL validate the file type (JPEG, PNG, WebP) and size (maximum 5MB) before uploading to R2
5. WHEN a customer browses products THEN the Product_Display_System SHALL retrieve only active products from the database
6. WHEN an admin views the product list THEN the Product_Management_System SHALL display all products including inactive ones with their status clearly indicated
7. WHEN an admin assigns a product to a category THEN the Product_Management_System SHALL validate that the category exists before saving

### Requirement 3: Category Management

**User Story:** As an admin, I want to manage product categories, so that products can be organized and customers can browse by category.

#### Acceptance Criteria

1. WHEN an admin creates a new category with name and optional image THEN the Category_Management_System SHALL store the category in the database
2. WHEN an admin updates a category THEN the Category_Management_System SHALL persist the changes to the database
3. WHEN an admin attempts to delete a category containing products THEN the Category_Management_System SHALL prevent deletion and display a warning message
4. WHEN a customer views the home screen THEN the Category_Display_System SHALL show all active categories with their images

### Requirement 4: Shopping Cart and Checkout

**User Story:** As a customer, I want to add products to my cart and complete checkout, so that I can purchase groceries for delivery.

#### Acceptance Criteria

1. WHEN a customer adds a product to the cart THEN the Cart_System SHALL store the item with quantity in the database linked to the user
2. WHEN a customer updates item quantity in the cart THEN the Cart_System SHALL persist the new quantity to the database
3. WHEN a customer removes an item from the cart THEN the Cart_System SHALL delete the item from the database
4. WHEN a customer views the cart THEN the Cart_System SHALL calculate and display the subtotal, delivery fee, and total amount
5. WHEN a customer proceeds to checkout with delivery address and payment method THEN the Order_System SHALL create an order with status "pending" and clear the cart
6. WHEN a customer completes checkout THEN the Order_System SHALL send an order confirmation notification to the customer

### Requirement 5: Order Management

**User Story:** As an admin, I want to manage customer orders, so that I can process, track, and fulfill orders efficiently.

#### Acceptance Criteria

1. WHEN an admin views the orders dashboard THEN the Order_Management_System SHALL display all orders with filtering options by status, date range, and customer
2. WHEN an admin updates an order status (pending, confirmed, preparing, out_for_delivery, delivered, cancelled) THEN the Order_Management_System SHALL persist the change and notify the customer
3. WHEN an admin assigns a rider to an order THEN the Order_Management_System SHALL update the order with rider details and change status to "out_for_delivery"
4. WHEN a customer views their orders THEN the Order_System SHALL display only orders belonging to that customer
5. WHEN an order status changes THEN the Notification_System SHALL send a push notification to the customer with the updated status

### Requirement 6: Delivery and Route Tracking

**User Story:** As a customer, I want to track my delivery in real-time on a map, so that I can know when my order will arrive.

#### Acceptance Criteria

1. WHEN a rider starts delivery THEN the Tracking_System SHALL begin recording GPS coordinates at 10-second intervals
2. WHEN a customer opens the tracking screen for an active delivery THEN the Tracking_System SHALL display the rider's current location on a Google Map
3. WHEN the rider's location updates THEN the Tracking_System SHALL update the map marker position in real-time using Supabase real-time subscriptions
4. WHEN a customer views the tracking screen THEN the Tracking_System SHALL display the estimated delivery time based on current distance and traffic
5. WHEN a delivery is completed THEN the Tracking_System SHALL stop location updates and display delivery confirmation
6. WHEN an admin views the delivery dashboard THEN the Delivery_Management_System SHALL display all active deliveries on a map with rider locations

### Requirement 7: Rider Management

**User Story:** As an admin, I want to manage delivery riders, so that I can assign deliveries and track rider performance.

#### Acceptance Criteria

1. WHEN an admin creates a new rider profile with name, phone, vehicle details, and photo THEN the Rider_Management_System SHALL store the rider in the database
2. WHEN an admin views the rider list THEN the Rider_Management_System SHALL display all riders with their current status (available, on_delivery, offline)
3. WHEN an admin assigns a delivery to a rider THEN the Rider_Management_System SHALL update the rider status to "on_delivery" and link the order
4. WHEN a rider completes a delivery THEN the Rider_Management_System SHALL update the rider status to "available" and increment their delivery count
5. WHEN an admin views rider details THEN the Rider_Management_System SHALL display delivery history and performance metrics

### Requirement 8: User Management (Admin)

**User Story:** As an admin, I want to manage user accounts, so that I can view customer information and handle account issues.

#### Acceptance Criteria

1. WHEN an admin views the user list THEN the User_Management_System SHALL display all customers with their registration date, order count, and status
2. WHEN an admin searches for a user by name, email, or phone THEN the User_Management_System SHALL return matching results
3. WHEN an admin disables a user account THEN the User_Management_System SHALL prevent that user from logging in and display a disabled account message
4. WHEN an admin views user details THEN the User_Management_System SHALL display the user's profile, order history, and addresses

### Requirement 9: Admin Dashboard and Analytics

**User Story:** As an admin, I want to view business analytics and metrics, so that I can make informed decisions about the grocery business.

#### Acceptance Criteria

1. WHEN an admin opens the dashboard THEN the Analytics_System SHALL display key metrics including total orders, revenue, active users, and pending deliveries
2. WHEN an admin views the sales chart THEN the Analytics_System SHALL display order and revenue trends for the selected time period (daily, weekly, monthly)
3. WHEN an admin views the top products report THEN the Analytics_System SHALL display the best-selling products by quantity and revenue
4. WHEN an admin views the delivery performance report THEN the Analytics_System SHALL display average delivery time and rider performance metrics

### Requirement 10: Customer Profile Management

**User Story:** As a customer, I want to manage my profile and delivery addresses, so that I can keep my information up to date.

#### Acceptance Criteria

1. WHEN a customer updates their profile (name, phone, avatar) THEN the Profile_System SHALL persist the changes to the database and upload the avatar to R2
2. WHEN a customer adds a new delivery address THEN the Address_System SHALL store the address with optional label (Home, Work, Other)
3. WHEN a customer sets a default delivery address THEN the Address_System SHALL mark the address as default and unmark any previous default
4. WHEN a customer deletes an address THEN the Address_System SHALL remove the address from the database

### Requirement 11: Favorites and Wishlist

**User Story:** As a customer, I want to save products to my favorites, so that I can quickly find and reorder products I like.

#### Acceptance Criteria

1. WHEN a customer adds a product to favorites THEN the Favorites_System SHALL store the product reference in the database linked to the user
2. WHEN a customer removes a product from favorites THEN the Favorites_System SHALL delete the reference from the database
3. WHEN a customer views their favorites THEN the Favorites_System SHALL display all favorited products with current prices and availability

### Requirement 12: Search and Filtering

**User Story:** As a customer, I want to search and filter products, so that I can quickly find what I need.

#### Acceptance Criteria

1. WHEN a customer enters a search query THEN the Search_System SHALL return products matching the query in name or description
2. WHEN a customer filters by category THEN the Search_System SHALL return only products in the selected category
3. WHEN a customer sorts results by price or name THEN the Search_System SHALL reorder the results accordingly
4. WHEN a customer applies multiple filters THEN the Search_System SHALL combine all filter criteria in the query

### Requirement 13: Image Storage with Cloudflare R2

**User Story:** As a system administrator, I want product and user images stored in Cloudflare R2, so that images load quickly and storage costs are optimized.

#### Acceptance Criteria

1. WHEN an image is uploaded THEN the Image_Storage_System SHALL generate a unique filename and store the image in the appropriate R2 bucket (products or avatars)
2. WHEN an image is requested THEN the Image_Storage_System SHALL return a signed URL or public URL based on bucket configuration
3. WHEN an image is replaced THEN the Image_Storage_System SHALL delete the old image from R2 to prevent orphaned files
4. WHEN an image upload fails THEN the Image_Storage_System SHALL return an error message and not save partial data

### Requirement 14: Real-time Data Synchronization

**User Story:** As a user, I want to see real-time updates, so that I have the latest information without manually refreshing.

#### Acceptance Criteria

1. WHEN a product's stock or price changes THEN the Real_Time_System SHALL push the update to all connected clients viewing that product
2. WHEN an order status changes THEN the Real_Time_System SHALL push the update to the customer's app immediately
3. WHEN a rider's location updates THEN the Real_Time_System SHALL push the coordinates to customers tracking that delivery
4. WHEN an admin is viewing the dashboard THEN the Real_Time_System SHALL update metrics as new orders arrive

### Requirement 15: UI/UX Improvements

**User Story:** As a user, I want a polished and intuitive interface, so that I can use the app efficiently and enjoyably.

#### Acceptance Criteria

1. WHEN the app loads THEN the UI_System SHALL display a branded splash screen with the app logo
2. WHEN data is loading THEN the UI_System SHALL display skeleton loaders instead of blank screens
3. WHEN an error occurs THEN the UI_System SHALL display a user-friendly error message with retry option
4. WHEN a user performs an action THEN the UI_System SHALL provide visual feedback within 100 milliseconds
5. WHEN the app is used on different screen sizes THEN the UI_System SHALL adapt the layout responsively

