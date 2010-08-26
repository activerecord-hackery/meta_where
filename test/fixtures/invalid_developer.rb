class InvalidDeveloper < ActiveRecord::Base
  set_table_name 'developers'
  has_many :notes, :as => :notable, :conditions => [:note.eq % 'GIPE']
end