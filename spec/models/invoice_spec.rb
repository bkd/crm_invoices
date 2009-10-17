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

    
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Invoice do

  before(:each) do
    login
  end

  describe "Invoice/Create" do
    it "should create a new invoice instance given valid attributes" do
      @account = Factory(:account)
      invoice = Factory(:invoice, :account=>@account,:title => "Invoice title")
      invoice.should be_valid
    end
  
    it "should have a currency" do
      @account = Factory(:account)
      invoice = Factory(:invoice, :account=>@account)
      invoice.currency.should_not be_nil
    end
    
    it "should have a numeric total" do
      @account = Factory(:account)
      invoice = Factory(:invoice, :account=>@account)
      invoice.total.should be_kind_of(Numeric)
    end
  end

  describe "Invoice/Update" do
    it "should update invoice title" do
      @account = Factory(:account)
      invoice = Factory(:invoice, :account=>@account)
      invoice.update_attributes({ :title => "Invoice changed"})
      invoice.title.should == "Invoice changed"
    end

    it "should update invoice total" do
      @account = Factory(:account)
      invoice = Factory(:invoice, :account=>@account)
      invoice.update_attributes({ :amount => 1000, :vat=>17.5})
      invoice.total.should == 1175
    end

    it "should update invoice currency" do
      @account = Factory(:account)
      invoice = Factory(:invoice, :account=>@account,:currency => "Sterling")
      invoice.update_attributes({ :currency=> "Dollar" })
      invoice.currency.should == "Dollar"
    end

    it "should reassign the invoice to another person" do
      him = Factory(:user)
      her = Factory(:user)
      @account = Factory(:account)
      invoice = Factory(:invoice, :account=>@account,:assigned_to => him.id)
      invoice.update_attributes( { :assigned_to => her.id } )
      invoice.assigned_to.should == her.id
      invoice.assignee.should == her
    end

    it "should reassign the invoice from another person to myself" do
      him = Factory(:user)
      @account = Factory(:account)
      invoice = Factory(:invoice, :account=>@account,:assigned_to => him.id)
      invoice.update_attributes( { :assigned_to => "" } )
      invoice.assigned_to.should == nil
      invoice.assignee.should == nil
    end
  end




end
