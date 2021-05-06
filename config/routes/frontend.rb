# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  scope module: 'frontend' do
    resources :sessions do
      collection do
        post 'login' => 'sessions#create'
        delete 'logout' => 'sessions#destroy'
      end
    end

    get 'me' => 'users#show'
    resources :users, only: %i[create show update destroy]

    resources :passwords do
      collection do
        put 'change_password' => 'passwords#update'
      end
    end

    resources :artists do
      member do
        get :tattoos
      end

      collection do
        get 'register' => 'artists#home'
        get ':city_state' => 'artists#city', as: :city_state
      end
    end

    resources :studios do
      member do
        get :tattoos
        get :artists
      end

      collection do
        get ':city_state' => 'studios#city', as: :city_state
      end
    end

    resources :locations, only: %i[index show]

    resources :favorites, only: %i[create] do
      collection do
        :delete
      end
    end

    resources :tattoos, only: %i[index show]
    resources :articles, only: %i[index show]
    resources :pages, only: %i[index show]
    resources :styles
    resources :categories, only: %i[index show]
    resources :landing_pages, only: %i[show index]
    resources :global_search_redirector, only: [:index]
    root to: 'landing_pages#home'
  end
end
