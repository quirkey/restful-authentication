require 'test_helper'

class <%= class_name %>Test < ActiveSupport::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead.
  # Then, you can remove it from this and the functional test.
  include AuthenticatedTestHelper
  fixtures :<%= table_name %>

  should_require_attributes :login, :email, :password, :password_confirmation
  should_require_unique_attributes :email

  context "creating a regular <%= file_name %>" do
    setup do
      @<%= file_name %> = create_<%= file_name %>
      @<%= file_name %>.reload
    end

    should "save <%= file_name %>" do
      assert !<%= file_name %>.new_record?, "#{<%= file_name %>.errors.full_messages.to_sentence}"
    end
  <% if options[:include_activation] %>
    should "initialize activation code" do
      assert_not_nil @<%= file_name %>.activation_code
    end<% end %><% if options[:stateful] %>
    should "start in pending state" do
      assert @<%= file_name %>.pending?
    end<% end %>

  end

  context "a <%= file_name %>" do
    setup do
      @<%= file_name %> = <%= table_name %>(:quentin)
    end

    context "authenticating" do

      should "authenticate <%= file_name %> by email" do
        assert_equal @<%= file_name %>, <%= class_name %>.authenticate(@<%= file_name %>.email, 'monkey')
      end

      should "authenticate by remote key" do
        assert_equal @<%= file_name %>, <%= class_name %>.authenticate_by_remote_key(@<%= file_name %>.remote_key)
      end

      should "reset password on update" do
        @<%= file_name %>.update_attributes(:password => 'new password', :password_confirmation => 'new password')
        assert_equal @<%= file_name %>, <%= class_name %>.authenticate('quentin@example.com', 'new password')
      end

      should "not rehash password if password is not included when updating" do
        @<%= file_name %>.update_attributes(:email => 'quentin2@example.com')
        assert_equal @<%= file_name %>, <%= class_name %>.authenticate('quentin2@example.com', 'monkey')
      end

    end    

    <% if options[:stateful] %>
    context "with states" do
      context "creating a without passwords" do
        setup do
          @<%= file_name %> = create_<%= file_name %>(:password => nil, :password_confirmation => nil)
        end
        
        should "be passive" do
          assert @<%= file_name %>.passive?
        end
        
        should "transition to pending on register!" do
          @<%= file_name %>.update_attributes(:password => 'new password', :password_confirmation => 'new password')
          @<%= file_name %>.register!
          assert @<%= file_name %>.pending?
        end
      end
    
      context "deleting <%= file_name %>" do
        setup do
          @<%= file_name %>.delete!
          @<%= file_name %>.reload
        end
        
        should "set deleted time" do
          assert_not_nil @<%= file_name %>.deleted_at
        end 
        
        should "transition to deleted state" do
          @<%= file_name %>.deleted?
        end 
      end

      context "a suspended <%= file_name %>" do
        setup do
          @<%= file_name %>.suspend!
        end

        should "be suspended" do
          assert @<%= file_name %>.suspended?
        end

        should "not authenticate" do
          assert_not_equal @<%= file_name %>, <%= class_name %>.authenticate(@<%= file_name %>.email, 'monkey')
        end

        should "unsuspend <%= file_name %> to active state" do
          @<%= file_name %>.unsuspend!
          assert @<%= file_name %>.active?
        end
        
        context "unsuspending a suspended <%= file_name %> without activation code and nil activated_at" do
          should "transition to pending" do
            <%= class_name %>.update_all :activation_code => nil, :activated_at => nil
            @<%= file_name %>.reload.unsuspend!
            assert @<%= file_name %>.pending?
          end
        end
        
        context "unsuspending a suspended <%= file_name %> with activation code and nil activated_at" do
          should "transition to pending" do
            <%= class_name %>.update_all :activation_code => 'foo-bar', :activated_at => nil
            @<%= file_name %>.reload.unsuspend!
            assert @<%= file_name %>.pending?
          end
        end        
      end

    <% end %>
    context "remembering" do
      context "remember_me" do        
        setup do
          @remembered = 2.weeks.from_now.utc
          @<%= file_name %>.remember_me
        end
        
        should "set remember token" do
          assert_not_nil @<%= file_name %>.remember_token
          assert_not_nil @<%= file_name %>.remember_token_expires_at
        end
        
        should "remember for default two weeks" do
          assert @<%= file_name %>.remember_token_expires_at.between?(before, 2.weeks.from_now.utc)
        end
      end

      context "forget_me" do
        should "unset token" do
          @<%= file_name %>.remember_me
          @<%= file_name %>.forget_me
          assert_nil @<%= file_name %>.remember_token
        end
      end
    
      context "remember_me_for" do
        should "remember me for one week" do
          before = 1.week.from_now.utc
          @<%= file_name %>.remember_me_for 1.week
          after = 1.week.from_now.utc
          assert_not_nil @<%= file_name %>.remember_token
          assert_not_nil @<%= file_name %>.remember_token_expires_at
          assert @<%= file_name %>.remember_token_expires_at.between?(before, after)
        end
      end
    
      context "remember me until" do
        should "remember me until one week" do
          time = 1.week.from_now.utc
          @<%= file_name %>.remember_me_until time
          assert_not_nil @<%= file_name %>.remember_token
          assert_not_nil @<%= file_name %>.remember_token_expires_at
          assert_equal @<%= file_name %>.remember_token_expires_at, time
        end
      end
      
    end

  end

  protected
  def create_<%= file_name %>(options = {})
    record = <%= class_name %>.new({ :login => 'quire', :email => 'quire@example.com', :password => 'quire69', :password_confirmation => 'quire69' }.merge(options))
    record.<% if options[:stateful] %>register! if record.valid?<% else %>save<% end %>
    record
  end
end