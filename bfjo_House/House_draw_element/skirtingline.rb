module BFJO
  module House
    class Skirtingline < BFJO::House::MObject
      def initialize
        super
        @id = "踢脚线"
        set_id(@id)
        @height
        @depth
      end

      def set_height(height)
        @height = height
        @used_to_return["height"] = @height
      end

      def set_depth(depth)
        @depth = depth
        @used_to_return["depth"] = @depth
      end

      def set_data_from_measure

        inner_face = []
        walls = House.room.get["mobjects"]["BFJO::House::Wall"]
        walls.each{ |wall|
          point = wall.get["inner_points"][0]
          vector = wall.get["normal_vector"]
          plane = [point,vector]
          inner_face.push(plane)
        }

        skirtingline_height = House.cpoints[House.cpoints.size - 2].z.to_f
        point0 = House.cpoints[House.cpoints.size - 1]
        points = [point0]
        mi = Geometry::find_belong_wall(points,inner_face)

        plane = [walls[mi].get["inner_points"][0],walls[mi].get["normal_vector"]]
        skirtingline_width = point0.distance_to_plane plane
        set_depth(skirtingline_width)
        set_height(skirtingline_height)
      end

      def set_data_from_file(skirtingline_hash)
        @id = skirtingline_hash["id"]
        set_id(@id)
        set_height(skirtingline_hash["skirtingline_height"].mm)
        set_depth(skirtingline_hash["skirtingline_depth"].mm)
      end
    end
    
  	def self.measure_skirtingline
  		skirtingline = Skirtingline.new
      skirtingline.set_data_from_measure
      House.room.set_mobject(skirtingline)
      skirtingline.get["su_model"].draw(skirtingline)
  		#还原标志
  		state = "'[End]测量踢脚线结束'"
	    House.Web.execute_script("show("+"#{state}"+")") #
	    message = "'踢脚线测量完成！'"
	    House.Web.execute_script("showMessage("+"#{message}"+")")
  	end
  end
end