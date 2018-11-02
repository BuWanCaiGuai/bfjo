module BFJO
  module House
    class Ceilingline < BFJO::House::MObject
      def initialize
        super
        @id = "石膏线"
        set_id(@id)
        @height = []
        @depth
      end

      def set_height(height1,height2)
        @height.push(height1)
        @height.push(height2)
        @used_to_return["height"] = @height
      end

      def set_depth(depth)
        @depth = depth
        @used_to_return["depth"] = @depth
      end

      def set_data_from_measure
        #内墙面
        inner_face = []
        walls = House.room.get["mobjects"]["BFJO::House::Wall"]
        walls.each{ |wall|
          point = wall.get["inner_points"][0]
          vector = wall.get["normal_vector"]
          plane = [point,vector]
          inner_face.push(plane)
        }

        ceiling_line_height1 = House.room.get["height"].mm - House.cpoints[House.cpoints.size - 2].z.to_f
        ceiling_line_height2 = House.room.get["height"].mm - House.cpoints[House.cpoints.size - 1].z.to_f
        point0 = House.cpoints[House.cpoints.size - 1]
        points = [point0]
        mi = Geometry::find_belong_wall(points,inner_face)

        plane = [walls[mi].get["inner_points"][0],walls[mi].get["normal_vector"]]
        ceiling_line_depth = point0.distance_to_plane plane
        #设置宽高
        set_depth(ceiling_line_depth)
        set_height(ceiling_line_height1,ceiling_line_height2)
      end

      def set_data_from_file(ceilingline_hash)
        @id = ceilingline_hash["id"]
        set_id(@id)
        set_height(ceilingline_hash["ceilingline_height"][0].mm,ceilingline_hash["ceilingline_height"][1].mm)
        set_depth(ceilingline_hash["ceilingline_depth"].mm)
      end
    end
    
  	def self.measure_ceilingline
  		ceilingline = Ceilingline.new
      ceilingline.set_data_from_measure
      House.room.set_mobject(ceilingline)
      ceilingline.get["su_model"].draw(ceilingline)
  		#还原标志
  		state = "'[End]测量石膏线结束'"
	    House.Web.execute_script("show("+"#{state}"+")") #
	    message = "'石膏线测量完成！'"
	    House.Web.execute_script("showMessage("+"#{message}"+")")
  	end
  end
end