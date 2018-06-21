class SystemUsersController < ApplicationController

  before_action :authenticate_system_admin
  before_action :set_user, only: [:edit, :destroy, :update]

  def index
    @users = User.all
  end

  def create
    pass = Devise.friendly_token.first(8)
    @user = User.new(email: params[:email], password: pass, password_confirmation: pass)
    if @user.save
      @user.send_welcome_mail(current_user)
      redirect_to system_users_path, notice: "User was added successfully"
    else
      redirect_to system_users_path, alert: @user.errors.full_messages.first
    end
  end

  def update
    if @user.update(user_params)
      if params[:user].has_key?(:system_admin) && params[:user][:system_admin] == "1"
        @user.add_role :system_admin
      else
        @user.remove_role :system_admin
      end
      redirect_to system_users_path, notice: "User was updated successfully"
    else
      flash.now[:alert] = @user.errors.full_messages.first
      render "edit"
    end
  end

  def show
    redirect_to :edit_system_user
  end

  def destroy
    @user.destroy
    redirect_to system_users_path, notice: "User was deleted successfully"
  end

  private

    def user_params
      params[:user].permit(:email)
    end

    def set_user
      @user = User.find(params[:id])
      raise "Cannot edit self" if @user == current_user
    end

    def authenticate_system_admin
      authorize(current_user)
    end

end
