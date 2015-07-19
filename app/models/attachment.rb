class Attachment < ActiveRecord::Base
  belongs_to :article

  has_attached_file :image, :styles => { :large => "1024x1024", :medium => "300x300>", :thumb => "100x100>" }

  validates_attachment_content_type :image, :content_type => /\Aimage\/.*\Z/
end
