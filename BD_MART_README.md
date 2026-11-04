# BD_MART - Bahir Dar Marketplace

## Final Year University Project
**Course:** Software Engineering / Computer Science  
**Institution:** Bahir Dar University  
**Developer:** Bezma834

---

## 📍 Project Overview

BD_MART is a **digital marketplace platform** designed for the Bahir Dar market in Ethiopia, inspired by Shein and Alibaba but tailored for local farmers, artisans, and merchants. The platform connects buyers and sellers in the Bahir Dar region, enabling online shopping with local delivery, payment, and tracking features.

**Mission:** Modernize traditional Bahir Dar market trading by providing a digital platform that bridges the gap between local sellers and tech-savvy buyers, supporting Ethiopia's digital economy transformation.

---

## 🏗️ Architecture

```
┌─────────────────┐      ┌────────────────────┐
│   Mobile/Web    │      │   Admin Dashboard  │
│   Application   │◄────►│   (React/Vue)      │
└─────────────────┘      └────────────────────┘
           │                       │
           │ (REST API)          │
           ▼                       ▼
┌─────────────────┐      ┌────────────────────┐
│   BD_MART API   │◄────►│   Hasura GraphQL   │
│   (Node.js)     │      │   (PostgreSQL API) │
└─────────────────┘      └────────────────────┘
           │                       │
           │                       │
           ▼                       ▼
┌─────────────────┐      ┌────────────────────┐
│  PostgreSQL DB  │      │  Storage (Supabase)│
│  (Users, Products,│    │  Images, Files     │
│   Orders, etc.) │      └────────────────────┘
└─────────────────┘
           ▲
           │
┌─────────────────┐
│  External Services    │
│  - Stripe (Payments)  │
│  - GeoIP (Location)  │
│  - EthioPay Gateway  │
│  - SMS/Email Notif.  │
└─────────────────┘
```

---

## 🛠️ Technology Stack

| **Layer** | **Technology** | **Purpose** |
|---|---|---|
| **Frontend** | React / Vue / React Native | User & seller applications |
| **Backend** | Node.js (Express.js) | Business logic, API layer |
| **Database** | PostgreSQL | Relational data storage |
| **API Gateway** | Hasura GraphQL | Auto-generated CRUD & real-time APIs |
| **Authentication** | JWT (jsonwebtoken) + bcrypt | Secure user auth |
| **Payments** | Stripe + Ethiopian gateways | Card, Telebirr, M-Birr, CBE Birr |
| **Mapping** | Google Maps / OpenStreetMap | Location tracking, distance calculation |
| **Geo** | PostGIS + geolib | Spatial queries, nearby partners |
| **Deployment** | Docker / Render / Railway | Containerized deployment |
| **Testing** | Jest, Supertest, Postman | API testing |

---

## 📦 Installation & Setup

### Prerequisites

- Node.js >= 18.x
- PostgreSQL >= 13.x
- Hasura CLI (optional, for local development)
- Stripe account (for payment processing)
- Google Maps API key (optional, for mapping features)

### 1. Clone the Repository

```bash
git clone https://github.com/Bezma834/BD_MART.git
cd BD_MART
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Environment Configuration

Copy the example environment file and configure:

```bash
cp .env.example .env
```

Edit `.env` with your settings:

```env
# Server
PORT=5000
NODE_ENV=development

# Database
DATABASE_URL=postgres://postgres:password@localhost:5432/bd_mart

# Hasura
HASURA_GRAPHQL_ENDPOINT=http://localhost:8080/v1/graphql
HASURA_ADMIN_SECRET=myadminsecretkey

# Authentication
JWT_SECRET=your_very_secret_jwt_key_min_32_chars
JWT_EXPIRES_IN=1d
BCRYPT_SALT_ROUNDS=12

# Payments
STRIPE_SECRET_KEY=your_stripe_secret_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret

# Mapping (optional)
GOOGLE_MAPS_API_KEY=your_google_maps_api_key

# CORS
CORS_ORIGIN=http://localhost:3000,exp://localhost:8081

