class FixityAlg < ActiveRecord::Base
  has_and_belongs_to_many :nodes, :join_table => "supported_fixity_algs", :uniq => true
end
