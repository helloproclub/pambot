Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  
  root 'callback#root'
  
  post '/callback', to: 'callback#index'
end