# EthioPay (local Ethiopian payment gateways)
ETHIOPAY_MERCHANT_ID=
ETHIOPAY_PRIVATE_KEY=
```

### 4. Database Setup

#### Option A: Using Hasura Console
1. Start Hasura Console: `hasura serve`
2. Go to `http://localhost:8080/console`
3. Connect to your PostgreSQL database
4. Run the migration scripts in `database/migrations/`

#### Option B: Manual SQL

Run these SQL commands in your PostgreSQL database:

```sql
-- Create the database
CREATE DATABASE bd_mart;

-- Connect to bd_mart
\c bd_mart

-- Enable PostGIS extension for geo-spatial queries
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create users table
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'customer',
  phone VARCHAR(20),
  address TEXT,
  profile_image TEXT,
  status VARCHAR(20) DEFAULT 'active',
  email_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create products table
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  discounted_price DECIMAL(10, 2),
  category VARCHAR(100) DEFAULT 'other',
  subcategory VARCHAR(100),
  seller_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  images TEXT[] DEFAULT '{}',
  tags TEXT[] DEFAULT '{}',
  stock INTEGER DEFAULT 0,
  specifications JSONB DEFAULT '{}',
  ratings_average DECIMAL(3, 2) DEFAULT 0,
  ratings_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  location GEOGRAPHY(Point, 4326),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_seller ON products(seller_id);
CREATE INDEX idx_products_location ON products USING GIST(location);
CREATE INDEX idx_products_is_active ON products(is_active);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- Create orders table
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  order_total DECIMAL(12, 2) NOT NULL,
  payment_status VARCHAR(20) DEFAULT 'pending',
  status VARCHAR(20) DEFAULT 'pending',
  payment_method VARCHAR(50) DEFAULT 'card',
  shipping_address JSONB,
  delivery_partner_id INTEGER REFERENCES delivery_partners(id),
  estimated_delivery TIMESTAMP,
  paid_at TIMESTAMP,
  delivered_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create cart table
CREATE TABLE carts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  items JSONB DEFAULT '[]',
  total_amount DECIMAL(10, 2) DEFAULT 0,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create delivery_partners table
CREATE TABLE delivery_partners (
  id SERIAL PRIMARY KEY,
  user_id INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  full_name VARCHAR(255) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  vehicle_type VARCHAR(50) DEFAULT 'bicycle',
  status VARCHAR(20) DEFAULT 'available',
  rating DECIMAL(3, 2) DEFAULT 0,
  total_deliveries INTEGER DEFAULT 0,
  earnings DECIMAL(10, 2) DEFAULT 0,
  location GEOGRAPHY(Point, 4326),
  last_seen TIMESTAMP,
  is_verified BOOLEAN DEFAULT FALSE,
  id_document TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create order_items table (for detailed order breakdown)
CREATE TABLE order_items (
  id SERIAL PRIMARY KEY,
  order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
  product_id INTEGER REFERENCES products(id),
  quantity INTEGER NOT NULL DEFAULT 1,
  price DECIMAL(10, 2) NOT NULL, -- Price at purchase time
  color VARCHAR(50),
  size VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 5. Initialize Hasura (if using)

```bash
# Install Hasura CLI
curl -L https://hasura.io/download/hasura-cli/latest/linux/x86_64.hasura-cli.tar.gz | tar -xzf - -C /usr/local/bin/

# Connect to your database
hasura init bd-mart --database-url postgresql://postgres:password@localhost:5432/bd_mart

# Apply migrations
hasura apply migrate --dir bd-mart/migrations
```

### 6. Run the Backend Server

```bash
# Development mode with auto-reload
npm run dev

# Production mode
npm start
```

The server will run on `http://localhost:5000`

### 7. Verify Installation

```bash
# Health check
curl http://localhost:5000/health

# Expected response:
{
  "status": "success",
  "message": "BD_MART API is running",
  "version": "1.0.0"
}
```

---

## 🌐 API Documentation

### Base URL: `http://localhost:5000/api/v1/`

### Authentication

Most protected routes require a JWT token in the `Authorization` header:

```
Authorization: Bearer <your_jwt_token>
```

### Endpoints

