# Copyright (c) 2015 The Regents of the University of Michigan.
# All Rights Reserved.
# Licensed according to the terms of the Revised BSD License
# See LICENSE.md for details.


class ReplicationAgreement < ActiveRecord::Base
  belongs_to :from_node, :foreign_key => "from_node_id", :class_name => "Node", touch: true
  belongs_to :to_node, :foreign_key => "to_node_id", :class_name => "Node", touch: true

  validates :from_node, presence: true
  validates :to_node, presence: true
end