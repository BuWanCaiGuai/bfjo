module BFJO
  	module House
	  	def self.measure_plane
	    	if House.measure_option == 1
	    	  	#地板三点，天花板三点
		        point1 = House.cpoints[House.cpoints.size - 6]
		        point2 = House.cpoints[House.cpoints.size - 5]
		        point3 = House.cpoints[House.cpoints.size - 4]
		        point4 = House.cpoints[House.cpoints.size - 3]
		        point5 = House.cpoints[House.cpoints.size - 2]
		        point6 = House.cpoints[House.cpoints.size - 1]
		        vector1 = point1.vector_to(point2)
		        vector2 = point2.vector_to(point3)
		        floor_vector = vector1 * vector2
		        floor_vector.normalize!
		        if floor_vector.z < 0
		          floor_vector.reverse!
		        end
		        vector3 = point4.vector_to(point5)
		        vector4 = point5.vector_to(point6)
		        ceiling_vector = vector3 * vector4
		        ceiling_vector.normalize!
		        if ceiling_vector.z < 0
		          ceiling_vector.reverse!
		        end
		        House.current_floor = [point1,floor_vector]
				House.current_ceiling = [point4,ceiling_vector]
		        dis1 = point4.distance_to_plane House.current_floor
		        dis2 = point5.distance_to_plane House.current_floor
		        dis3 = point6.distance_to_plane House.current_floor
		        room_height = ((dis1 + dis2 + dis3) / 3.0).to_mm.round
		    elsif House.measure_option == 0
		    	#地板一点，天花板一点
		        point1 = House.cpoints[House.cpoints.size - 2]
		        point2 = House.cpoints[House.cpoints.size - 1]
		        room_height =(point1.z-point2.z).abs().to_mm.round
		        floor_vector = Geom::Vector3d.new 0,0,1
		        ceiling_vector = floor_vector
		        House.current_floor = [point1,floor_vector]
				House.current_ceiling = [point2,ceiling_vector]
	    	end
			House.room_height = room_height
			House.room.set_height(room_height)
			puts House.room.get["height"]
			room_height_text= "'"+"#{room_height}"+"'"
			room_name = House.room.get["id"]
			room_name_text ="'"+"#{room_name}"+"'"
			House.Web.execute_script("set_room_height("+"#{room_height_text}"+","+"#{room_name_text}"+")")
			state = "'[End]结束测量地板/天花板'"
			House.Web.execute_script("show("+"#{state}"+")")
			state = "'准备测量墙...'"
			House.Web.execute_script("show("+"#{state}"+")")
			message="'地板/天花板测量结束'"
			#测量天花板/地板结束后显示相关按钮
			House.Web.execute_script("show_hidden_btn("+"#{message}"+","+"3"+")")
			#隐藏天花板/地板测量按钮
			House.Web.execute_script("hide_shown_component("+"1"+")")
			House.room.set_floor_vector(floor_vector)
			House.room.set_ceiling_vector(ceiling_vector)
			House.current_work = ""
	  	end
  	end
end