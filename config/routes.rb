# == Route Map
#
# Routes for application:
#                            Prefix Verb   URI Pattern                                     Controller#Action
#                  new_user_session GET    /users/sign_in(.:format)                        devise/sessions#new
#                      user_session POST   /users/sign_in(.:format)                        devise/sessions#create
#              destroy_user_session DELETE /users/sign_out(.:format)                       devise/sessions#destroy
#                 new_user_password GET    /users/password/new(.:format)                   devise/passwords#new
#                edit_user_password GET    /users/password/edit(.:format)                  devise/passwords#edit
#                     user_password PATCH  /users/password(.:format)                       devise/passwords#update
#                                   PUT    /users/password(.:format)                       devise/passwords#update
#                                   POST   /users/password(.:format)                       devise/passwords#create
#          cancel_user_registration GET    /users/cancel(.:format)                         devise/registrations#cancel
#             new_user_registration GET    /users/sign_up(.:format)                        devise/registrations#new
#            edit_user_registration GET    /users/edit(.:format)                           devise/registrations#edit
#                 user_registration PATCH  /users(.:format)                                devise/registrations#update
#                                   PUT    /users(.:format)                                devise/registrations#update
#                                   DELETE /users(.:format)                                devise/registrations#destroy
#                                   POST   /users(.:format)                                devise/registrations#create
#                rails_health_check GET    /up(.:format)                                   rails/health#show
#                       sidekiq_web        /sidekiq                                        Sidekiq::Web
#                          lookbook        /lookbook                                       Lookbook::Engine
#                            clicks GET    /clicks(.:format)                               clicks#index
#                                   POST   /clicks(.:format)                               clicks#create
#                     organizations GET    /organizations(.:format)                        organizations#index
#                                   POST   /organizations(.:format)                        organizations#create
#                  new_organization GET    /organizations/new(.:format)                    organizations#new
#                 organization_root GET    /org/:organization_id(.:format)                 dashboards#show
#        edit_organization_settings GET    /org/:organization_id/settings/edit(.:format)   organization_settings#edit
#             organization_settings PATCH  /org/:organization_id/settings(.:format)        organization_settings#update
#                                   PUT    /org/:organization_id/settings(.:format)        organization_settings#update
#          organization_memberships GET    /org/:organization_id/memberships(.:format)     memberships#index
#                                   POST   /org/:organization_id/memberships(.:format)     memberships#create
#           organization_membership PATCH  /org/:organization_id/memberships/:id(.:format) memberships#update
#                                   PUT    /org/:organization_id/memberships/:id(.:format) memberships#update
#                                   DELETE /org/:organization_id/memberships/:id(.:format) memberships#destroy
#                       webmanifest GET    /manifest.v1.webmanifest(.:format)              statics#manifest
#                             about GET    /about(.:format)                                about#index
#                              root GET    /                                               clicks#index
#  turbo_recede_historical_location GET    /recede_historical_location(.:format)           turbo/native/navigation#recede
#  turbo_resume_historical_location GET    /resume_historical_location(.:format)           turbo/native/navigation#resume
# turbo_refresh_historical_location GET    /refresh_historical_location(.:format)          turbo/native/navigation#refresh
#
# Routes for Lookbook::Engine:
#                Prefix Verb URI Pattern              Controller#Action
#         lookbook_home GET  /                        lookbook/application#index
#   lookbook_page_index GET  /pages(.:format)         lookbook/pages#index
#         lookbook_page GET  /pages/*path(.:format)   lookbook/pages#show
#     lookbook_previews GET  /previews(.:format)      lookbook/previews#index
#      lookbook_preview GET  /preview/*path(.:format) lookbook/previews#show
#      lookbook_inspect GET  /inspect/*path(.:format) lookbook/inspector#show
# lookbook_embed_lookup GET  /embed(.:format)         lookbook/embeds#lookup
#        lookbook_embed GET  /embed/*path(.:format)   lookbook/embeds#show
#                       GET  /*path(.:format)         lookbook/application#not_found

require 'sidekiq/web'
require 'lockup'

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  devise_for :users

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', :as => :rails_health_check

  mount Lockup::Engine, at: '/lockup' if Rails.env.production?
  # SECURITY: Mounted without authentication on purpose, so the public demo can
  # show it off. Sidekiq::Web is a separate Rack app, so neither Lockup nor any
  # ApplicationController before_action applies to it - anyone reaching this URL
  # can read job arguments and retry, kill or delete queues.
  #
  # Before using this template for anything real, restrict it, e.g.:
  #
  #   Sidekiq::Web.use Rack::Auth::Basic do |user, password|
  #     ActiveSupport::SecurityUtils.secure_compare(user, ENV.fetch('SIDEKIQ_USER')) &
  #       ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch('SIDEKIQ_PASSWORD'))
  #   end
  #
  # ...or simply mount it in development only.
  mount Sidekiq::Web => '/sidekiq'
  mount Lookbook::Engine, at: '/lookbook' if Rails.env.development?

  resources :clicks, only: %i[index create]

  # Which organization a request belongs to is part of the path, so the whole
  # tenant lives in the URL: no wildcard DNS in development, no cookie-domain
  # setup, and a link can be pasted between members without losing its context.
  # Everything below the scope goes through TenantScoped.
  resources :organizations, only: %i[index new create]

  scope 'org/:organization_id', as: :organization do
    get '/', to: 'dashboards#show', as: :root

    resource :settings, only: %i[edit update], controller: :organization_settings

    resources :memberships, only: %i[index create update destroy]
  end

  get '/manifest.v1.webmanifest', to: 'statics#manifest', as: :webmanifest
  get '/about', to: 'about#index', as: :about

  root to: 'clicks#index'
end
