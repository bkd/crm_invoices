Factory.define :account_invoice do |a|
  a.account             { |a| a.association(:account) }
  a.invoice               { |a| a.association(:invoice) }
  a.deleted_at          nil
  a.updated_at          { Factory.next(:time) }
  a.created_at          { Factory.next(:time) }
end


#----------------------------------------------------------------------------
Factory.define :invoice do |i|
  i.user                { |a| a.association(:user) }
  i.assigned_to         nil
  i.access              "Private"
  i.description         { Faker::Lorem.sentence[0..63] }
  i.title               "Invoice title"
  i.amount              { rand(1000) }
  i.vat                 { rand(10) }
  i.currency            { %w(Sterling Dollar Euro).rand }
  i.status              { %w(open approved sent credit late demand legal paid).rand }
  i.invoice_address     { Factory.next(:address) }
  i.due_date            { Factory.next(:time) }
  i.sent_date           { Factory.next(:time) }
  i.deleted_at          nil
  i.updated_at          { Factory.next(:time) }
  i.created_at          { Factory.next(:time) }
end