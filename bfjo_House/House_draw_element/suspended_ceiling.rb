module BFJO
  module House  
    class Suspended_ceiling < BFJO::House::MObject
      def initialize
        super
      end

      def set_data_from_measure
        walls = House.room.get["mobjects"]["BFJO::House::Wall"]
        inner_face = []
        walls.each{ |wall|
          point = wall.get["inner_points"][0]
          vector = wall.get["normal_vector"]
          plane = [point,vector]
          inner_face.push(plane)
        }
        sc_points = []
        sc_points.push(House.cpoints[House.cpoints.size - 2])
        sc_points.push(House.cpoints[House.cpoints.size - 1])
        mi = Geometry::find_belong_wall(sc_points,inner_face)
        for i in 0..1
          sc_points[i] = sc_points[i].project_to_plane inner_face[mi]
        end
        inner_points = walls[mi].get["inner_points"]
        point1 = Geometry::intersect_between_lines(inner_points[0],inner_points[2],sc_points[0],sc_points[1])
        point2 = Geometry::intersect_between_lines(inner_points[1],inner_points[3],sc_points[0],sc_points[1])

        set_point(0,point1)
        set_point(1,point2)
      end

      def set_data_from_file(suspended_ceiling_hash)
        i = 0
        suspended_ceiling_hash["suspended_ceiling_points"].each{ |point|  
          point = [point.x.mm,point.y.mm,point.z.mm]
          point.transform! House.origin_tr
          set_point(i,point)
          i += 1
        }
      end
    end

    def self.measure_suspended_ceiling
      suspended_ceiling = Suspended_ceiling.new
      suspended_ceiling.set_data_from_measure
      House.room.set_mobject(suspended_ceiling)
      suspended_ceiling.get["su_model"].draw(suspended_ceiling)
      #还原标志
      state="'[End]测量吊顶结束'"
      House.Web.execute_script("show("+"#{state}"+")") #
      message="'吊顶测量完成'"
      House.Web.execute_script("showMessage("+"#{message}"+")")
    end
  end
end