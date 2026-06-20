require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "devise sign in route is not captured by users show" do
    assert_recognizes({ controller: "devise/sessions", action: "new" }, "/users/sign_in")
  end

  test "should get devise sign in endpoint" do
    sign_out @user

    get new_user_session_url

    assert_response :success
    assert_select "form[action=?]", user_session_path
  end

  test "should get index" do
    get users_url

    assert_response :success
    assert_select "h1", "Usuarios"
    assert_select "td", text: /User One/
  end

  test "should get new" do
    get new_user_url

    assert_response :success
  end

  test "should create user with initial role" do
    assert_difference("User.count") do
      assert_difference("RoleAssignment.count") do
        post users_url, params: {
          user: {
            name: "New Operator",
            email: "new_operator@example.com",
            whatsapp_phone: "+573000000099",
            status: "active",
            password: "password123",
            password_confirmation: "password123",
            initial_business_id: businesses(:one).id,
            initial_role: "operator"
          }
        }
      end
    end

    assert_redirected_to user_url(User.last)
    assert_equal "operator", User.last.role_for(businesses(:one))
  end

  test "should show user" do
    get user_url(@user)

    assert_response :success
  end

  test "should get edit" do
    get edit_user_url(@user)

    assert_response :success
  end

  test "should update user without changing password" do
    patch user_url(@user), params: {
      user: {
        name: "Updated User",
        email: @user.email,
        whatsapp_phone: @user.whatsapp_phone,
        status: @user.status,
        password: "",
        password_confirmation: ""
      }
    }

    assert_redirected_to user_url(@user)
    assert_equal "Updated User", @user.reload.name
  end
end