#### **Authentication** (`/auth`)

| Method | Endpoint | Description | Auth |
|---|---|---|---|
| `POST` | `/auth/register` | Register new user | Public |
| `POST` | `/auth/login` | Login user | Public |
| `GET` | `/auth/me` | Get current user profile | Private |

#### **Products** (`/products`)

| Method | Endpoint | Description | Auth |
|---|---|---|---|
| `GET` | `/products` | List all products | Public |
| `GET` | `/products/:id` | Get single product | Public |
| `POST` | `/products` | Create product | Seller (Private) |
| `PATCH` | `/products/:id` | Update product | Seller/Admin (Private) |
| `DELETE` | `/products/:id` | Delete product | Seller/Admin (Private) |

**Query Parameters for GET /products:**
- `category` - Filter by category (clothing, electronics, food, etc.)
- `minPrice` / `maxPrice` - Price range filter
- `search` - Search in name and description
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 10)

#### **Cart** (`/cart`)

| Method | Endpoint | Description | Auth |
|---|---|---|---|
| `GET` | `/cart` | Get user's cart | Private |
| `POST` | `/cart` | Add item to cart | Private |
| `PATCH` | `/cart/:productId` | Update cart item quantity | Private |
| `DELETE` | `/cart/:productId` | Remove item from cart | Private |

#### **Orders** (`/orders`)

| Method | Endpoint | Description | Auth |
|---|---|---|---|
| `POST` | `/orders` | Create order from cart | Private |
| `GET` | `/orders` | Get user's order history | Private |
| `GET` | `/orders/:id` | Get single order details | Private |

#### **Payments** (`/payments`)

| Method | Endpoint | Description | Auth |
|---|---|---|---|
| `POST` | `/payments/intent` | Create Stripe payment intent | Private |
| `POST` | `/payments/webhook` | Stripe webhook receiver | Public |
| `GET` | `/payments/history` | Get payment history | Private |

#### **Delivery** (`/delivery`)

| Method | Endpoint | Description | Auth |
|---|---|---|---|
| `GET` | `/delivery/partners-near` | Find nearby delivery partners | Private |
| `POST` | `/delivery/location` | Update delivery partner location | Partner (Private) |
| `POST` | `/delivery/orders` | Create delivery order | Private |
| `GET` | `/delivery/orders/:id` | Get delivery order status | Private |

---

## 🗄️ Database Schema Overview

### Core Tables

| **Table** | **Key Fields** | **Description** |
|---|---|---|
| `users` | id, name, email, password, role, created_at | All platform users (customers, sellers, delivery partners, admins) |
| `products` | id, name, price, seller_id, stock, location, is_active | Marketplace products with geo-location |
| `orders` | id, user_id, order_total, status, payment_status, created_at | Customer orders |
| `order_items` | id, order_id, product_id, quantity, price | Order line items |
| `carts` | id, user_id, items, total_amount | User shopping carts |
| `delivery_partners` | id, user_id, full_name, phone, vehicle_type, location, status | Delivery personnel |

### Relationships

```
(users) 1:n (orders)    ← Customer places many orders
(users) 1:n (products)  ← Seller lists many products
(users) 1:1 (carts)     ← User has one cart
(users) 1:1 (delivery_partners) ← Delivery partner profile
(order) 1:n (order_items) ← One order has many items
(product) 1:n (order_items) ← Product appears in many orders
```

### Geo-spatial Queries

Products and delivery partners support location-based queries:

```sql
-- Find products within 5km of a location
SELECT * FROM products
WHERE location <@ earth_box(ll_to_geometry('(37.7749, -122.4194)'::text, 4326), '5km');

-- Find delivery partners near user
SELECT * FROM delivery_partners
WHERE location <@ earth_box(
  ll_to_geometry(latitude || ',' || longitude::text, 4326),
  '2km'
);
```

---

## 🔐 Authentication System

### JWT Token Format

```json
{
  "id": "user_id_string",
  "role": "customer|seller|delivery_partner|admin",
  "iat": issued_at_timestamp,
  "exp": expiration_timestamp
}
```

### Login/Register Flow

