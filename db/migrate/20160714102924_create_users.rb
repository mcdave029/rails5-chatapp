class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string  :email
      t.integer :gender
      t.string  :birthdate
      t.string  :image_url
      t.string  :first_name
      t.string  :last_name
      t.string  :facebook_url

      t.timestamps null: false
    end

    add_index :users, :email, unique: true
  end
end
