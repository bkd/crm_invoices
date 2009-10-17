class CreateAccountInvoices < ActiveRecord::Migration
  def self.up
    create_table :account_invoices, :force => true do |t|
      t.references :account
      t.references :invoice
      t.datetime   :deleted_at
      t.timestamps
    end
  end

  def self.down
    drop_table :account_invoices
  end
end
