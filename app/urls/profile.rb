
# Loads the user profile page 
get '/:username' do
  user = params[:username]
  is_user = User.find_by_username(user)
  @layout_info = is_user ? layout_info("profile") : layout_info("profile", "usernotfound")
  @menu_data = profile_home_info(user) if is_user
  set_profile_page_info user
  erb(:"body/structure")
end


get '/:username/songs' do
  @user = User.with_username(params[:username])
  @layout_info = layout_info("profile", 'songs')
  @menu_data = profile_home_info(params[:username])
  @songs = @user.songs rescue []
  erb(:"body/structure")
end


get '/:username/jams' do
  user = params[:username]
  @layout_info = layout_info("profile", 'jams')
  @menu_data = profile_home_info(user)
  set_profile_page_info user
  erb(:"body/structure")
end

get '/:username/jammed_with' do
  @user = User.with_username(params[:username])
  @layout_info = {"left_panel" => "profile/menu", "middle_panel" => "profile/jammed_with"}
  @menu_data = profile_home_info(@user.username)
  erb(:'body/structure')
end

get '/:username/info' do
  @layout_info = {
    'left_panel' => 'profile/menu',
    "middle_panel" => 'profile/info'
  }
  @menu_data = profile_home_info(params[:username])
  erb(:"body/structure")
end
