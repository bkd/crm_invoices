ActionController::Routing::Routes.draw do |map|
  
   map.resources :invoices,      :has_many => :comments, :collection => { :search => :get, :auto_complete => :post, :options => :get, :laterun => :get, :redraw => :post, :redraw_late => :post }

end
