class CreateAttachments < ActiveRecord::Migration
  def change
    create_table :attachments do |t|
      t.integer :article_id, null: false
      t.string :caption
      t.attachment :image

      t.timestamps null: false
    end
  end
end
