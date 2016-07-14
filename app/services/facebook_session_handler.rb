require 'logger'

FacebookSessionHandlerError = Class.new(StandardError)

class FacebookSessionHandler

  PROVIDER = "facebook"

  FIELDS = "id,first_name,last_name,gender,email,birthday,link"

  attr_accessor :auth, :token

  def initialize(access_token)
    @token    = access_token
    @auth     = Koala::Facebook::API.new(token).get_object("me?fields=#{FIELDS}", api_version: "v2.0")
  end

  def find
    user = find_by_uid_and_provider || find_by_email

    if user
      # We refresh token for every login
      login_email = email || "#{uid}@facebook.com"
      identity = user.identities.find_or_initialize_by(provider: provider, uid: uid)
      user.update(email: login_email)
      identity.update(token: token)
      user
    else
      nil
    end
  end

  def create
    # Initialize user
    user = User.new(user_options)

    # Services like facebook does not return email via oauth sometimes
    # In this case, we generate temporary email and force user to fill it later
    if user.email.blank?
      user.email = "#{uid}@facebook.com"
    end

    begin
      user.save! && user.identities.create(identity_options)
    rescue ActiveRecord::RecordInvalid => e
      log.error "(OAuth) Email #{e.record.errors[:email]}."
      return nil, e.record.errors
    end

    log.info "(OAuth) Creating user #{email} from login with uid => #{uid}"

    user
  end

  private

  def find_by_email
    User.find_by(email: [email,"#{uid}@facebook.com"])
  end

  def find_by_uid_and_provider
    Identity.find_by(provider: provider, uid: uid).try(:user)
  end

  def user_options
    {
      email:        email,
      gender:       gender,
      birthdate:    birthday,
      image_url:    image_url,
      last_name:    last_name,
      first_name:   first_name,
      facebook_url: facebook_url,
    }
  end
  def identity_options
    {
      provider:     provider,
      uid:          uid,
      token:        token
    }
  end

  def uid
    auth['id'].to_s
  end

  def provider
    PROVIDER
  end

  def first_name
    auth['first_name']
  end

  def last_name
    auth['last_name']
  end

  def email
    auth['email'].try(:downcase)
  end

  def gender
    auth['gender'].nil? ? 0 : (auth['gender'].downcase == "male" ? 1 : 2)
  end

  def birthday
    if auth['birthday']
      b = auth['birthday'].split("/")
      DateTime.new(b[2].to_i,b[0].to_i,b[1].to_i)
    end
  end

  def facebook_url
    auth['link']
  end

  def image_url
    "https://graph.facebook.com/#{uid}/picture?width=1024"
  end

  def koala
    Koala::Facebook::API
  end

  def log
    Logger.new(STDOUT)
  end

end
