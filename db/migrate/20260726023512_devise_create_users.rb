class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  # Only the columns the enabled Devise modules actually use. Enabling
  # :confirmable, :trackable or :lockable later means adding their columns in a
  # migration of their own - see the module list in app/models/user.rb.
  def change
    create_table :users do |t|
      # database_authenticatable
      t.string :email, null: false, default: '', index: { unique: true }
      t.string :encrypted_password, null: false, default: ''

      # recoverable
      t.string :reset_password_token, index: { unique: true }
      t.datetime :reset_password_sent_at

      # rememberable
      t.datetime :remember_created_at

      t.timestamps null: false
    end
  end
end
