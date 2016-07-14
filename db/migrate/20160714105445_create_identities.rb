class CreateIdentities < ActiveRecord::Migration[5.0]
  def change
    create_table :identities do |t|
      t.references :user, foreign_key: true
      t.string :uid
      t.string :provider
      t.string :token

      t.timestamps
    end
  end
end
