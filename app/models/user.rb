class User
  include Mongoid::Document
  include Mongoid::Timestamps

  validates :email, presence: true
  validates :email, :email => true
  
  field :balance,           type: Integer, default: 5000
  field :image_path,        type: String, default: ""
  
  field :provider,          type: String
  field :uid,               type: String

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :confirmable,
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :trackable, :validatable, :omniauthable, :omniauth_providers => [:facebook]

  ## Database authenticatable
  field :first_name,         type: String, default: ""
  field :last_name,          type: String, default: ""
  field :username,           type: String, default: ""
  field :email,              type: String, default: ""
  field :encrypted_password, type: String, default: ""

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  ## Confirmable
  field :confirmation_token,   type: String
  field :confirmed_at,         type: Time
  field :confirmation_sent_at, type: Time
  field :unconfirmed_email,    type: String # Only if using reconfirmable

  ## Lockable
  #field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  #field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  #field :locked_at,       type: Time
  
  def self.from_omniauth(auth)
    puts "---------------------User#from_omniauth------------------------------"
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0,20]
      a = auth.info.name.split
      user.first_name = a[0]
      user.last_name = a[1...a.length].join(" ") if a.length > 1
      user.username = auth.info.name.downcase.gsub(" ","")
      user.save!
    end
  end
  
  def self.new_with_session(params, session)
    puts "---------------------User#new_with_session------------------------------"
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
    puts "---------------------User#new_with_session------------------------------END"
  end
  
end
