class Note < ActiveRecord::Base
  belongs_to :notable, :polymorphic => true, :conditions => '1=1'
end