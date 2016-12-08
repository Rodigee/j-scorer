class PasswordResetsController < ApplicationController
  before_action :find_user,        only: [:edit, :update]
  before_action :valid_user,       only: [:edit, :update]
  before_action :check_expiration, only: [:edit, :update]
  before_action :password_present, only: [:update]

  def new
  end

  def create
    @user = User.find_by(email: params[:password_reset][:email].downcase)
    if @user
      @user.create_reset_digest
      @user.send_password_reset_email
    end
    flash[:info] = 'If this address exists in the database, an email ' \
                   'has been sent with password reset instructions.'
    redirect_to root_url
  end

  def edit
  end

  def update
    if @user.update(user_params)
      log_in @user
      @user.update_attribute(:reset_digest, nil)
      flash[:success] = 'Password has been reset.'
      redirect_to root_url
    else
      render 'edit'
    end
  end

  private

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  # Before filters

  def find_user
    @user = User.find_by(email: params[:email])
  end

  def valid_user
    unless @user && @user.authenticated?(:reset, params[:id])
      redirect_to root_url
    end
  end

  def check_expiration
    if @user.password_reset_expired?
      flash[:danger] = 'Password reset has expired.'
      redirect_to forgot_url
    end
  end

  def password_present
    if params[:user][:password].empty?
      @user.errors.add(:password, "can't be empty")
      render 'edit'
    end
  end
end
