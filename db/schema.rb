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

ActiveRecord::Schema[7.1].define(version: 2025_06_02_140428) do
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
    t.check_constraint "permission_type::text = ANY (ARRAY['read'::character varying, 'write'::character varying, 'admin'::character varying]::text[])", name: "data_permissions_permission_type_check"
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
    t.check_constraint "access_level::text = ANY (ARRAY['public'::character varying, 'shared'::character varying, 'private'::character varying]::text[])", name: "data_records_access_level_check"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying, 'archived'::character varying, 'deleted'::character varying]::text[])", name: "data_records_status_check"
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
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying, 'disposed'::character varying, 'maintenance'::character varying, 'reserved'::character varying]::text[])", name: "items_status_check"
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
    t.check_constraint "role::text = ANY (ARRAY['admin'::character varying, 'user'::character varying, 'viewer'::character varying]::text[])", name: "users_role_check"
  end

  add_foreign_key "access_logs", "data_records", on_delete: :cascade
  add_foreign_key "access_logs", "users", on_delete: :nullify
  add_foreign_key "data_permissions", "data_records", on_delete: :cascade
  add_foreign_key "data_permissions", "users", column: "granted_by_id"
  add_foreign_key "data_permissions", "users", on_delete: :cascade
  add_foreign_key "data_records", "users", on_delete: :cascade
  add_foreign_key "items", "users", on_delete: :cascade
  add_foreign_key "user_sessions", "users", on_delete: :cascade
end
