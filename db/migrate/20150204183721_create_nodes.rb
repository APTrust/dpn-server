# Copyright (c) 2015 The Regents of the University of Michigan.
# All Rights Reserved.
# Licensed according to the terms of the Revised BSD License
# See LICENSE.md for details.


class CreateNodes < ActiveRecord::Migration
  def change
    create_table :nodes do |t|
      t.string :namespace, null: false
      t.string :name
      t.string :ssh_pubkey
      t.references :storage_region, null: false
      t.references :storage_type, null: false
      t.timestamps null: false
    end
    add_index :nodes, :namespace, unique: true
  end
end
