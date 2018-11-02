# encoding: UTF-8
#
# file "Author_MultiClassPlugin/MultiClassPlugin_loader.rb"

module BFJO
  module House
    Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/Observer_class.rb")
    Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/House_Class.rb")
    Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/House_draw_element/room.rb")
    #带有类的文件如果该类要在插件加载时初始化，文件加载要写在main.rb前
    # Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/License_verify.rb") 
    Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/Exception.rb")  
    Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/Combine_room.rb")  
    Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/Geometry.rb")
  	Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/House_save.rb")
  	# Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/House_deprecated.rb")
  	Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/House_draw_element/door.rb")
    Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/House_draw_element/window.rb")
  	Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/House_draw_element/eletricity.rb")
  	Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/House_draw_element/girder.rb")
    Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/House_draw_element/column.rb")
    Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/House_draw_element/steps.rb")
  	Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/House_draw_element/wall.rb")
    Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/House_draw_element/skirtingline.rb")
    Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/House_draw_element/tripoint_pipe.rb")
    Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/House_draw_element/water_pipe.rb")
    Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/House_draw_element/plane.rb")
    Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/House_draw_element/ceilingline.rb")
    Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/House_draw_element/suspended_ceiling.rb")
    Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/Setting.rb")
    Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/Web.rb")
    Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/House_main.rb")
    Sketchup::require (Sketchup.find_support_file("Plugins") + "/bfjo_House/register.rb")
    # ... etc.
  end
end