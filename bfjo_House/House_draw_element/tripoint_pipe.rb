module BFJO
  module House
    class Tripoint_pipe < BFJO::House::MObject
      @@tripoint_pipe_num = 0
      def initialize
        super
        @@tripoint_pipe_num += 1
        @id = "三点水管" + "#{@@tripoint_pipe_num}"
        set_id(@id)
        @radius
        @height
      end

      def set_radius(radius)
        @radius = radius
        @used_to_return["radius"] = @radius
      end

      def set_height(height)
        @height = height
        @used_to_return["height"] = @height
      end

      def self.reset_num
        @@tripoint_pipe_num = 0
      end

      def self.num_delete
        @@tripoint_pipe_num -= 1
      end

      def set_data_from_measure
        point1 = House.cpoints[House.cpoints.size - 3]
        point2 = House.cpoints[House.cpoints.size - 2]
        point3 = House.cpoints[House.cpoints.size - 1]
        point1.z = 0
        point2.z = 0
        point3.z = 0
        center = Geometry::centerpoint_for_tripoints(point1,point2,point3)
        radius = point1.distance(center)
        set_radius(radius)
        set_point(0,center)
        height = House.room_height
        set_height(height.mm)
      end

      def set_data_from_file(tripoint_pipe_hash)
        @id = tripoint_pipe_hash["id"]
        set_id(@id)
        center = [tripoint_pipe_hash["center"].x.mm,tripoint_pipe_hash["center"].y.mm,tripoint_pipe_hash["center"].z.mm]
        center.transform! House.origin_tr
        set_point(0,center)
        set_radius(tripoint_pipe_hash["radius"].mm)
        set_height(tripoint_pipe_hash["height"].mm)
      end
    end

  	def self.measure_tripoint_pipe
  		tripoint_pipe = Tripoint_pipe.new
      tripoint_pipe.set_data_from_measure
      House.room.set_mobject(tripoint_pipe)
      tripoint_pipe.get["su_model"].draw(tripoint_pipe)
  		#还原标志
  		state = "'[End]测量三点水管结束'"
	    House.Web.execute_script("show("+"#{state}"+")") #
	    message = "'三点水管测量完成！'"
	    House.Web.execute_script("showMessage("+"#{message}"+")")
  	end
  end
end