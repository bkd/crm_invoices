# Fat Free CRM
# Copyright (C) 2008-2009 by Michael Dvorkin
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#------------------------------------------------------------------------------

# == Schema Information
# Schema version: 21
#
# Table name: invoices
#
#  id              :integer(4)     not null, primary key
#  user_id         :integer(4)
#  assigned_to     :integer(4)
#  access          :string(8)
#  title           :string(64)  not null  default ""
#  description     :string(128  not null  default ""
#  amount          :float(10)  not null  default ""
#  vat             :float(10) 
#  additions       :float(10) 
#  total           :string(10) not null 
#  currency        :string
#  status          :string(64) not null  default ""
#  purchase_order  :string(20) 
#  uniqueid        :string(64) not null  default ""
#  invoice_address 
#  due_date        :datetime
#  sent_date       :datetime
#  deleted_at      :datetime
#  created_at      :datetime
#  updated_at      :datetime
#
class Invoice < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :assignee, :class_name => "User", :foreign_key => :assigned_to
  has_one     :account_invoice, :dependent => :destroy
  has_one     :account, :through => :account_invoice
 # has_many    :invoice_terms, :dependent => :destroy
  has_many    :tasks, :as => :asset, :dependent => :destroy, :order => 'created_at DESC'
  has_many    :activities, :as => :subject, :order => 'created_at DESC'
  has_many    :ledgeritems

  named_scope :only, lambda { |filters| { :conditions => [ "status IN (?)" + (filters.delete("other") ? " OR status IS NULL" : ""), filters ] } }
  named_scope :created_by, lambda { |user| { :conditions => "user_id = #{user.id}" } }
  named_scope :assigned_to, lambda { |user| { :conditions => "assigned_to = #{user.id}" } }
  
  year=Time.now.strftime("%Y")
  named_scope :thisyear, lambda { |invoice| {:conditions => ["created_at > '01/01/#{year}'"] }}
  named_scope :recent, lambda { |*args| {:conditions => ["due_date < ?", (args.first || 2.weeks.ago)] }}
  
  ##restrict the invoices to the current user
  named_scope :sent, lambda { |filters| { :conditions => [ "status = ? sent" ]} }
  simple_column_search :title, :description, :status, :total, :match => :middle, :escape => lambda { |query| query.gsub(/[^\w\s\-\.']/, "").strip }
  
  uses_user_permissions
  acts_as_commentable
  acts_as_paranoid
  
  validates_presence_of :title, :message => "^Please specify an invoice title."
  validates_presence_of :amount, :message => "^Please specify an amount for the invoice."
  validates_presence_of :account_invoice, :message => "^Please specify an account for the invoice."
  validates_presence_of :due_date, :message => "^Please specify a due date for the invoice."
  
  validate :users_for_shared_access
  
  before_save :update_total
 
  SORT_BY = {
    "title" => "invoices.title DESC",
    "description" => "invoices.description DESC",
    "date created" => "invoices.created_at DESC",
    "date updated" => "invoices.updated_at DESC"
  }

  # Added to work with the late run filter
  LATE_BY = {
    "1 week" => "#{1.week.ago}",
    "2 weeks" => "#{2.weeks.ago}",
    "1 month" => "#{4.weeks.ago}",
    "2 months" => "#{60.days.ago}",
    "3 months" => "#{90.days.ago}",
    "4 months" => "#{120.days.ago}",
    "5 months" => "#{150.days.ago}",
    "6 months" => "#{180.days.ago}"
  }

  # Default values provided through class methods.
  #----------------------------------------------------------------------------
  def self.per_page ;  20                         ; end
  def self.outline  ;  "long"                     ; end
  def self.sort_by  ;  "invoices.created_at DESC" ; end
  def self.late_by  ;  "30 days" ; end
  def self.title_position ;  "before"        ; end

  # Convert the curreny to a symbol, could be done elsewhere 
  #----------------------------------------------------------------------------
  def get_currency_symbol(currency)
    case currency
      when "dollar"   then "&#36;"
      when "sterling" then "&#163;"
      else "&#8364;"  # euro
    end
  end
   
  #----------------------------------------------------------------------------
   def full_name(format = nil)
    c = get_currency_symbol self.currency
    if format.nil? || format == "before"
      "(#{c}#{self.total}) #{self.title}"
    else
      "#{self.title} (#{c}#{self.total})"
    end
  end
  alias :name :full_name
  
  def create_ledgeritem(params)
    Ledgeritem.create(
      :type_id      => self.id,
      :type         => "Invoice",
      :recipient_id => self.account_invoice.account_id,
      :user_id      => self.user_id,
      :total_amount => self.amount,
      :tax_amount   => get_tax(self.amount, self.vat),
      :status       => self.status,
      :description  => self.description,
      :due_date     => self.due_date,
      :currency     => Setting.invoice_currencies(self.currency)
    )
  end
    
  def get_tax(amount,vat)
    tax_total = vat > 0 ? amount * (vat/100) : 0
  end

  # Update the invoice total with the tax after created or updated/edited, could be better coded, but copied and pasted from old application
  #----------------------------------------------------------------------------
  def update_total
    subtotal = self.amount + (!self.additions.blank? ? self.additions : 0)
    self.total = subtotal + get_tax(self.amount, self.vat)
  end
  
  # Backend handler for [Create New Invoice] form (see invoice/create).
  #----------------------------------------------------------------------------
  def save_with_account_and_permissions(params)
    account = Account.create_or_select_for(self, params[:account], params[:users])
    self.account_invoice = AccountInvoice.new(:account => account, :invoice => self) unless account.id.blank?
    #self.opportunities << Opportunity.find(params[:opportunity]) unless params[:opportunity].blank?
    self.save_with_permissions(params[:users])
  end

  # Backend handler for [Update Invoice] form (see invoice/update).
  #----------------------------------------------------------------------------
  def update_with_account_and_permissions(params)
    account = Account.create_or_select_for(self, params[:account], params[:users])
    self.account_invoice = AccountInvoice.new(:account => account, :invoice => self) unless account.id.blank?
    self.update_with_permissions(params[:invoice], params[:users])
  end

  # Class methods.  - should change this later but copied from Leads
  #----------------------------------------------------------------------------
  def self.create_for(model, account, opportunity, params)
    attributes = {
      :user_id     => params[:account][:user_id],
      :assigned_to => params[:account][:assigned_to],
      :access      => params[:access]
    }
    %w(title description).each do |name|
      attributes[name] = model.send(name.intern)
    end
    invoice = Invoice.new(attributes)
    # Save the invoice only if the account and the opportunity have no errors.
    if account.errors.empty?
      # Note: invoice.account = account doesn't seem to work here.
      invoice.account_invoice = AccountInvoice.new(:account => account, :invoice => invoice) unless account.id.blank?
      invoice.save_with_model_permissions(model)
    end
    invoice
  end

  private
  
  # Make sure at least one user has been selected if the invoice is being shared. 
  #----------------------------------------------------------------------------
  def users_for_shared_access
    errors.add(:access, "^Please specify users to share the invoice with.") if self[:access] == "Shared" && !self.permissions.any?
  end

end
