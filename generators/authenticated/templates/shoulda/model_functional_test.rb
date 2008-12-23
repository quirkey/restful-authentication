require 'test_helper'

class <%= model_controller_class_name %>ControllerTest < ActionController::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  include AuthenticatedTestHelper

  fixtures :<%= table_name %>
  
  context "<%= model_controller_class_name %> Controller" do
    context "creating <%= file_name %>" do
      context "with valid params" do
        setup { create_<%= file_name %> }

        should_change '<%= class_name %>.count', :by => 1
        should_respond_with :redirect
        
        should "send welcome email" do
          assert_sent_email {|email| email.to.include?(assigns(:<%= file_name %>).email) }
        end
  
        <% if options[:stateful] %>
        should "signup in pending state" do
          assigns(:<%= file_name %>).reload
          assert assigns(:<%= file_name %>).pending?
        end<% end %>
        <% if options[:include_activation] %>
          
        should "create activation code" do
          assigns(:<%= file_name %>).reload
          assert_not_nil assigns(:<%= file_name %>).activation_code
        end<% end %>
      end
      
      context "with invalid params" do
        setup { create_<%= file_name %>(:login => nil) }
        
        should_not_change '<%= class_name %>.count'
        should_respond_with :success
        
        should "not send welcome email" do
          assert_did_not_send_email
        end
        
        should "have errors on invalid params" do
          assert assigns(:<%= file_name %>).errors.on(:login)
        end
      end
    end
    <% if options[:include_activation] %>
    context "activating <%= file_name %>" do
      context "with inactive <%= file_name %> with key" do
        setup do
          get :activate, :activation_code => <%= table_name %>(:aaron).activation_code
        end
        
        should_redirect_to "'/<%= controller_routing_path %>/new'"

        should "set flash message" do
          assert_not_nil flash[:notice]
        end
        
        should "activate <%= file_name %>" do
          assert assigns(:<%= file_name %>).active?
          assert_equal <%= table_name %>(:aaron), <%= class_name %>.authenticate('aaron', 'monkey')
        end
      end
      
      context "with no key" do
        should "not activate <%= file_name %>" do
          begin
            get :activate
            assert_nil flash[:notice]
          rescue ActionController::RoutingError
            # in the event your routes deny this, we'll just bow out gracefully.
          end
        end      
      end
      
      context "with blank key" do
        should "not activate <%= file_name %>" do
          begin
            get :activate, :activation_code => ''
            assert_nil flash[:notice]
          rescue ActionController::RoutingError
            # in the event your routes deny this, we'll just bow out gracefully.
          end
        end      
      end
    end
    <% end %>
  end

  protected
    def create_<%= file_name %>(options = {})
      post :create, :<%= file_name %> => { :login => 'quire', :email => 'quire@example.com',
        :password => 'quire69', :password_confirmation => 'quire69' }.merge(options)
    end
end