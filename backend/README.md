# Rails API Backend

Ruby on Rails API backend for the shopping cart application.

## Setup

1. **Install dependencies**:
   ```bash
   bundle install
   ```

2. **Set up the database**:
   ```bash
   rails db:migrate
   rails db:seed
   ```

3. **Start the server**:
   ```bash
   rails server
   ```

The API will be available at `http://localhost:3000`

## Database

- **Database**: SQLite (development)
- **Migrations**: Run with `rails db:migrate`
- **Seeds**: Run with `rails db:seed` to populate sample data

## API Documentation

### Authentication

All endpoints except `/api/auth/*` and `/api/products` require authentication via JWT token in the Authorization header:

```
Authorization: Bearer <token>
```

### Endpoints

#### Authentication

- `POST /api/auth/login`
  - Body: `{ "email": "user@example.com", "password": "password123" }`
  - Returns: `{ "token": "...", "user": { "id": 1, "email": "..." } }`

- `POST /api/auth/signup`
  - Body: `{ "user": { "email": "user@example.com", "password": "password123", "password_confirmation": "password123" } }`
  - Returns: `{ "token": "...", "user": { "id": 1, "email": "..." } }`

#### Products

- `GET /api/products` - List all products
- `GET /api/products/:id` - Get product details

#### Cart (Authenticated)

- `GET /api/cart` - Get user's cart with items
- `POST /api/cart/items` - Add item to cart
  - Body: `{ "product_id": 1, "quantity": 2 }`
- `PATCH /api/cart/items/:id` - Update cart item quantity
  - Body: `{ "quantity": 3 }`
- `DELETE /api/cart/items/:id` - Remove item from cart

#### Orders (Authenticated)

- `GET /api/orders` - List user's orders
- `POST /api/orders` - Create order from cart

## Models

- **User**: Email, password (bcrypt)
- **Product**: Name, description, price, image_url, stock_quantity
- **Cart**: Belongs to user (one per user)
- **CartItem**: Cart, product, quantity
- **Order**: User, total_amount, status
- **OrderItem**: Order, product, quantity, price

## Configuration

- **CORS**: Configured in `config/initializers/cors.rb`
- **JWT Secret**: Uses Rails secret key base (set in production)
- **Password**: Minimum 6 characters