1. **Register**: POST `/api/v1/auth/register` with name, email, password, optional role
2. **Login**: POST `/api/v1/auth/login` with email, password
3. **Receive**: JWT token in response
4. **Use**: Include token in `Authorization: Bearer <token>` header
5. **Access**: Protected routes verify token and attach `req.user`

### Role-Based Access Control

| **Role** | **Permissions** |
|---|---|
| `customer` | Browse products, add to cart, place orders, view own orders |
| `seller` | Create/manage own products, view own orders, process orders |
| `delivery_partner` | Update location, accept deliveries, update delivery status |
| `admin` | Full system access, user management, order oversight |

---

## 💳 Payment Integration

### Stripe Payment Flow

1. **Create Payment Intent**: POST `/api/v1/payments/intent` with `{ amount, currency }`
2. **Receive**: `client_secret` to initiate Stripe Checkout
3. **Customer**: Completes payment at Stripe-hosted page
4. **Webhook**: Your server receives `payment_intent.succeeded`
5. **Update Order**: Mark order as paid and confirmed

### Ethiopian Payment Gateways

Integrate with local gateways:

| **Gateway** | **Method** | **Status** |
|---|---|---|
| **Telebirr** | API integration | 🟡 Planned |
| **CBE Birr** | API integration | 🟡 Planned |
| **M-Birr** | API integration | 🟡 Planned |
| **Stripe** | International cards | ✅ Ready |

**Configuration**: Add to `.env`:
```env
ETHIOPAY_MERCHANT_ID=your_merchant_id
ETHIOPAY_PRIVATE_KEY=your_private_key
```

---

## 📍 Location & Tracking

### Google Maps Integration

1. **Get API Key**: Google Cloud Console → Maps Static API / Maps JavaScript API
2. **Configure**: Add `GOOGLE_MAPS_API_KEY` to `.env`
3. **Usage**: Frontend uses Maps JavaScript API for:
   - Product location display
   - Delivery partner tracking
   - Route visualization

### Distance Calculation (Node.js)

```javascript
const geolib = require('geolib');

// Calculate distance in meters between two points
const distance = geolib.getDistance(
  { latitude: 11.59, longitude: 37.06 },   // Bahir Dar center
  { latitude: 11.61, longitude: 37.10 }   // User location
);
// distance is in meters
```

### Nearby Delivery Partners Algorithm

```javascript
// In delivery route handler
const partners = await DeliveryPartner.find({
  status: 'available',
  location: {
    $near: {
      $maxDistance: 5000, // 5km radius
      $geometry: {
        type: 'Point',
        coordinates: [longitude, latitude]
      }
    }
  }
}).limit(5);
```

---

## 📱 Frontend Integration Guide

### Sample API Call (Fetch)

```javascript
// Get products with filtering
async function fetchProducts(filters = {}) {
  const params = new URLSearchParams({
    page: filters.page || 1,
    limit: filters.limit || 10,
    ...filters.category && { category: filters.category },
    ...filters.search && { search: filters.search }
  });
  
  const response = await fetch(`/api/v1/products?${params}`);
  return response.json();
}

// Create order
async function createOrder(orderData) {
  const response = await fetch('/api/v1/orders', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${userToken}`
    },
    body: JSON.stringify(orderData)
  });
  return response.json();
}
```

### Response Format (Consistent)

All API responses follow this structure:

```json
// Success
{
  "status": "success",
  "message": "Optional success message",
  "data": { ... },      // Response data
  "meta": { ... }       // Pagination, counts, etc.
}

// Error
{
  "status": "error",
  "message": "Error description",
  "error": { ... }      // Detailed error (development only)
}
```

---

## 🧪 Testing

### Run Tests

```bash
# Run all tests
npm test

# Run with coverage
npm test -- --coverage
```

### Postman Collection

Import the included `BD_MART_API.postman_collection.json` for easy testing.

### Test Coverage Areas

- Authentication (register, login, token validation)
- Product CRUD operations
- Cart flow (add, update, remove, checkout)
- Order creation and status tracking
- Payment intent creation
- Delivery partner location updates

---

## 📦 Deployment

### Docker Deployment

```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY . .

