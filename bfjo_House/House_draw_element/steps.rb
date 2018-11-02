module BFJO
  module House  
    class Steps < BFJO::House::MObject
      @@steps_num = 0
      def initialize
        super
        @@steps_num += 1
        @id = "台阶" + "#{@@steps_num}"
        set_id(@id)
      end

      def self.reset_num
        @@steps_num = 0
      end

      def self.num_delete
        @@steps_num -= 1
      end

      def set_data_from_measure
        layers = House.model.layers
        #使用数据绘制 
        record_point0 = House.cpoints[House.cpoints.size - 3] 
        record_point1 = House.cpoints[House.cpoints.size - 2]
        record_point2 = House.cpoints[House.cpoints.size - 1] 
        walls = House.room.get["mobjects"]["BFJO::House::Wall"]
        inner_face = []
        walls = House.room.get["mobjects"]["BFJO::House::Wall"]
        wall_count = walls.length
        walls.each{ |wall|
          point = wall.get["inner_points"][0]
          vector = wall.get["normal_vector"]
          plane = [point,vector]
          inner_face.push(plane)
        }
        points = [record_point0]
        mi = Geometry::find_belong_wall(points,inner_face)
        #台阶附属墙
        affiliated_wall = walls[mi]
        #附属墙所在的平面
        affiliated_wall_plane = [affiliated_wall.get["inner_points"][0],affiliated_wall.get["normal_vector"]]
        #附属墙的前一面墙
        previous_wall = walls[(mi-1) % wall_count]
        previous_wall_plane = [previous_wall.get["inner_points"][0],previous_wall.get["normal_vector"]]
        #附属墙的下一面墙
        next_wall = walls[(mi+1) % wall_count]
        next_wall_plane = [next_wall.get["inner_points"][0],next_wall.get["normal_vector"]]

        #第2点到前一面墙的距离
        p1_to_pre_wall_distance = record_point1.distance_to_plane(previous_wall_plane)
        p1_to_next_wall_distance = record_point1.distance_to_plane(next_wall_plane)

        #台阶左外点,默认台阶左上外点为point2
        left_top_outter_point = record_point1
        #台阶右外点
        right_top_outter_point = record_point2
        #判断
        if p1_to_pre_wall_distance > p1_to_next_wall_distance
          left_top_outter_point = record_point2
          right_top_outter_point = record_point1
        end
        #台阶外高线
        top_outter_line = [left_top_outter_point,right_top_outter_point]
        left_top_outter_point_distance =  left_top_outter_point.distance_to_plane(previous_wall_plane)
        right_top_outter_point_distance =  right_top_outter_point.distance_to_plane(next_wall_plane)

        floor_plane =   House.current_floor
        #如果左上角点距离上一面墙的距离小于5毫米，采取台阶外高线与两面墙的交点
        if left_top_outter_point_distance < 5.mm
          left_top_outter_point = Geom.intersect_line_plane(top_outter_line, previous_wall_plane)
        end

        if right_top_outter_point_distance < 5.mm
          right_top_outter_point = Geom.intersect_line_plane(top_outter_line, next_wall_plane)
        end

        left_bottom_outter_point = left_top_outter_point.project_to_plane(floor_plane)
        right_bottom_outter_point = right_top_outter_point.project_to_plane(floor_plane)

        left_bottom_inner_point = left_bottom_outter_point.project_to_plane(affiliated_wall_plane)
        right_bottom_inner_point = right_bottom_outter_point.project_to_plane(affiliated_wall_plane)

        left_top_inner_point = left_top_outter_point.project_to_plane(affiliated_wall_plane)
        right_top_inner_point = right_top_outter_point.project_to_plane(affiliated_wall_plane)

        set_point(0,left_top_outter_point)
        set_point(1,right_top_outter_point)
        set_point(2,right_bottom_outter_point)
        set_point(3,left_bottom_outter_point)
        set_point(4,left_top_inner_point)
        set_point(5,right_top_inner_point)
        set_point(6,right_bottom_inner_point)
        set_point(7,left_bottom_inner_point)
      end
      
      def set_data_from_file(steps_hash)
        i = 0
        @id = steps_hash["id"]
        set_id(@id)
        steps_hash["steps_points"].each{ |point|  
          point = [point.x.mm,point.y.mm,point.z.mm]
          point.transform! House.origin_tr
          set_point(i,point)
          i += 1
        }
      end
     
    end
    #测量台阶
    def self.measure_steps
      steps = Steps.new 
      steps.set_data_from_measure
      House.room.set_mobject(steps)
      steps.get["su_model"].draw(steps)
      state="'[End]台阶测量完毕'"
      House.Web.execute_script("show("+"#{state}"+")")
      message="'台阶测量完成！'"
      House.Web.execute_script("showMessage("+"#{message}"+")")
    end
  end
end