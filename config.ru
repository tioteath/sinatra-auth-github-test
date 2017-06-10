require "rubygems"
require "bundler/setup"

require 'rack/ssl'
require 'sinatra/auth/github'

module Dashboard
  class BadAuthentication < Sinatra::Base
    get '/unauthenticated' do
      status 403
      <<-EOS
      <h2>Access denied.</h2>
      <p>#{env['warden'].message}</p>
      EOS
    end
  end

  class DashboardApp < Sinatra::Base
    enable  :sessions
    enable  :raise_errors
    disable :show_exceptions
    enable :inline_templates

    set :github_options, {
      :scope     => 'user',
      :secret    => ENV['GITHUB_CLIENT_SECRET'] || 'test_client_secret',
      :client_id => ENV['GITHUB_CLIENT_ID']     || 'test_client_id'
    }
    register Sinatra::Auth::Github

    get '/' do
      if authenticated?
        erb :index
      else
        redirect '/login'
      end
    end

    get '/login' do
      authenticate!
      redirect '/'
    end

    get '/logout' do
      logout!
      erb :logged_out
    end
  end

  def self.app
    @app ||= Rack::Builder.new do
      run DashboardApp
    end
  end
end

use Rack::SSL if ENV['RAILS_ENV'] == "production"
run Dashboard.app

__END__

@@ layout
<html>
  <body>
    <h1>Simple App Example</h1>
    <ul>
      <li><a href='/'>Home</a></li>
      <li><a href='/profile'>View profile</a><% if !env['warden'].authenticated? %> (implicit sign in)<% end %></li>
    <% if authenticated? %>
      <li><a href='/logout'>Sign out</a></li>
    <% else %>
      <li><a href='/login'>Sign in</a> (explicit sign in)</li>
    <% end %>
    </ul>
    <hr />
    <%= yield %>
  </body>
</html>

@@ index
<h2>
  <img src='<%= env['warden'].user.avatar_url %>' />
  Welcome <%= github_user.name %>
</h2>
<a href="/logout">Log out</a>

@@ logged_out
<h2>Logged out</h2>
<a href="/login">Log in</a>
