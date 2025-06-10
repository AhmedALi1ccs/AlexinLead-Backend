# db/seeds.rb
puts "Creating seed data..."

# Create admin user
admin = User.create!(
  email: 'admin@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Admin',
  last_name: 'User',
  role: 'admin',
  is_active: true
)

# Create regular user
user = User.create!(
  email: 'user@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Regular',
  last_name: 'User',
  role: 'user',
  is_active: true
)

puts "Created users:"
puts "- Admin: admin@example.com / password123"
puts "- User: user@example.com / password123"
puts "Seed data created successfully!"