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
# Create initial screen inventory based on current stock
ScreenInventory.create!([
  { screen_type: 'P2.6B1', pixel_pitch: '2.6', total_sqm_owned: 26, available_sqm: 26 },
  { screen_type: 'P2.6B2', pixel_pitch: '2.6', total_sqm_owned: 50, available_sqm: 50 },
  { screen_type: 'P2.6B3', pixel_pitch: '2.6', total_sqm_owned: 50, available_sqm: 50 },
  { screen_type: 'P3.9B1', pixel_pitch: '3.9', total_sqm_owned: 24, available_sqm: 24 }
])

# Create initial equipment
Equipment.create!([
  { equipment_type: 'laptop', model: 'Dell Latitude 5520', serial_number: 'LAP001' },
  { equipment_type: 'laptop', model: 'Dell Latitude 5520', serial_number: 'LAP002' },
  { equipment_type: 'laptop', model: 'Dell Latitude 5520', serial_number: 'LAP003' },
  { equipment_type: 'laptop', model: 'Dell Latitude 5520', serial_number: 'LAP004' },
  { equipment_type: 'laptop', model: 'Dell Latitude 5520', serial_number: 'LAP005' },
  { equipment_type: 'video_processor', model: 'Novastar VX4S', serial_number: 'VID001' },
  { equipment_type: 'video_processor', model: 'Novastar VX4S', serial_number: 'VID002' },
  { equipment_type: 'video_processor', model: 'Novastar VX4S', serial_number: 'VID003' },
  { equipment_type: 'video_processor', model: 'Novastar VX4S', serial_number: 'VID004' },
  { equipment_type: 'video_processor', model: 'Novastar VX4S', serial_number: 'VID005' },
  { equipment_type: 'video_processor', model: 'Novastar VX4S', serial_number: 'VID006' },
  { equipment_type: 'video_processor', model: 'Novastar VX4S', serial_number: 'VID007' }
])

puts "Created users:"
puts "- Admin: admin@example.com / password123"
puts "- User: user@example.com / password123"
puts "Seed data created successfully!"
