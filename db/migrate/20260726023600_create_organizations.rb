class CreateOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false

      # The slug is what appears in /org/:slug/... URLs, so it has to be unique
      # at the database level and not just in a validation, which races.
      t.string :slug, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
