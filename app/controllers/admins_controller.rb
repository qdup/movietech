class AdminsController < ApplicationController
  def index
    binding.pry
    @users = User.all
  end
end
