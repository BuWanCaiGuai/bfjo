module BFJO
  module House
    class Door < BFJO::House::MObject
      @@door_num = 0  #类变量
      def initialize
        super
        @wid
      end

      def set_door_id(id)
        @@door_num += 1
        @id = id + "#{@@door_num}"
        @used_to_return["id"] = @id
      end

      def set_wid(wid)
        @wid = wid
        @used_to_return["wid"] = @wid
      end

      def self.reset_num
        @@door_num = 0
      end

      def self.num_delete
        @@door_num -= 1
      end

      def create_dim
        point1 = @points[0]
        point2 = @points[1]
        midp = @points[2]
        walls = House.room.get["mobjects"]["BFJO::House::Wall"]
        wall = walls[@wid.to_i - 1]
        inner_points = wall.get["inner_points"]
        v1 = Geom::Vector3d.new(inner_points[1].x - inner_points[0].x,inner_points[1].y - inner_points[0].y,inner_points[1].z - inner_points[0].z)
        point1 = Geom::Point3d.new(point1.x,point1.y,point1.z)
        point2 = Geom::Point3d.new(point2.x,point2.y,point2.z)

        if point1.z > point2.z
          point3 = Geom::Point3d.new(point2.x,point2.y,point2.z)
          point2.z = point1.z
        else
          point3 = Geom::Point3d.new(point1.x,point1.y,point1.z)
          point1.z = point2.z
        end
        #           p2--------p1
        #           |          |
        #           |          |
        # p5------midp2      midp1 ------p4
        #                      |
        #                      |
        #                p6   p3
        #                p7
        v2 = point1 - point2
        if v2.angle_between(v1) > 0.01
          temp = point1
          point1 = point2
          point2 = temp
        end
        point3.x = point1.x
        point3.y = point1.y
        midp1 = Geom::Point3d.new(point1.x,point1.y,midp.z)
        midp2 = Geom::Point3d.new(point2.x,point2.y,midp.z)
        point4 = Geometry::intersect_between_lines(midp1,midp2,inner_points[1],inner_points[3])
        point5 = Geometry::intersect_between_lines(midp1,midp2,inner_points[0],inner_points[2])
        offset1 = Geom::Vector3d.new(v1.x,v1.y,v1.z)
        offset1.reverse!
        offset1.length = 24
        @mdimension.create_dim(point1,point3,offset1,@id,"redraw_height",2)

        offset2 = Geom::Vector3d.new(0,0,24)
        @mdimension.create_dim(point1,point2,offset2,@id,"redraw_width",3)

        offset3 = wall.get["normal_vector"]
        offset3.length = 0.1
        if midp1 != point4
          @mdimension.create_dim(midp1,point4,offset3,@id,"redraw_right2wall",1)
        end
        if midp2 != point5
          @mdimension.create_dim(midp2,point5,offset3,@id,"redraw_left2wall",1)
        end

        point6 = Geom::Point3d.new((point1.x + point2.x) / 2,(point1.y + point2.y) / 2,point3.z)
        point7 = Geom::Point3d.new(point6.x,point6.y,0)
        if point6 != point7
          @mdimension.create_dim(point6,point7,offset3,@id,"redraw_ground",1)
        end
      end

      def set_data_from_measure
        #找到所有内墙面
        inner_face = []
        walls = House.room.get["mobjects"]["BFJO::House::Wall"]
        walls.each{ |wall|
          point = wall.get["inner_points"][0]
          vector = wall.get["normal_vector"]
          plane = [point,vector]
          inner_face.push(plane)
        }
        if House.measure_option == 0 || House.measure_option == 1
          door_points = []
          if House.measure_option == 0
            l = 7
          elsif House.measure_option == 1
            l = 1
          end
              
          for i in 0..l
            door_points.push(House.cpoints[House.cpoints.size - l - 1 + i])
            puts i
          end
          mi = Geometry::find_belong_wall(door_points,inner_face)
          
          #找到投影点
          for i in 0..l
            door_points[i] = door_points[i].project_to_plane inner_face[mi]
          end

          if House.measure_option == 0
            door_point1 = Geometry::intersect_between_lines(door_points[0],door_points[1],door_points[2],door_points[3])
            door_point2 = Geometry::intersect_between_lines(door_points[4],door_points[5],door_points[6],door_points[7])
          elsif House.measure_option == 1
            door_point1 = door_points[0]
            door_point2 = door_points[1]
          end
        elsif House.measure_option == 2
          #顶一点，对边一点
          #确定对角两点
          door_point1 = House.cpoints[House.cpoints.size - 2]
          door_point2 = House.cpoints[House.cpoints.size - 1]

          door_points = [door_point1,door_point2]
          mi = Geometry::find_belong_wall(door_points,inner_face)

          door_point1 = door_point1.project_to_plane inner_face[mi]
          door_point2 = door_point2.project_to_plane inner_face[mi]
          if door_point1.z <= door_point2.z
             door_point1.z = 0.0
          else
            door_point2.z = 0.0
          end
        end

        inner_points = walls[mi].get["inner_points"]
        v1 = inner_points[1] - inner_points[0]
        check_point1 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,door_point1.z)
        check_point2 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,door_point2.z)
        v2 = door_point1 - check_point1
        v3 = door_point2 - check_point2
        if v1.angle_between(v2) > 0.01
          door_point1.x = inner_points[0].x
          door_point1.y = inner_points[0].y
        end
        if v1.angle_between(v3) > 0.01
          door_point2.x = inner_points[0].x
          door_point2.y = inner_points[0].y
        end
        check_point1 = Geom::Point3d.new(inner_points[1].x,inner_points[1].y,door_point1.z)
        check_point2 = Geom::Point3d.new(inner_points[1].x,inner_points[1].y,door_point2.z)
        v2 = door_point1 - check_point1
        v3 = door_point2 - check_point2
        if v1.angle_between(v2) < 0.01 
          door_point1.x = inner_points[1].x
          door_point1.y = inner_points[1].y
        end
        if v1.angle_between(v3) < 0.01 
          door_point2.x = inner_points[1].x
          door_point2.y = inner_points[1].y
        end
        midp = [(door_point1.x + door_point2.x) / 2,(door_point1.y + door_point2.y) / 2,(door_point1.z + door_point2.z) / 2]

        set_wid("#{mi + 1}")
        @points.push(door_point1)
        @points.push(door_point2)
        @points.push(midp)

      end

      def set_data_from_file(door_hash)
        i = 0
        set_id(door_hash["id"])
        door_hash["door_points"].each{ |point|  
          point = [point.x.mm,point.y.mm,point.z.mm]
          point.transform! House.origin_tr
          set_point(i,point)
          i += 1
        }
        set_wid(door_hash["wid"])
      end
    end

    def self.measure_door
  		#使用数据绘制门
      door = Door.new
      door.set_data_from_measure
      House.room.set_mobject(door)
      door.get["su_model"].draw(door)
      House.last_door = door
  		#还原标志
      state="'[End]测量门结束'"
      House.Web.execute_script("show("+"#{state}"+")") #
      message="'门测量完成'"
      House.Web.execute_script("show_door_type()")
      House.Web.execute_script("showMessage("+"#{message}"+")")
  	end

    def self.add_door_tag(type)
      layers = House.model.layers
      tab_layer_name = "标签"
      tab_layer = layers[tab_layer_name]
      House.model.active_layer = tab_layer
      House.last_door.set_door_id(type)
      House.last_door.create_dim
      text = House.entities.add_text type,House.last_door.get["points"][2]
      House.last_door.get["su_model"].set_text(text)
      House.entity_group.push(text)
      state = "'[Tag]添加#{type}标签'"
      House.Web.execute_script("show("+"#{state}"+")")
      message = "'添加#{type}标签成功！'"
      House.Web.execute_script("showMessage("+"#{message}"+")")
    end
  end
end