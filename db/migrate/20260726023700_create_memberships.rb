class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships do |t|
      # The cascade lives in the database rather than in a `dependent: :destroy`
      # on the association: Membership is tenant-scoped, so an Active Record
      # cascade would query it - and deleting an account happens outside any
      # organization, where a tenant-scoped query raises NoTenantSet.
      t.references :user,
                   null: false,
                   index: false, # covered by the composite index below
                   foreign_key: { on_delete: :cascade }

      t.references :organization, null: false, foreign_key: { on_delete: :cascade }

      t.string :role, null: false

      t.timestamps

      # One membership per user and organization, enforced where it cannot race
      # with a concurrent request. Doubles as the lookup index for user_id.
      t.index %i[user_id organization_id], unique: true
    end
  end
end
