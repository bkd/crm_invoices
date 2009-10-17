module AccountInvoiceAssociations
  
  def self.included(base)
    base.class_eval do
      has_many :account_invoices, :dependent => :destroy
      has_many :invoices, :through => :account_invoices, :uniq => true
    end
  end

end
