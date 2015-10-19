class UsersController < ApplicationController
  before_filter :init_user, except: [:update_state]

  def show
    if @user == current_user
      return render 'show'

    elsif signed_in?

    end
  end

  private
  def init_user
    @user = User.find(params[:id]) if params[:id]
  end
end
