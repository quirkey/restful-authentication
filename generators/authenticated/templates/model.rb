require 'digest/sha1'

class <%= class_name %> < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
<% if options[:aasm] -%>
  include Authorization::AasmRoles
<% elsif options[:stateful] -%>
  include Authorization::StatefulRoles<% end %>
<% unless options[:email] %>
  validates_presence_of     :login
  validates_length_of       :login,       :within => 3..40
  validates_uniqueness_of   :login
  validates_format_of       :login,       :with => Authentication.login_regex, :message => Authentication.bad_login_message<% end %>

  validates_presence_of     :email
  validates_length_of       :email,       :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,       :with => Authentication.email_regex, :message => Authentication.bad_email_message
  
  validates_format_of       :first_name,  :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_format_of       :last_name,   :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true

  validates_length_of       :first_name,  :maximum => 100, :allow_nil => true
  validates_length_of       :last_name,   :maximum => 100, :allow_nil => true
  

  <% if options[:include_activation] && !options[:stateful] %>before_create :make_activation_code <% end %>

  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible <% unless options[:email] %>:login,<% end %> :email, :first_name, :last_name, :password, :password_confirmation

<% if options[:include_activation] && !options[:stateful] %>
  # Activates the user in the database.
  def activate!
    @activated = true
    self.activated_at = Time.now.utc
    self.activation_code = nil
    save(false)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  def active?
    # the existence of an activation code means they have not activated yet
    activation_code.nil?
  end<% end %>

  # Authenticates a user by their <%= unique_auth_attr %> and unencrypted password.  Returns the user or nil.
  def self.authenticate(<%= unique_auth_attr %>, password)
    return nil if <%= unique_auth_attr %>.blank? || password.blank?
    u = <% if    options[:stateful]           %>find_in_state :first, :active, :conditions => {:<%= unique_auth_attr %> => <%= unique_auth_attr %>}<%
           elsif options[:include_activation] %>find :first, :conditions => ['<%= unique_auth_attr %> = ? and activated_at IS NOT NULL', <%= unique_auth_attr %>]<%
           else %>find_by_<%= unique_auth_attr %>(<%= unique_auth_attr %>)<% end %> # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

<% unless options[:email] %>
  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end<% end %>

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  protected
    
<% if options[:include_activation] -%>
    def make_activation_code
  <% if options[:stateful] -%>
      self.deleted_at = nil
  <% end -%>
      self.activation_code = self.class.make_token
    end
<% end %>

end
