module BFJO
  module House
  	class Water_pipe < BFJO::House::MObject
      @@water_pipe_num = 0
      def initialize
        super
        @@water_pipe_num += 1
        @id = "水管" + "#{@@water_pipe_num}"
        set_id(@id)
        @height
        @radius
        @type
        @vector
      end

      def set_radius(radius)
        @radius = radius
        @used_to_return["radius"] = @radius
      end

      def set_vector(vector)
        @vector = vector
        @used_to_return["normal"] = @vector
      end

      def set_type(type)
        @type = type
        @used_to_return["type"] = @type
      end

      def set_height(height)
        @height = height
        @used_to_return["height"] = @height
      end

      def set_data_from_measure
        if House.measure_option == 1 #地面水管
          center = House.cpoints[House.cpoints.size - 1]
          height = center.z
          vector = [0,0,1]
        elsif House.measure_option == 2 #墙面水管
          point1 = House.cpoints[House.cpoints.size - 2]
          point2 = House.cpoints[House.cpoints.size - 1]
          inner_face = []
          walls = House.room.get["mobjects"]["BFJO::House::Wall"]
          walls.each{ |wall|
            point = wall.get["inner_points"][0]
            vector = wall.get["normal_vector"]
            plane = [point,vector]
            inner_face.push(plane)
          }
          points = [point1]
          mi = Geometry::find_belong_wall(points,inner_face)
          plane = inner_face[mi]
          center = point2
          height = point2.distance_to_plane plane
          vector = walls[mi].get["normal_vector"].reverse
        end
        set_point(0,center)
        set_vector(vector)
        set_height(height)
        set_type(House.measure_option)
        set_radius(House.water_pipe_radius / 2)
      end

      def set_data_from_file(water_pipe_hash)
        @id = water_pipe_hash["id"]
        set_id(@id)
        set_radius(water_pipe_hash["radius"].mm)
        center = [water_pipe_hash["center"].x.mm,water_pipe_hash["center"].y.mm,water_pipe_hash["center"].z.mm]
        center.transform! House.origin_tr
        set_point(0,center)
        vector = [water_pipe_hash["normal"].x.mm,water_pipe_hash["normal"].y.mm,water_pipe_hash["normal"].z.mm]
        set_vector(vector)
        set_height(water_pipe_hash["height"].mm)
        set_type(water_pipe_hash["type"])
      end

      def self.reset_num
        @@water_pipe_num = 0
      end

      def self.num_delete
        @@wall_num -= 1
      end
    end

  	def self.measure_water_pipe
  		water_pipe = Water_pipe.new
      water_pipe.set_data_from_measure
      House.room.set_mobject(water_pipe)
  		water_pipe.get["su_model"].draw(water_pipe)
  		#还原标志
  		House.Web.canClick = 1
  		House.current_work = ""
  		House.count = 0
  		House.can_undo = 1
  		state = "'[End]测量水管结束'"
	    House.Web.execute_script("show("+"#{state}"+")") #
	    message = "'水管测量完成！'"
	    House.Web.execute_script("showMessage("+"#{message}"+")")
  	end

  	def self.get_water_pipe_radius(radius)
  		House.water_pipe_radius = radius.to_f.mm
  		self.measure_water_pipe
  	end
  end
end