EXPOSE 5000

CMD ["npm", "start"]
```

```bash
# Build and run
docker build -t bd-mart-backend .
docker run -d -p 5000:5000 --env-file .env bd-mart-backend
```

### Production Environment Variables

```env
NODE_ENV=production
PORT=5000
# ... other vars
```

### Recommended Hosting Platforms

| **Platform** | **Suitability** | **Notes** |
|---|---|---|
| **Render** | ⭐⭐⭐⭐⭐ | Free tier, easy Node.js deployment |
| **Railway** | ⭐⭐⭐⭐⭐ | Good developer experience |
| **Fly.io** | ⭐⭐⭐⭐ | Close to Ethiopia, good performance |
| **Heroku** | ⭐⭐⭐ | Deprecated free tier |
| **Vercel** | ⭐⭐ | Frontend-only, backend limited |
| **Self-hosted** | ⭐⭐⭐⭐⭐ | Full control, best for local network |

---

## 🎯 Unique Features for Bahir Dar Market

### 1. **Local Payment Integration**
- Support for Telebirr, CBE Birr, M-Birr QR codes
- Cash on delivery option
- Ethiopian Birr (ETB) currency handling

### 2. **Geolocation-Based Discovery**
- Products tagged with Bahir Dar area locations
- "Near me" feature for local products
- Distance-based pricing for delivery

### 3. **Delivery Partner Network**
- University students, local transporters
- Real-time location sharing
- Rating system based on Bahir Dar routes

### 4. **Cultural & Language Support**
- Amharic language support options
- Local product categories (fruits, vegetables, crafts, livestock)
- Ethiopian holiday/schedule awareness

### 5. **Farmer/Seller Empowerment**
- Simple product listing without technical skills
- Inventory management for small sellers
- Sales analytics dashboard

---

## 📊 Project Report Sections

### 1. **Introduction**
- Problem statement: Lack of digital marketplace for Bahir Dar
- Objectives: Build platform connecting buyers/sellers locally
- Scope: Web + mobile compatible, cart, payment, delivery

### 2. **System Analysis**
- Current state: Traditional market trading
- Proposed system: Digital marketplace
- Requirements: Functional & non-functional

### 3. **System Design**
- Architecture diagram (include the one from this README)
- Database ER diagram
- API endpoints design
- Class diagrams

### 4. **Implementation**
- Technology choices justification
- Code snippets of key features
- Challenges faced & solutions
- Hasura integration explanation

### 5. **Testing & Results**
- API test results
- Performance benchmarks
- Security considerations
- User acceptance (if applicable)

### 6. **Conclusion & Future Work**
- Achievements
- Limitations
- Recommended enhancements
- Future features: wishlist, reviews, notifications, admin dashboard

### 7. **Scalability Considerations (1000+ Concurrent Users)**
#### Expected Load Patterns
| **Metric** | **Expected** | **Notes** |
|---|---|---|
| **Concurrent Users** | 500-1000+ | During peak market hours (evenings, weekends) |
| **API Requests/sec** | 100-200 req/s | Product browsing, cart updates |
| **Database Connections** | 20-30 max | Connection pooling recommended |
| **Storage Growth** | 5-10 GB/month | Product images, order records |

#### Scaling Strategy

##### 1. **Horizontal Scaling (Multiple Instances)**
- Deploy backend behind load balancer (Nginx, HAProxy, Cloud Load Balancer)
- Use session affinity sparingly (only for cart state)
- Stateless design allows easy scaling: "Any instance can handle any request"

```yaml
# Example Nginx load balancer config
upstream bd_mart_backend {
  server backend1:5000;
  server backend2:5000;
  server backend3:5000;
}

