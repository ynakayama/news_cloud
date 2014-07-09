RailsApp::Application.routes.draw do
  root :to => 'blogs#index'
  resources :blogs,
    :only => [:index, :api] do
    collection do
      get :json
      get :jsonp
    end
  end
  resources :search,
    :only => [:create, :index]
end
