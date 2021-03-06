require File.dirname(__FILE__) + '/../test_helper'

class TypusControllerTest < ActionController::TestCase

  def setup
    Typus::Configuration.options[:recover_password] = true
    Typus::Configuration.options[:app_name] = "whatistypus.com"
  end

  def test_should_render_login
    get :login
    assert_response :success
    assert_template 'login'
  end

  def test_should_login_and_redirect_to_dashboard
    typus_user = typus_users(:admin)
    post :login, { :user => { :email => typus_user.email, 
                              :password => '12345678' } }
    assert_equal typus_user.id, @request.session[:typus]
    assert_response :redirect
    assert_redirected_to admin_dashboard_url
  end

  def test_should_not_login_disabled_user
    typus_user = typus_users(:disabled_user)
    post :login, { :user => { :email => typus_user.email, 
                              :password => '12345678' } }
    assert_nil @request.session[:typus]
    assert_response :redirect
    assert_redirected_to admin_login_url
  end

  def test_should_not_login_removed_role
    typus_user = typus_users(:removed_role)
    post :login, { :user => { :email => typus_user.email, 
                              :password => '12345678' } }
    assert_equal typus_user.id, @request.session[:typus]
    assert_response :redirect
    assert_redirected_to admin_dashboard_url
    get :dashboard
    assert_redirected_to admin_login_url
    assert_nil @request.session[:typus]
    assert flash[:error]
    assert_equal "Error! Typus User or role doesn't exist.", flash[:error]
  end

  def test_should_not_send_recovery_password_link_to_unexisting_user
    post :recover_password, { :user => { :email => 'unexisting' } }
    assert_response :redirect
    assert_redirected_to admin_recover_password_url
    [ :notice, :error, :warning ].each { |f| assert !flash[f] }
  end

  def test_should_send_recovery_password_link_to_existing_user
    admin = typus_users(:admin)
    post :recover_password, { :user => { :email => admin.email } }
    assert_response :redirect
    assert_redirected_to admin_login_url
    assert flash[:success]
    assert_match /Password recovery link sent to your email/, flash[:success]
  end

  def test_should_logout
    admin = typus_users(:admin)
    @request.session[:typus] = admin.id
    get :logout
    assert_nil @request.session[:typus]
    assert_response :redirect
    assert_redirected_to admin_login_url
    [ :notice, :error, :warning ].each { |f| assert !flash[f] }
  end

  def test_should_not_allow_recover_password_if_disabled

    get :recover_password

    assert_response :success
    assert_template 'recover_password'

    Typus::Configuration.options[:recover_password] = false
    get :recover_password

    assert_response :redirect
    assert_redirected_to admin_login_url

  end

  def test_should_not_allow_reset_password_if_disabled

    get :reset_password

    assert_response :success
    assert_template 'reset_password'

    Typus::Configuration.options[:recover_password] = false
    get :reset_password

    assert_response :redirect
    assert_redirected_to admin_login_url

  end

  def test_should_return_404_when_reseting_passsowrd_if_token_is_invalid
    assert_raise(ActiveRecord::RecordNotFound) { get :reset_password, { :token => 'INVALID' } }
  end

  def test_should_allow_a_user_with_valid_token_to_change_password
    typus_user = typus_users(:admin)
    get :reset_password, { :token => typus_user.token }
    assert_response :success
    assert_template 'reset_password'
  end

  def test_should_verify_admin_login_layout_does_not_include_recover_password_link

    get :login
    assert_match /Recover password/, @response.body

    Typus::Configuration.options[:recover_password] = false
    get :login
    assert !@response.body.include?("Recover password")

  end

  def test_should_render_typus_login_top
    get :login
    assert_response :success
    assert_match /_top.html.erb/, @response.body
    assert_equal 'layouts/typus', @controller.active_layout
  end

  def test_should_render_admin_login_bottom
    get :login
    assert_response :success
    assert_select "h1", "whatistypus.com"
    assert_equal 'layouts/typus', @controller.active_layout
  end

  def test_should_verify_page_title_on_login
    get :login
    assert_select 'title', "#{Typus::Configuration.options[:app_name]} &rsaquo; Login"
  end

  def test_should_create_first_typus_user
    TypusUser.destroy_all
    assert_nil @request.session[:typus]
    assert TypusUser.find(:all).empty?
    get :login
    assert_response :redirect
    assert_redirected_to :action => 'setup'
    post :setup, :user => { :email => 'example.com' }
    assert_response :redirect
    assert_redirected_to :action => 'setup'
    assert flash[:error]
    assert_equal "That doesn't seem like a valid email address.", flash[:error]
    post :setup, :user => { :email => 'john@example.com' }
    assert_response :redirect
    assert_redirected_to :action => 'dashboard'
    assert flash[:notice]
    assert_match /Your new password is/, flash[:notice]
    assert @request.session[:typus]
    assert !(TypusUser.find(:all).empty?)
    @request.session[:typus] = nil
    get :setup
    assert_redirected_to :action => 'login'
  end

  def test_should_redirect_to_login_if_not_logged
    @request.session[:typus] = nil
    get :overview
    assert_response :redirect
    assert_redirected_to admin_login_url(:back_to => '/admin/overview')
  end

  def test_should_render_dashboard
    @request.session[:typus] = typus_users(:admin).id
    get :dashboard
    assert_response :success
    assert_template 'dashboard'
    assert_match "whatistypus.com", @response.body
    assert_equal 'layouts/admin', @controller.active_layout
  end

  def test_should_verify_overview_works
    @request.session[:typus] = typus_users(:admin).id
    get :overview
    assert_response :success
    assert_template 'overview'
    assert_equal 'layouts/admin', @controller.active_layout
  end

  def test_should_verify_overview_works
    @request.session[:typus] = typus_users(:admin).id
    TypusUser.destroy_all
    get :setup
    assert_response :success
    assert_template 'setup'
    assert_equal 'layouts/typus', @controller.active_layout
  end

  def test_should_verify_page_title_on_dashboard
    @request.session[:typus] = typus_users(:admin).id
    get :dashboard
    assert_select 'title', "#{Typus::Configuration.options[:app_name]} &rsaquo; Dashboard"
  end

  def test_should_verify_link_to_edit_typus_user
    @request.session[:typus] = typus_users(:admin).id
    get :dashboard
    assert_response :success
    assert_match "/admin/typus_users/#{@request.session[:typus]}/edit", @response.body
  end

  def test_should_show_add_links_in_resources_list_for_admin

    @request.session[:typus] = typus_users(:admin).id
    get :dashboard

    %w( typus_users posts pages assets ).each do |resource|
      assert_match "/admin/#{resource}/new", @response.body
    end

    %w( statuses orders ).each do |resource|
      assert_no_match /\/admin\/#{resource}\n/, @response.body
    end

  end

  def test_should_show_add_links_in_resources_list_for_editor
    editor = typus_users(:editor)
    @request.session[:typus] = editor.id
    get :dashboard
    assert_match "/admin/posts/new", @response.body
    assert_no_match /\/admin\/typus_users\/new/, @response.body
    # We have loaded categories as a module, so are not displayed 
    # on the applications list.
    assert_no_match /\/admin\/categories\/new/, @response.body
  end

  def test_should_show_add_links_in_resources_list_for_designer
    designer = typus_users(:designer)
    @request.session[:typus] = designer.id
    get :dashboard
    assert_no_match /\/admin\/posts\/new/, @response.body
    assert_no_match /\/admin\/typus_users\/new/, @response.body
  end

  def test_should_render_application_dashboard_template_extensions
    admin = typus_users(:admin)
    @request.session[:typus] = admin.id
    get :dashboard
    assert_response :success
    partials = %w( _sidebar.html.erb _top.html.erb _bottom.html.erb )
    partials.each { |p| assert_match p, @response.body }
  end

end