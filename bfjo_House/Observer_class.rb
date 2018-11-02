module BFJO
  	module House
		class Column_ent_ob < Sketchup::EntityObserver
		end

		class Girder_ent_ob < Sketchup::EntityObserver
		end

		class Steps_ent_ob < Sketchup::EntityObserver
		end

		class Wall_ent_ob < Sketchup::EntityObserver
		end

		class Room_ent_ob < Sketchup::EntityObserver
		end

		class Water_pipe_ent_ob < Sketchup::EntityObserver
		end

		class Tripoint_pipe_ent_ob < Sketchup::EntityObserver
		end

		class Skirtingline_ent_ob < Sketchup::EntityObserver
		end

		class Electricity_ent_ob < Sketchup::EntityObserver
		end

		class Ceilingline_ent_ob < Sketchup::EntityObserver
		end

		class MyDimensionObserver < Sketchup::DimensionObserver
			def onTextChanged(dimension)
				methodname = dimension.get_attribute "house_dim","methodname"
				belong_object = dimension.get_attribute "house_dim","belong_object"
				tiptype = dimension.get_attribute "house_dim","tiptype"
				# belong_object = belong_object.split(",")
				id = belong_object.reverse.to_i
				if (/门/.match(belong_object)) != nil
					doors = House.room.get["mobjects"]["BFJO::House::Door"]
					object = doors[id - 1]
				elsif (/窗/.match(belong_object)) != nil
					windows = House.room.get["mobjects"]["BFJO::House::Window"]
					object = windows[id - 1]
				elsif (/梁/.match(belong_object)) != nil
					girders = House.room.get["mobjects"]["BFJO::House::Girder"]
					object = girders[id - 1]		
				elsif (/柱/.match(belong_object)) != nil
					columns = House.room.get["mobjects"]["BFJO::House::Column"]
					object = columns[id - 1]
				elsif (/墙/.match(belong_object)) != nil
					walls = House.room.get["mobjects"]["BFJO::House::Wall"]
					object = walls[id - 1]
				end

				case tiptype
				when 0
					Sketchup.undo
					UI.messagebox("该尺寸不可更改")
					return
				when 1
					result = UI.messagebox("确认修改尺寸？",MB_OKCANCEL)
					if result == IDOK
						if methodname == "redraw_lwidth"
							methodname = "redraw_width"
							direct = "左"
						elsif methodname == "redraw_rwidth"
							methodname = "redraw_width"
							direct = "右"
						elsif methodname == "redraw_ldepth"
							methodname = "redraw_depth"
							direct = "左"
						elsif methodname == "redraw_rdepth"
							methodname = "redraw_depth"
							direct = "右"
						else
							direct = ""
						end
						object.get["mdimension"].send "#{methodname}",dimension.text,direct,object
					else
						Sketchup.undo
						return
					end
				when 2 #上下
					prompts = ["尺寸方向："]
				    defaults = ["上"]
				    list = ["上|下"]
				    result = inputbox(prompts, defaults,list, "选择尺寸修改方向")    
				    if result != false
				    	object.get["mdimension"].send "#{methodname}",dimension.text,result[0],object
				    else
				    	Sketchup.undo
				    	return
				    end
				when 3 #左右
					prompts = ["尺寸方向："]
				    defaults = ["左"]
				    list = ["左|右"]
				    result = inputbox(prompts, defaults,list, "选择尺寸修改方向")    
				    if result != false
				    	object.get["mdimension"].send "#{methodname}",dimension.text,result[0],object
				    else
				    	Sketchup.undo
				    	return
				    end
				end
				object.get["mdimension"].show_dim
				# puts "onTextChanged: #{dimension}, new_text= #{dimension.text}"
			end
		end
	end
end