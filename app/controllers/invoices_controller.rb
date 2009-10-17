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

class InvoicesController < ApplicationController
  before_filter :require_user
  before_filter :get_data_for_sidebar, :only => :index 
  before_filter :set_current_tab, :only => [ :index, :show ]
  before_filter :auto_complete, :only => :auto_complete

  #added these before filters to keep DRY factor
  before_filter :find_users, :only => [:new, :update, :edit, :create]
  before_filter :find_record, :only => [:update, :edit, :show, :destroy]
  after_filter  :update_recently_viewed, :only => :show
  
  unloadable
  
  #default setup for Prawnto
  #prawnto :prawn => { :top_margin => 75 }
  
  def index
    @invoices = get_invoices(:page => params[:page])
     respond_to do |format|
      format.html
      format.js  
      format.xml  { render :xml => @invoices }
    end
  end

  # Moved the finding of the record here to improve DRY factor
  def find_record
    @invoice = Invoice.my(@current_user).find(params[:id]) 
  end

  # Moved the finding of the uer here to improve DRY factor
  def find_users
    @users = User.except(@current_user).all
  end

  # optional for PDF here to output the invoice via Prawn/prawnto
  def show
   #@accountid = AccountInvoice.find(@invoice.id)
   #@account = Account.find(@accountid)
   @current_tab = :invoices
   @comment = Comment.new
    respond_to do |format|
      format.html # show.html.erb
      format.pdf # <-- bombs without Prawn/prawnto
      format.xml  { render :xml => @invoice }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:html, :xml)
  end


  def new
    @invoice  = Invoice.new(:user => @current_user)
    @account  = Account.new(:user => @current_user)
    @accounts = Account.my(@current_user).all(:order => "name")
    # invoice stem is added to the unique counter for the current year, meaning users cant make up their own, check Settings.rb 
    @invoice.uniqueid="#{Setting.invoice_stem}#{Invoice.thisyear.size+1}"
    # assume that the default number numer of days for the invoice to be due to 30 days, could set this in a preference later
    @invoice.due_date=30.days.from_now.strftime("%m/%d/%Y") 
        
    if params[:related]
      model, id = params[:related].split("_")
      instance_variable_set("@#{model}", model.classify.constantize.my(@current_user).find(id))
    end
    
    respond_to do |format|
      format.js   # new.js.rjs
      format.xml  { render :xml => @invoice }
    end
  rescue ActiveRecord::RecordNotFound # Kicks in if related asset was not found.
    respond_to_related_not_found(model, :js) if model
  end


  def edit
    @account  = @invoice.account || Account.new(:user => @current_user)
    @accounts = Account.my(@current_user).all(:order => "name")
    if params[:previous] =~ /(\d+)\z/
      @previous = Invoice.my(@current_user).find($1)
    end
    respond_to do |format|
      format.js       
    end

  rescue ActiveRecord::RecordNotFound
    @previous ||= $1.to_i
    respond_to_not_found(:js) unless @invoice
  end

  
  def create
    @invoice = Invoice.new(params[:invoice])
    ##make sure that the invoice unique ID is set on creation, used the named_scope "thisyear" in Invoice.rb model , 
    ## TODO should store this in db and increment it, incase lots of deleted invoices lead to duplicate unique ids
    
    @invoice.uniqueid="#{Setting.invoice_stem}#{Invoice.thisyear.size+1}"
    respond_to do |format|
      if @invoice.save_with_account_and_permissions(params)
        
        #@invoice.create_ledgeritem(params) if @invoice.status == 'sent'
                  
        get_data_for_sidebar if called_from_index_page?
        @invoices = get_invoices if called_from_index_page?
        format.js   # create.js.rjs
        format.xml  { render :xml => @invoice, :status => :created, :location => @invoice }
      else
        @accounts = Account.my(@current_user).all(:order => "name")
        unless params[:account][:id].blank?
          @account = Account.find(params[:account][:id])
        else
          if request.referer =~ /\/accounts\/(.+)$/
            @account = Account.find($1) # related account
          else
            @account = Account.new(:user => @current_user)
          end
        end
        #@invoice.create_ledgeritem(params)
      
        format.js   # create.js.rjs
        format.xml  { render :xml => @invoice.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @invoice.update_with_account_and_permissions(params)
        get_data_for_sidebar if called_from_index_page?
        #@invoice.create_ledgeritem(params) if @invoice.status == 'sent' and @invoice_old_status == ('approved' || 'open')
        format.js
        format.xml  { head :ok }
      else
        @accounts = Account.my(@current_user).all(:order => "name")
        if @invoice.account
          @account = Account.find(@invoice.account.id)
        else
          @account = Account.new(:user => @current_user)
        end
        format.js
        format.xml  { render :xml => @invoice.errors, :status => :unprocessable_entity }
      end
    end
   rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:js, :xml)
  end

  def destroy
    @invoice.destroy if @invoice
    get_data_for_sidebar if called_from_index_page?
      respond_to do |format|
      format.html { respond_to_destroy(:html) }
      format.js   { respond_to_destroy(:ajax) }
      format.xml  { head :ok }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:html, :js, :xml)
  end

  def search
    @invoices = get_invoices(:query => params[:query], :page => 1)
    respond_to do |format|
      format.js   { render :action => :index }
      format.xml  { render :xml => @invoices.to_xml }
    end
  end

  def options
    unless params[:cancel] == "true"
      @per_page = @current_user.pref[:invoices_per_page] || Invoice.per_page
      @outline  = @current_user.pref[:invoices_outline]  || Invoice.outline
      @sort_by  = @current_user.pref[:invoices_sort_by]  || Invoice.sort_by
      @sort_by  = Invoice::SORT_BY.invert[@sort_by]
      @naming   = @current_user.pref[:invoices_naming]   || Invoice.title_position
    end
  end

  # intended to only use the filter while the laterun panel is still open, otherwise dont save the preferences, this way it doesnt affect the normal searches
  def laterun
    unless params[:cancel] == "true"
      @late_by = Invoice::LATE_BY[params[:late_by]] 
    end
  end
 
  def redraw
    @current_user.pref[:invoices_per_page] = params[:per_page] if params[:per_page]
    @current_user.pref[:invoices_outline]  = params[:outline]  if params[:outline]
    @current_user.pref[:invoices_sort_by] = Invoice::SORT_BY[params[:sort_by]] if params[:sort_by]
    @current_user.pref[:invoices_naming] = params[:naming] if params[:naming]
    @invoices = get_invoices(:page => 1) # Start one the first page.
    @late_by  =  Invoice::LATE_BY[params[:late_by]] 
    ## Added to allow laterun to work - could change this later
    @invoices = Invoice.sent.recent(@late_by).paginate({:page => current_page, :per_page => @current_user.pref[:invoices_per_page]}) if @late_by
    render :action => :index
  end

  def filter
    session[:filter_by_invoice_status] = params[:status]
    @invoices = get_invoices(:page => 1) # Start one the first page.
    render :action => :index
  end

  private
  def get_invoices(options = { :page => nil, :query => nil })
    self.current_page = options[:page] if options[:page]
    self.current_query = options[:query] if options[:query]
    records = {
      :user => @current_user,
      :order => @current_user.pref[:invoices_sort_by] || Invoice.sort_by
    }
    pages = {
      :page => current_page,
      :per_page => @current_user.pref[:invoices_per_page]
    }
    if !session[:filter_by_invoice_status].blank?
      filtered = session[:filter_by_invoice_status].split(",")
      current_query.blank? ? Invoice.my(records).only(filtered) : Invoice.my(records).only(filtered).search(current_query)
    else
      current_query.blank? ? Invoice.my(records) : Invoice.my(records).search(current_query)
    end.paginate(pages)
  end

  def respond_to_destroy(method)
    if method == :ajax
      if called_from_index_page?
        @invoices = get_invoices
        if @invoices.blank?
          @invoices = get_invoices(:page => current_page - 1) if current_page > 1
          render :action => :index and return
        end
      else
        self.current_page = 1
      end
      # At this point render destroy.js.rjs
    else
      self.current_page = 1
      flash[:notice] = "#{@invoice.full_name} has beed deleted."
      redirect_to(invoices_path)
    end
  end
  
   def get_data_for_sidebar
    @invoice_status_total = { :all => Invoice.my(@current_user).count}
    Setting.invoice_status.keys.each do |key|
      @invoice_status_total[key] = Invoice.my(@current_user).count(:conditions => [ "status=?", key.to_s ])
    end
  end
end
