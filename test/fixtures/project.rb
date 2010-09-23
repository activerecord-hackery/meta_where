class Project < ActiveRecord::Base
  has_and_belongs_to_many :developers
  has_many :notes, :as => :notable

  default_scope where(:name.not_eq => nil)
  scope :hours_lte_100, where(:estimated_hours.lte => 100)
end