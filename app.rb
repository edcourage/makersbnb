ENV["BNB"] ||= "dev"
#if not under rspec 'test' then set it to 'dev'

require 'sinatra/flash'
require 'sinatra/partial'
require_relative 'require_helper_app'

class MakersBnb < Sinatra::Base
  enable :sessions
  #the below 4 lines are convention
  register Sinatra::Flash
  register Sinatra::Partial
  set :partial_template_engine, :erb
  enable :partial_underscores


  get '/' do
    erb :home
  end

  get '/listings/new' do
    erb :new
  end

  post '/listings' do
    @user = Account.first(id: session[:user])
    @user.listing.create(
      name: params[:name],
      description: params[:description],
      price: params[:price],
      start_date: params[:start_date],
      end_date: params[:end_date]
    )
    redirect '/listings'
  end

  get '/listings' do
    @listings = Listing.all
    erb :listings
  end

  get '/bookings/new/:id' do
    @listing = Listing.get(params[:id])
    erb :booking_new
  end

  post '/bookings/new/:id' do
    @user = Account.first(id: session[:user])
    @listing = Listing.get(params[:id])
    @user.booking.create(
      listing_id: @listing.id,
      start_date: params[:start_date],
      end_date: params[:end_date]
    )
    redirect '/profile'
  end

  post '/booking/appoved' do
    Booking.confirm_booking(booking_id: params[:booking_id])
    redirect '/profile'

  end

  post '/profile' do
    # flash[:invalid_email] = nil

    @user = Account.create(
      email: params[:email],
      password: params[:password],
      first_name: params[:first_name],
      last_name: params[:last_name])

    if @user.id == nil
      flash[:invalid_email] = "Email Already In Use"
      redirect '/'
    else
      session[:user] = @user.id
      redirect '/profile'
    end
  end

  get '/profile' do
    @user = Account.first(id: session[:user])
    @listings = Listing.all(account_id: session[:user])
    @bookings = user_bookings_array(user_id: session[:user])
    @booking_requests_array = booking_requests_array(user_id: session[:user])
    erb :profile
  end

  get '/log-in' do
    erb :'log-in'
  end

  post '/log-in' do
    @user = Account.first(:email => params[:email])

    if @user.is_a?(Account)
      if @user.right_password?(email:params[:email],password:params[:password])
        session[:user] = @user.id
        redirect '/profile'
      else
        flash[:incorrect_password] = "Wrong password"
        redirect '/log-in'
      end
    else
      flash[:incorrect_email] = "Unknown email"
      redirect '/log-in'
    end
  end

  get '/log-out' do
    session[:user] = nil
    redirect '/'
  end

  run! if app_file == $0
end
