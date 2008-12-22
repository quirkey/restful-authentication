require 'test_helper'

class <%= controller_class_name %>ControllerTest < ActionController::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  include AuthenticatedTestHelper

  fixtures :<%= table_name %>
  
  context "<%= controller_class_name %> Controller" do
    context "logging in" do
      context "with bad login" do
        setup do
          post :create, :email => 'quentin@example.com', :password => 'Bas PSSS'
        end

        should_respond_with :success
        should_set_the_flash_to(/Couldn\'t log you in/i)

        should "not set <%= file_name %> in session" do
          assert !@controller.send(:current_<%= file_name %>)
        end

      end

      context "with good login" do
        setup do
          post :create, :email => 'quentin@example.com', :password => 'monkey'
        end

        should_respond_with :redirect

        should "set <%= file_name %> in session" do
          assert_equal <%= table_name %>(:quentin), @controller.send(:current_<%= file_name %>)
        end
      end

      context "with remember me" do
        setup do
          @request.cookies["auth_token"] = nil
          post :create, :email => 'quentin@example.com', :password => 'monkey', :remember_me => "1"
        end

        should "set auth token" do
          assert_not_nil @response.cookies["auth_token"]
        end
      end

      context "without remember me" do
        setup do
          @request.cookies["auth_token"] = nil
          post :create, :email => 'quentin@example.com', :password => 'monkey', :remember_me => "0"
        end

        should "not set auth token" do
          assert @response.cookies["auth_token"].blank?
        end
      end

      context "with cookie" do
        setup do
          <%= table_name %>(:quentin).remember_me
          @request.cookies["auth_token"] = cookie_for(:quentin)
          get :new
        end
        should "auto be logged in" do
          assert @controller.send(:logged_in?)
        end
      end

      context "with expired cookie" do
        setup do
          <%= table_name %>(:quentin).remember_me
          <%= table_name %>(:quentin).update_attribute :remember_token_expires_at, 5.minutes.ago
          @request.cookies["auth_token"] = cookie_for(:quentin)
          get :new
        end

        should "not auto log in" do
          assert !@controller.send(:logged_in?)
        end
      end

      context "with invalid cookie" do
        setup do
          <%= table_name %>(:quentin).remember_me
          @request.cookies["auth_token"] = auth_token('invalid_auth_token')
          get :new
        end
        should "not auto log in" do
          assert !@controller.send(:logged_in?)
        end
      end
    end

    context "logging out" do
      setup do
        login_as :quentin
        get :destroy
      end

      should_respond_with :redirect

      should "set <%= file_name %> to nil" do
        assert_nil session[:<%= file_name %>_id]
      end

      should "delete token" do
        assert @response.cookies["auth_token"].blank?
      end
    end
  end
  
  protected
    def auth_token(token)
      CGI::Cookie.new('name' => 'auth_token', 'value' => token)
    end
    
    def cookie_for(<%= file_name %>)
      auth_token <%= table_name %>(<%= file_name %>).remember_token
    end
end
