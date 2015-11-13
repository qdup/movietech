class User < ActiveRecord::Base
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
  before_create do |doc|
    doc.api_key = doc.generate_api_key
  end
  devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :trackable, :validatable


  def display_name
    "#{fname} #{lname}" || email.split('@').first
  end

  def show

  end

  def change
    change_column :users, :current_sign_in_ip,  :string
    change_column :users, :last_sign_in_ip,  :string
  end

private
  def generate_api_key
    loop do
      token = SecureRandom.base64.tr('+/=', 'Qrt')
      break token unless User.exists?(api_key: token).any?
    end
  end



end
