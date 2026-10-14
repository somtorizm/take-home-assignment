# Clear existing data (children before parents to satisfy foreign keys)
OrderItem.destroy_all
Order.destroy_all
CartItem.destroy_all
Cart.destroy_all
User.destroy_all
Product.destroy_all
Cart.destroy_all
CartItem.destroy_all
PromoCode.destroy_all

# Create test users
puts "Creating test users..."
user1 = User.create!(
  email: 'test@example.com',
  password: 'password123',
  password_confirmation: 'password123'
)

user2 = User.create!(
  email: 'demo@example.com',
  password: 'password123',
  password_confirmation: 'password123'
)

puts "Created users: #{user1.email}, #{user2.email}"

# Create products
puts "Creating products..."
products_data = [
  {
    name: 'Premium Dog Leash',
    description: 'Durable nylon leash with comfortable padded handle. Perfect for daily walks and training.',
    price: 24.99,
    image_url: 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?w=400',
    stock_quantity: 50
  },
  {
    name: 'Interactive Dog Toy',
    description: 'Engaging puzzle toy that keeps your dog mentally stimulated. Made from non-toxic materials.',
    price: 18.99,
    image_url: 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400',
    stock_quantity: 30
  },
  {
    name: 'Dog Food Bowl Set',
    description: 'Stainless steel bowls with non-slip base. Includes food and water bowls.',
    price: 29.99,
    image_url: 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400',
    stock_quantity: 40
  },
  {
    name: 'Comfortable Dog Bed',
    description: 'Orthopedic memory foam bed for large dogs. Machine washable cover included.',
    price: 79.99,
    image_url: 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400',
    stock_quantity: 20
  },
  {
    name: 'Dog Training Treats',
    description: 'All-natural training treats with no artificial preservatives. Great for positive reinforcement.',
    price: 12.99,
    image_url: 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400',
    stock_quantity: 100
  },
  {
    name: 'Waterproof Dog Jacket',
    description: 'Reflective waterproof jacket for rainy days. Available in multiple sizes.',
    price: 34.99,
    image_url: 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400',
    stock_quantity: 25
  },
  {
    name: 'Dog Grooming Brush',
    description: 'Self-cleaning brush that removes loose fur and reduces shedding. Suitable for all coat types.',
    price: 16.99,
    image_url: 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400',
    stock_quantity: 60
  },
  {
    name: 'Portable Dog Water Bottle',
    description: 'Collapsible water bottle with attached bowl. Perfect for hikes and long walks.',
    price: 14.99,
    image_url: 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400',
    stock_quantity: 45
  },
  {
    name: 'Dog Harness',
    description: 'No-pull harness with front and back attachment points. Adjustable for perfect fit.',
    price: 32.99,
    image_url: 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400',
    stock_quantity: 35
  },
  {
    name: 'Dog Puzzle Feeder',
    description: 'Slow feeder puzzle that makes mealtime fun and prevents fast eating.',
    price: 22.99,
    image_url: 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400',
    stock_quantity: 28
  },
  {
    name: 'Dog Waste Bags Dispenser',
    description: 'Eco-friendly biodegradable waste bags. Includes dispenser that attaches to leash.',
    price: 9.99,
    image_url: 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400',
    stock_quantity: 80
  },
  {
    name: 'Dog Cooling Mat',
    description: 'Self-cooling gel mat that helps keep your dog cool during hot weather. No refrigeration needed.',
    price: 39.99,
    image_url: 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400',
    stock_quantity: 15
  },
  {
    name: 'Dog Dental Chew Toys',
    description: 'Set of 3 dental chew toys that help clean teeth and reduce plaque buildup.',
    price: 19.99,
    image_url: 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400',
    stock_quantity: 42
  },
  {
    name: 'Dog First Aid Kit',
    description: 'Comprehensive first aid kit with bandages, antiseptic, and emergency supplies for dogs.',
    price: 27.99,
    image_url: 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400',
    stock_quantity: 18
  },
  {
    name: 'Dog Travel Carrier',
    description: 'Airline-approved soft-sided carrier with mesh windows for ventilation. Perfect for travel.',
    price: 64.99,
    image_url: 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400',
    stock_quantity: 12
  }
]

products = products_data.map do |product_data|
  Product.create!(product_data)
end

puts "Created #{products.count} products"

# Add some items to user1's cart
puts "Adding items to test user's cart..."
cart1 = user1.cart
CartItem.create!(cart: cart1, product: products[0], quantity: 2)
CartItem.create!(cart: cart1, product: products[2], quantity: 1)
CartItem.create!(cart: cart1, product: products[4], quantity: 3)

puts "Added items to #{user1.email}'s cart"

# Create a sample order for user1
puts "Creating sample order..."
order1 = Order.create!(
  user: user1,
  subtotal_amount: 98.98,
  total_amount: 98.98,
  status: 'completed'
)

OrderItem.create!(
  order: order1,
  product: products[1],
  quantity: 1,
  price: products[1].price
)

OrderItem.create!(
  order: order1,
  product: products[3],
  quantity: 1,
  price: products[3].price
)

puts "Created sample order for #{user1.email}"

# Promo codes to try. Marketing has no admin UI yet; these can also be managed
# from `rails console` (e.g. PromoCode.find_by_code('save5').update!(active: false)).
puts "Creating promo codes..."
[
  { code: 'WELCOME10', discount_type: 'percent', value: 10 },
  { code: 'SAVE5', discount_type: 'fixed', value: 5 },
  { code: 'HALFOFF', discount_type: 'percent', value: 50, expires_at: 30.days.from_now },
  { code: 'BIGSAVER', discount_type: 'fixed', value: 500 }, # larger than any cart: shows the cap at subtotal
  { code: 'EXPIRED', discount_type: 'percent', value: 20, expires_at: 1.day.ago },
  { code: 'DISABLED', discount_type: 'fixed', value: 10, active: false },
  { code: 'COMINGSOON', discount_type: 'percent', value: 15, starts_at: 7.days.from_now }
].each { |attrs| PromoCode.create!(attrs) }
puts "Created promo codes: #{PromoCode.pluck(:code).join(', ')}"

puts "\nSeeding complete!"
puts "Test users:"
puts "  - #{user1.email} / password123"
puts "  - #{user2.email} / password123"
puts "\nTotal products: #{Product.count}"
puts "Total users: #{User.count}"
