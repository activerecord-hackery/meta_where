class InvalidCompany < ActiveRecord::Base
  set_table_name 'companies'
  has_many :developers, :conditions => {:name.matches => '%Miller'}
end