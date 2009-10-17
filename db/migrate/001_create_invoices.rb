class CreateInvoices < ActiveRecord::Migration
  def self.up
    create_table :invoices, :force => true do |t|
      t.references  :user
      t.integer     :assigned_to
      t.string      :access,        :limit => 8, :default => "Private"
      t.string      :title,         :limit => 64, :null => false, :default => ""
      t.string      :description,   :limit => 128, :null => false, :default => ""
      t.float       :amount,        :limit => 10, :null => false
      t.float       :vat,           :limit => 10
      t.float       :additions,     :limit => 10
      t.float       :total,         :limit => 10, :null => false
      t.string      :currency,      :limit => 10, :null => false
      t.string      :status,        :limit => 64, :null => false, :default => ""
      t.string      :purchase_order
      t.string      :uniqueid,      :limit => 64, :null => false, :default => ""
      t.string      :invoice_address 
      t.date        :due_date
      t.date        :sent_date
      t.datetime    :deleted_at
      t.timestamps
    end

    add_index :invoices, [:deleted_at ], :unique => true
    add_index :invoices, [:assigned_to, :title, :description]
  end

  def self.down
    drop_table :invoices
  end
end
