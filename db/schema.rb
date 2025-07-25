# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2025_07_07_223915) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "access_logs", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "data_record_id"
    t.string "action", limit: 50, null: false
    t.inet "ip_address"
    t.text "user_agent"
    t.boolean "success", default: true
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_access_logs_on_action"
    t.index ["created_at"], name: "index_access_logs_on_created_at"
    t.index ["data_record_id"], name: "index_access_logs_on_data_record_id"
    t.index ["user_id"], name: "index_access_logs_on_user_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "contact_person", limit: 255
    t.string "email", limit: 255
    t.string "phone", limit: 20
    t.text "address"
    t.boolean "is_active", default: true
    t.integer "total_orders_count", default: 0
    t.decimal "total_revenue_generated", precision: 12, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_companies_on_is_active"
    t.index ["name"], name: "index_companies_on_name"
  end

  create_table "data_permissions", force: :cascade do |t|
    t.bigint "data_record_id", null: false
    t.bigint "user_id", null: false
    t.string "permission_type", limit: 20, default: "read"
    t.bigint "granted_by_id"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["data_record_id", "user_id"], name: "index_data_permissions_on_data_record_id_and_user_id", unique: true
    t.index ["data_record_id"], name: "index_data_permissions_on_data_record_id"
    t.index ["granted_by_id"], name: "index_data_permissions_on_granted_by_id"
    t.index ["user_id"], name: "index_data_permissions_on_user_id"
    t.check_constraint "permission_type::text = ANY (ARRAY['read'::character varying::text, 'write'::character varying::text, 'admin'::character varying::text])", name: "data_permissions_permission_type_check"
  end

  create_table "data_records", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", limit: 255, null: false
    t.text "description"
    t.string "data_type", limit: 50, null: false
    t.string "file_path", limit: 500
    t.bigint "file_size"
    t.string "checksum", limit: 64
    t.boolean "is_encrypted", default: false
    t.string "access_level", limit: 20, default: "private"
    t.string "status", limit: 20, default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["data_type"], name: "index_data_records_on_data_type"
    t.index ["status"], name: "index_data_records_on_status"
    t.index ["user_id"], name: "index_data_records_on_user_id"
    t.check_constraint "access_level::text = ANY (ARRAY['public'::character varying::text, 'shared'::character varying::text, 'private'::character varying::text])", name: "data_records_access_level_check"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying::text, 'archived'::character varying::text, 'deleted'::character varying::text])", name: "data_records_status_check"
  end

  create_table "employees", force: :cascade do |t|
    t.string "first_name", limit: 100, null: false
    t.string "last_name", limit: 100, null: false
    t.string "email", limit: 255, null: false
    t.string "phone", limit: 20
    t.string "role", limit: 50
    t.boolean "is_active", default: true
    t.decimal "hourly_rate", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "contract_type"
    t.index ["email"], name: "index_employees_on_email", unique: true
    t.index ["is_active"], name: "index_employees_on_is_active"
  end

  create_table "equipment", force: :cascade do |t|
    t.string "equipment_type", limit: 50, null: false
    t.string "model", limit: 100
    t.string "serial_number", limit: 100
    t.string "status", limit: 20, default: "available"
    t.decimal "purchase_price", precision: 8, scale: 2
    t.date "purchase_date"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "maintenance_start_date"
    t.date "maintenance_end_date"
    t.index ["equipment_type"], name: "index_equipment_on_equipment_type"
    t.index ["serial_number"], name: "index_equipment_on_serial_number", unique: true
    t.index ["status"], name: "index_equipment_on_status"
    t.check_constraint "equipment_type::text = ANY (ARRAY['laptop'::character varying::text, 'video_processor'::character varying::text, 'cable'::character varying::text])", name: "equipment_type_check"
    t.check_constraint "status::text = ANY (ARRAY['available'::character varying::text, 'assigned'::character varying::text, 'maintenance'::character varying::text, 'damaged'::character varying::text, 'retired'::character varying::text])", name: "equipment_status_check"
  end

  create_table "expenses", force: :cascade do |t|
    t.bigint "order_id"
    t.string "expense_type", limit: 50, null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.date "expense_date", null: false
    t.text "description"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "recurring_expense_id"
    t.string "contractor_type", limit: 20
    t.decimal "hours_worked", precision: 5, scale: 2
    t.decimal "hourly_rate", precision: 8, scale: 2
    t.string "status", limit: 20, default: "approved", null: false
    t.bigint "approved_by_id"
    t.datetime "approved_at"
    t.index ["approved_by_id"], name: "index_expenses_on_approved_by_id"
    t.index ["contractor_type"], name: "index_expenses_on_contractor_type"
    t.index ["expense_date"], name: "index_expenses_on_expense_date"
    t.index ["expense_type"], name: "index_expenses_on_expense_type"
    t.index ["order_id"], name: "index_expenses_on_order_id"
    t.index ["recurring_expense_id"], name: "index_expenses_on_recurring_expense_id"
    t.index ["status"], name: "index_expenses_on_status"
    t.index ["user_id"], name: "index_expenses_on_user_id"
    t.check_constraint "(contractor_type::text = ANY (ARRAY['salary'::character varying, 'hourly'::character varying]::text[])) OR contractor_type IS NULL", name: "contractor_type_check"
    t.check_constraint "amount > 0::numeric", name: "positive_amount_check"
    t.check_constraint "contractor_type::text = 'hourly'::text AND hours_worked IS NOT NULL AND hourly_rate IS NOT NULL OR contractor_type::text <> 'hourly'::text OR contractor_type IS NULL", name: "hourly_contractor_fields_check"
    t.check_constraint "expense_type::text = ANY (ARRAY['labor'::character varying, 'transportation'::character varying, 'lunch'::character varying, 'others'::character varying]::text[])", name: "expense_type_check"
    t.check_constraint "hourly_rate IS NULL OR hourly_rate > 0::numeric", name: "positive_hourly_rate_check"
    t.check_constraint "hours_worked IS NULL OR hours_worked > 0::numeric", name: "positive_hours_check"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying]::text[])", name: "expense_status_check"
  end

  create_table "financial_settings", force: :cascade do |t|
    t.decimal "partner_1_percentage", precision: 5, scale: 2, default: "33.33", null: false
    t.decimal "partner_2_percentage", precision: 5, scale: 2, default: "33.33", null: false
    t.decimal "company_saving_percentage", precision: 5, scale: 2, default: "33.34", null: false
    t.string "partner_1_name", limit: 100, default: "Partner 1", null: false
    t.string "partner_2_name", limit: 100, default: "Partner 2", null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_financial_settings_on_is_active"
    t.check_constraint "(partner_1_percentage + partner_2_percentage + company_saving_percentage) = 100::numeric", name: "profit_sharing_percentage_check"
    t.check_constraint "partner_1_percentage > 0::numeric AND partner_2_percentage > 0::numeric AND company_saving_percentage > 0::numeric", name: "positive_percentages_check"
  end

  create_table "items", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", limit: 255, null: false
    t.text "description"
    t.string "category", limit: 100
    t.string "location", limit: 255
    t.integer "quantity", default: 1
    t.string "status", limit: 50, default: "active"
    t.datetime "disposed_at"
    t.text "disposal_reason"
    t.decimal "value", precision: 10, scale: 2
    t.string "barcode", limit: 100
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_items_on_category"
    t.index ["location"], name: "index_items_on_location"
    t.index ["status"], name: "index_items_on_status"
    t.index ["user_id"], name: "index_items_on_user_id"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying::text, 'disposed'::character varying::text, 'maintenance'::character varying::text, 'reserved'::character varying::text])", name: "items_status_check"
  end

  create_table "monthly_targets", force: :cascade do |t|
    t.integer "month", null: false
    t.integer "year", null: false
    t.decimal "gross_earnings_target", precision: 12, scale: 2, null: false
    t.decimal "estimated_fixed_expenses", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "estimated_variable_expenses", precision: 10, scale: 2, default: "0.0", null: false
    t.text "notes"
    t.bigint "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_monthly_targets_on_created_by_id"
    t.index ["year", "month"], name: "index_monthly_targets_on_year_and_month", unique: true
    t.check_constraint "estimated_fixed_expenses >= 0::numeric AND estimated_variable_expenses >= 0::numeric", name: "non_negative_expenses_check"
    t.check_constraint "gross_earnings_target > 0::numeric", name: "positive_target_check"
    t.check_constraint "month >= 1 AND month <= 12", name: "valid_month_check"
    t.check_constraint "year >= 2020 AND year <= 2100", name: "valid_year_check"
  end

  create_table "order_equipment_assignments", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "equipment_id", null: false
    t.datetime "assigned_at", null: false
    t.datetime "returned_at"
    t.string "assignment_status", limit: 20, default: "assigned"
    t.text "return_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["equipment_id"], name: "index_order_equipment_assignments_on_equipment_id"
    t.index ["order_id", "equipment_id"], name: "unique_order_equipment", unique: true
    t.index ["order_id"], name: "index_order_equipment_assignments_on_order_id"
    t.check_constraint "assignment_status::text = ANY (ARRAY['assigned'::character varying::text, 'returned'::character varying::text, 'damaged'::character varying::text, 'lost'::character varying::text])", name: "assignment_status_check"
  end

  create_table "order_screen_requirements", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "screen_inventory_id", null: false
    t.decimal "sqm_required", precision: 8, scale: 2, null: false
    t.datetime "reserved_at"
    t.datetime "released_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "dimensions_rows"
    t.integer "dimensions_columns"
    t.boolean "active", default: true, null: false
    t.index ["order_id", "screen_inventory_id"], name: "unique_order_screen", unique: true
    t.index ["order_id"], name: "index_order_screen_requirements_on_order_id"
    t.index ["screen_inventory_id"], name: "index_order_screen_requirements_on_screen_inventory_id"
    t.check_constraint "(dimensions_rows IS NULL OR dimensions_rows > 0) AND (dimensions_columns IS NULL OR dimensions_columns > 0)", name: "order_screen_requirements_positive_dimensions_check"
    t.check_constraint "sqm_required > 0::numeric", name: "positive_sqm_required_check"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "google_maps_link"
    t.string "location_name", limit: 255
    t.datetime "start_date", null: false
    t.datetime "end_date", null: false
    t.integer "duration_days", null: false
    t.bigint "installing_assignee_id", null: false
    t.bigint "disassemble_assignee_id", null: false
    t.bigint "third_party_provider_id"
    t.decimal "price_per_sqm", precision: 8, scale: 2, null: false
    t.decimal "total_amount", precision: 10, scale: 2
    t.string "payment_status", limit: 20, default: "not_received"
    t.string "order_status", limit: 20, default: "pending"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "order_id", limit: 50
    t.integer "laptops_needed", default: 1, null: false
    t.integer "video_processors_needed", default: 1, null: false
    t.integer "dimensions_rows"
    t.integer "dimensions_columns"
    t.decimal "payed", precision: 10, scale: 2, default: "0.0", null: false
    t.date "due_date"
    t.string "invoice_number", limit: 100
    t.string "payment_terms", limit: 50, default: "net_30"
    t.datetime "invoice_sent_at"
    t.datetime "last_reminder_sent_at"
    t.boolean "is_overdue", default: false, null: false
    t.index ["disassemble_assignee_id"], name: "index_orders_on_disassemble_assignee_id"
    t.index ["due_date"], name: "index_orders_on_due_date"
    t.index ["installing_assignee_id"], name: "index_orders_on_installing_assignee_id"
    t.index ["invoice_number"], name: "index_orders_on_invoice_number", unique: true
    t.index ["is_overdue"], name: "index_orders_on_is_overdue"
    t.index ["order_id"], name: "index_orders_on_order_id", unique: true
    t.index ["order_status"], name: "index_orders_on_order_status"
    t.index ["payment_status", "due_date"], name: "index_orders_on_payment_status_and_due_date"
    t.index ["payment_status"], name: "index_orders_on_payment_status"
    t.index ["payment_terms"], name: "index_orders_on_payment_terms"
    t.index ["start_date", "end_date"], name: "index_orders_on_start_date_and_end_date"
    t.index ["third_party_provider_id"], name: "index_orders_on_third_party_provider_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.check_constraint "laptops_needed > 0 AND video_processors_needed > 0", name: "orders_positive_equipment_counts_check"
    t.check_constraint "order_status::text = ANY (ARRAY['confirmed'::character varying, 'cancelled'::character varying]::text[])", name: "orders_status_check"
    t.check_constraint "payment_status::text = ANY (ARRAY['received'::character varying, 'not_received'::character varying, 'partial'::character varying]::text[])", name: "orders_payment_status_check"
    t.check_constraint "payment_terms::text = ANY (ARRAY['net_15'::character varying, 'net_30'::character varying, 'net_45'::character varying, 'net_60'::character varying, 'due_on_receipt'::character varying, 'advance_payment'::character varying]::text[])", name: "valid_payment_terms_check"
  end

  create_table "recurring_expenses", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "expense_type", limit: 50, null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "frequency", limit: 20, null: false
    t.date "start_date", null: false
    t.date "end_date"
    t.boolean "is_active", default: true, null: false
    t.text "description"
    t.bigint "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_recurring_expenses_on_created_by_id"
    t.index ["expense_type"], name: "index_recurring_expenses_on_expense_type"
    t.index ["frequency"], name: "index_recurring_expenses_on_frequency"
    t.index ["is_active"], name: "index_recurring_expenses_on_is_active"
    t.index ["start_date"], name: "index_recurring_expenses_on_start_date"
    t.check_constraint "amount > 0::numeric", name: "positive_recurring_amount_check"
    t.check_constraint "end_date IS NULL OR end_date >= start_date", name: "valid_date_range_check"
    t.check_constraint "expense_type::text = ANY (ARRAY['labor'::character varying, 'transportation'::character varying, 'lunch'::character varying, 'others'::character varying]::text[])", name: "recurring_expense_type_check"
    t.check_constraint "frequency::text = ANY (ARRAY['monthly'::character varying, 'weekly'::character varying, 'daily'::character varying]::text[])", name: "valid_frequency_check"
  end

  create_table "screen_inventory", force: :cascade do |t|
    t.string "screen_type", limit: 20, null: false
    t.string "pixel_pitch", limit: 10, null: false
    t.decimal "total_sqm_owned", precision: 8, scale: 2, null: false
    t.text "description"
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "maintenance_start_date"
    t.date "maintenance_end_date"
    t.index ["is_active"], name: "index_screen_inventory_on_is_active"
    t.index ["pixel_pitch"], name: "index_screen_inventory_on_pixel_pitch"
    t.index ["screen_type"], name: "index_screen_inventory_on_screen_type", unique: true
  end

  create_table "screen_maintenances", force: :cascade do |t|
    t.bigint "screen_inventory_id"
    t.decimal "sqm", precision: 8, scale: 2, null: false
    t.date "maintenance_start_date", null: false
    t.date "maintenance_end_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["screen_inventory_id"], name: "index_screen_maintenances_on_screen_inventory_id"
  end

  create_table "user_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "session_token", limit: 255, null: false
    t.inet "ip_address"
    t.text "user_agent"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_token"], name: "index_user_sessions_on_session_token", unique: true
    t.index ["user_id", "expires_at"], name: "index_user_sessions_on_user_id_and_expires_at"
    t.index ["user_id"], name: "index_user_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", limit: 255, null: false
    t.string "password_digest", limit: 255, null: false
    t.string "first_name", limit: 100, null: false
    t.string "last_name", limit: 100, null: false
    t.string "role", limit: 50, default: "user"
    t.boolean "is_active", default: true
    t.datetime "last_login_at"
    t.integer "failed_login_attempts", default: 0
    t.datetime "locked_until"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["is_active"], name: "index_users_on_is_active"
    t.check_constraint "role::text = ANY (ARRAY['admin'::character varying::text, 'user'::character varying::text, 'viewer'::character varying::text])", name: "users_role_check"
  end

  add_foreign_key "access_logs", "data_records", on_delete: :cascade
  add_foreign_key "access_logs", "users", on_delete: :nullify
  add_foreign_key "data_permissions", "data_records", on_delete: :cascade
  add_foreign_key "data_permissions", "users", column: "granted_by_id"
  add_foreign_key "data_permissions", "users", on_delete: :cascade
  add_foreign_key "data_records", "users", on_delete: :cascade
  add_foreign_key "expenses", "orders"
  add_foreign_key "expenses", "recurring_expenses"
  add_foreign_key "expenses", "users"
  add_foreign_key "expenses", "users", column: "approved_by_id"
  add_foreign_key "items", "users", on_delete: :cascade
  add_foreign_key "monthly_targets", "users", column: "created_by_id"
  add_foreign_key "order_equipment_assignments", "equipment"
  add_foreign_key "order_equipment_assignments", "orders"
  add_foreign_key "order_screen_requirements", "orders"
  add_foreign_key "order_screen_requirements", "screen_inventory"
  add_foreign_key "orders", "companies", column: "third_party_provider_id"
  add_foreign_key "orders", "employees", column: "disassemble_assignee_id", on_delete: :nullify
  add_foreign_key "orders", "employees", column: "installing_assignee_id", on_delete: :nullify
  add_foreign_key "orders", "users"
  add_foreign_key "recurring_expenses", "users", column: "created_by_id"
  add_foreign_key "screen_maintenances", "screen_inventory"
  add_foreign_key "user_sessions", "users", on_delete: :cascade
end
