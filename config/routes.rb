Rails.application.routes.draw do

  resources :projects, except: :index do

    resources :permissions, only: [:create, :update, :destroy]

    resources :zones, except: [:update] do
      resources :records, only: [:index], controller: 'zone_records'
      resources :changes, only: [:index, :show, :create], controller: 'zone_changes'
    end

    resources :import, only: [:index, :create], controller: 'zones_import' do
      post :process, to: :process_zone
      post :process_done
    end

    resources :export, only: [:index, :create], controller: 'zones_export' do
      post :process, to: :process_zone
      get :process_done
    end

  end

  # Allow only user editing but do not allow public registerations
  devise_for :users, path: "auth", skip: [:registrations], path_names: {
    sign_in: 'login',
    sign_out: 'logout'
  }
  as :user do
    get 'users/edit', to: 'devise/registrations#edit', as: 'edit_user_registration'
    put 'users/:id', to: 'devise/registrations#update', as: 'user_registration'
    delete 'users/:id', to: 'devise/registrations#destroy'

    # Required for the redirect after editing the user account.
    get 'users/:id', to: redirect('/'), as: 'signed_in_root'

    # Just for convenience
    get 'users', to: redirect('/')
  end

  root to: "projects#index"

end