server {
  listen 80;
  location /api/ {
    proxy_pass http://bd_mart_backend;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
}
```

##### 2. **Database Optimization**
- **Connection Pooling**: Use `pgbouncer` or Hasura's built-in pooling
- **Read Replica**: Offload read queries (product listings) to replica
- **Indexing**: Critical for geo-spatial queries and filters
- **Pagination**: Always use `page` + `limit` parameters

```sql
-- Example: Paginated product query
SELECT * FROM products
WHERE is_active = true
ORDER BY created_at DESC
LIMIT 10 OFFSET 0;
```

##### 3. **Caching Strategy**
- **HTTP Cache**: CDN (Cloudflare, AWS CloudFront) for static assets
- **Response Cache**: Redis for frequently accessed data
  - Product lists (cache for 5-10 minutes)
  - User profile (cache for 15 minutes)
  - Nearby partners (cache for 1 minute)

```javascript
// Redis caching example
const redis = require('redis').createClient();
async function getProductsCached() {
  const cached = await redis.get('products:list');
  if (cached) return JSON.parse(cached);
  
  const products = await Product.find({ isActive: true });
  await redis.setex('products:list', 300, JSON.stringify(products)); // 5 min
  return products;
}
```

##### 4. **Rate Limiting & DDoS Protection**
- Already implemented: `express-rate-limit` (100 requests/15min)
- Add: `express-async-errors` for unhandled promise rejections
- Consider: Cloudflare, AWS Shield, or similar DDoS protection

##### 5. **Queue System for Heavy Operations**
- **Email/SMS notifications**: Move to background queue
- **Payment processing**: Already handled by Stripe webhooks
- **Geo calculations**: Optional caching

```javascript
// BullMQ or RabbitMQ example
const Queue = require('bullmq').Queue;
const notificationQueue = new Queue('notifications');

await notificationQueue.add(
  'order-updated',
  { orderId: orderId, userId: userId },
  { attempt: 3 }
);
```

#### **Performance Targets**
| **Operation** | **Target Response Time** |
|---|---|
| Product list fetch | < 200ms |
| Product detail fetch | < 100ms |
| Cart operations | < 100ms |
| Order creation | < 500ms |
| Payment intent creation | < 200ms |
```

### 8. **Security Considerations**
#### **Authentication Security**

##### 1. **JWT Token Handling**
| **Aspect** | **Implementation** | **Best Practice** |
|---|---|---|
| **Token Storage** | Frontend: `localStorage` OR `HttpOnly` cookies | **Never** store in plain JavaScript variables |
| **Token Transmission** | `Authorization: Bearer <token>` header | Always use HTTPS (TLS 1.2+) |
| **Token Expiry** | 1 day access token, 7 day refresh token | Short access tokens + rotating refresh tokens |
| **Token Revocation** | Blacklist on logout + Redis blocklist | Immediate invalidation on logout |

```javascript
// Secure cookie configuration
app.use(cors({
  origin: process.env.CORS_ORIGIN,
  credentials: true, // Required for cookies
  // httpOnly: true, // If using cookies instead of localStorage
}));

// JWT options with short expiry
const jwtOptions = {
  expiresIn: '1d',
  algorithm: ['HS256'], // Explicit algorithm
};
```

##### 2. **Password Security**
| **Aspect** | **Implementation** | **Standard** |
|---|---|---|
| **Hashing Algorithm** | bcrypt | ⭐ Industry standard |
| **Salt Rounds** | 12-14 rounds | Balanced security/performance |
| **Password Policy** | Min 8 chars, max 128 chars | Enforce complexity |
| **Password Reset** | Token-based with 1-hour expiry | Secure, time-limited |

```javascript
// Password hashing configuration
const bcryptSaltRounds = 12; // Recommended: 12
const password = 'user-provided-password';

bcrypt.hash(password, bcryptSaltRounds)
  .then(hash => {
    // Store hash in database
    // Never store plaintext passwords
  })
  .catch(err => console.error('Bcrypt error:', err));
```

##### 3. **Input Validation & sanitization**
| **Vector** | **Protection** | **Tool** |
|---|---|---|
| **SQL Injection** | Parameterized queries, ORM | Hasura/Prisma/Mongoose |
| **XSS (Cross-Site Scripting)** | Input sanitization, Content-Security-Policy | `xss-clean` middleware |
| **NoSQL Injection** | Schema validation, sanitization | `express-mongo-sanitize` |
| **Command Injection** | Input length limits, allowlists | Custom validation |

```javascript
// Express validation example
const { body, validationResult } = require('express-validator');

router.post(
  '/register',
  [
    body('email')
      .isEmail()
      .withMessage('Must be a valid email')
      .normalizeEmail(), // Remove whitespace
    body('password')
      .isLength({ min: 8, max: 128 })
      .matches(/[A-Z]/) // At least one uppercase
      .withMessage('Must contain uppercase letter'),
    body('name')
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage('Name must be 2-100 characters'),
  ],
  async (req, res) => {
    // F-validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    // Proceed with safe, validated data
  }
)
```

#### **Data Security**

##### 1. **Sensitive Data Protection**
| **Data Type** | **Protection Method** | **Example** |
|---|---|---|
| **Passwords** | bcrypt hashing (never plaintext) | `hash = bcrypt.hashSync(password, salt)` |
| **PII (Personal Identifiable Info)** | Encryption at rest | AES-256 for addresses, phones |
| **Payment Data** | Never store card details | Use Stripe/Clementine/Telebirr tokens only |
| **Location Data** | Geo-hashing, distance calc only | Store coordinates, not addresses initially |

```javascript
// Never log sensitive data
console.log('User login attempt:', req.body.email); // ❌ DON'T

// ✅ DO:
console.log('User login attempt: [REDACTED]');
```

##### 2. **Headers & HTTP Security**
```javascript
// Helmet.js automatically sets security headers
app.use(helmet());

// Additional security headers
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  next();
});
```

##### 3. **Rate Limiting & Brute Force Protection**
- Already implemented: 100 requests per 15 minutes globally
- Add: Authentication attempt limiting (5 attempts/15min per IP)
- Consider: Account lockout after 3 failed logins

```javascript
// Failed attempt tracking (simplified)
const failCounts = {};

function trackFailedAttempt(ip) {
  failCounts[ip] = (failCounts[ip] || 0) + 1;
  if (failCounts[ip] >= 5) {
    // Temporary block (in production: use Redis with TTL)
    console.log(`IP ${ip} blocked after 5 failed attempts`);
  }
}
```

#### **API Security**

##### 1. **Request Size Limits**
```javascript
// Already configured: 10kb JSON payload limit
app.use(express.json({ limit: '10kb' }));
// Increase for file uploads, but validate on server
```

##### 2. **CORS Configuration**
```javascript
// Development: Allow all origins
// Production: Restrict to specific origins
app.use(cors({
  origin: process.env.CORS_ORIGIN.split(','), // Specific domains
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
```

##### 3. **HTTPS Everywhere**
- **Require HTTPS**: All API communications must use TLS
- **HTTP Strict Transport Security (HSTS)**: Enforce HTTPS for 1 year
- **Certificate**: Let's Encrypt (free) or paid certificate for production

##### 4. **Error Handling Security**
```javascript
// ❌ DON'T do this (exposes stack traces to users):
res.status(500).json({ error: err.message, stack: err.stack });

// ✅ DO this (development vs production):
res.status(err.statusCode).json({
  status: err.status,
  message: err.message,
  // Only include stack in development
  ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
});
```

---

## 👥 Team & Contributors

| **Role** | **Name** | **Contact** |
|---|---|---|
| **Project Lead / Developer** | Bezma834 | github.com/Bezma834 |
| **Advisor** | [Professor Name] | [Email] |
| **Co-developers** | [Names if applicable] | [Contacts] |

---

## 📄 License

This project is licensed under the **MIT License** - see the LICENSE file for details.

**Free for educational and commercial use.** Give credit if using significant portions of this code.

---

## 🆘 Support & Contact

- **GitHub Issues**: Report bugs or request features
- **Email**: [your.email@bdu.edu.et]
- **Discussion**: GitHub Discussions for questions

---

## 🙏 Acknowledgements

- Hasura for excellent GraphQL infrastructure
- Node.js community for excellent ecosystem
- Ethiopian tech community for inspiration
- Open source contributors for tools and libraries

---

*BD_MART - Digitizing the Bahir Dar Market for the Digital Economy* 🚀