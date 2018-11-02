module BFJO
  module House   
    class Wall < BFJO::House::MObject
      @@wall_num = 0
      def initialize
        super
        @@wall_num += 1
        @id = "墙" + @@wall_num.to_s
        @used_to_return["id"] = @id
        @thickness
        @normal_vector
        @inner_points = []
        @outter_points = []
      end

      def set_thickness(thickness)
        @thickness = thickness
        @used_to_return["thickness"] = @thickness
      end

      def set_normal_vector(normal_vector)
        @normal_vector = normal_vector
        @used_to_return["normal_vector"] = @normal_vector
      end

      def set_inner_point(i,point)
        @inner_points[i] = Geom::Point3d.new(point.x,point.y,point.z)
        @used_to_return["inner_points"] = @inner_points
      end

      def set_outter_point(i,point)
        @outter_points[i] = Geom::Point3d.new(point.x,point.y,point.z)
        @used_to_return["outter_points"] = @outter_points
      end

      def set_data_from_measure
        self.set_thickness(House.wall_thickness)
        #cpoints最后两个点为内墙面点
        point1 = House.cpoints[House.cpoints.size - 2]
        point2 = House.cpoints[House.cpoints.size - 1]
        #计算墙面法向量使其模为墙的厚度
        vector1 = House.room.get["floor_vector"] #获取地面法向量
        vector2 = point1.vector_to(point2)
        wall_vector = vector1 * vector2
        wall_vector.length = House.wall_thickness
        self.set_normal_vector(wall_vector)
        #内墙面两点向墙面法向量方向平移得外墙面2点
        tr1 = Geom::Transformation.translation(wall_vector)
        point3 = point1.transform tr1
        point4 = point2.transform tr1
        #为wall实例赋值
        self.set_inner_point(0,point1)
        self.set_inner_point(1,point2)
        self.set_outter_point(0,point3)
        self.set_outter_point(1,point4)
      end

      def set_data_from_file(wall_hash)
        set_id(wall_hash["wall_id"])
        set_thickness(wall_hash["wall_thickness"].mm)
        vec = wall_hash["normal_vector"]
        vec = [vec.x.mm,vec.y.mm,vec.z.mm]
        vec = Geom::Vector3d.new vec
        set_normal_vector(vec)
        i = 0
        wall_hash["inner_points"].each{ |point|  
          point = [point.x.mm,point.y.mm,point.z.mm]
          point.transform! House.origin_tr
          set_inner_point(i,point)
          i += 1
        }
        i = 0
        wall_hash["outter_points"].each{ |point|  
          point = [point.x.mm,point.y.mm,point.z.mm]
          point.transform! House.origin_tr
          set_outter_point(i,point)
          i += 1
        }
      end

      def self.reset_num
        @@wall_num = 0
      end

      def self.num_delete
        @@wall_num -= 1
      end

      #得到墙及附着物的属性
      def get_wall_and_connected_attr
        #墙属性
        top_width = @inner_points[2].distance(@inner_points[3])
        bottom_width = @inner_points[0].distance(@inner_points[1])
        left_height = @inner_points[0].distance(@inner_points[2])
        right_height = @inner_points[1].distance(@inner_points[3])
        wall_attr = [(@thickness.to_mm).round,(bottom_width.to_mm).round,(top_width.to_mm).round,
          (left_height.to_mm).round,(right_height.to_mm).round]
        #门属性
        door_attr = []
        @door.each do |door_item|
          #门的对角两点
          #point1的z轴坐标比point2的z轴坐标大
          door_point1 = door_item.get[0][0]
          door_point2 = door_item.get[0][1]
          if door_point1.z<door_point2.z
            door_point1 = door_item.get[0][1]
            door_point2 = door_item.get[0][0]
          end
          door_point3 = [door_point2.x,door_point2.y,door_point1.z]
          door_point4 = [door_point1.x,door_point1.y,door_point2.z]
          door_width = door_point1.distance(door_point3)

          door_height = door_point1.z-door_point2.z
          wall_left_line = [@inner_points[0],Geom::Point3d.new(@inner_points[2])]
          wall_right_line = [@inner_points[1],Geom::Point3d.new(@inner_points[3])]
          left_side_distance = nil
          right_side_distance = nil
          top_side_distance = @inner_points[3].z-door_point1.z
          bottom_side_distance =  door_point2.z
          if door_point1.distance_to_line(wall_left_line) <= door_point2.distance_to_line(wall_left_line)
            left_side_distance = door_point1.distance_to_line(wall_left_line)
            right_side_distance = door_point2.distance_to_line(wall_right_line)
          else
            left_side_distance = door_point2.distance_to_line(wall_left_line)
            right_side_distance = door_point1.distance_to_line(wall_right_line)
          end
          door_item_attr = [(door_height.to_mm).round,(door_width.to_mm).round,(top_side_distance.to_mm).round,
                             (bottom_side_distance.to_mm).round,(left_side_distance.to_mm).round,
                             (right_side_distance.to_mm).round]
          door_attr.push(door_item_attr)
        end
        #窗属性
        window_attr = []
        @window.each do |window_item|
          #门的对角两点
          #point1的z轴坐标比point2的z轴坐标大
          window_point1 = window_item.get[0][0]
          window_point2 = window_item.get[0][1]
          if window_point1.z<window_point2.z
            window_point1 = window_item.get[0][1]
            window_point2 = window_item.get[0][0]
          end
          window_point3 = [window_point2.x,window_point2.y,window_point1.z]
          window_point4 = [window_point1.x,window_point1.y,window_point2.z]
          window_width = window_point1.distance(window_point3)

          window_height = window_point1.z-window_point2.z
          wall_left_line = [@inner_points[0],Geom::Point3d.new(@inner_points[2])]
          wall_right_line = [@inner_points[1],Geom::Point3d.new(@inner_points[3])]
          left_side_distance = nil
          right_side_distance = nil
          top_side_distance = @inner_points[3].z-window_point1.z
          bottom_side_distance =  window_point2.z
          if window_point1.distance_to_line(wall_left_line) <= window_point2.distance_to_line(wall_left_line)
            left_side_distance = window_point1.distance_to_line(wall_left_line)
            right_side_distance = window_point2.distance_to_line(wall_right_line)
          else
            left_side_distance = window_point2.distance_to_line(wall_left_line)
            right_side_distance = window_point1.distance_to_line(wall_right_line)
          end
          window_item_attr = [(window_height.to_mm).round,(window_width.to_mm).round,(top_side_distance.to_mm).round,
                             (bottom_side_distance.to_mm).round,(left_side_distance.to_mm).round,
                             (right_side_distance.to_mm).round]
          window_attr.push(window_item_attr)
        end
        #梁柱属性
        column_attr = []
        columns = []
        girdes = []
        House.entities.each{ |e|  
          if e.get_attribute("column_owner_wall","wall#{House.cwall.get[0].to_i}") == House.cwall.get[0].to_i
            columns.push(e)
          end
          if e.get_attribute("girde_owner_wall","wall#{House.cwall.get[0].to_i}") == House.cwall.get[0].to_i
            girdes.push(e)
          end
        }
        i = 0
        puts 'column:'+columns.size.to_s
        columns.each{ |c|
          type = c.get_attribute("column","type") 
          # if type != "墙中柱"    
          # end
          tmp = []
          tmp.push(type)
          # column_attr[i].push(type)
          height = c.get_attribute("column_attr","height")
          width = c.get_attribute("column_attr","width")
          depth = c.get_attribute("column_attr","depth")
          # anchor_point = c.get_attribute("anchor_point","point")
          anchor_point = c.get_attribute("point","anchor_point")
          tmp.push(depth.to_mm.round)
          tmp.push(width.to_mm.round)
          tmp.push(height.to_mm.round)
          left_dis = ""
          right_dis = ""
          walls = House.room.get[1]
          if House.cwall.get[0].to_i != 0
            if c.get_attribute("column_owner_wall","wall#{House.cwall.get[0].to_i - 1}") != nil
              left_dis = 0
              if House.cwall.get[0].to_i == walls.size - 1
                nwall = walls[walls.size - 1]
                plane = [Geom::Point3d.new(nwall.get[5][0]),Geom::Vector3d.new(nwall.get[3])]
                #right_dis = anchor_point.distance_to_plane plane
                right_dis = (bottom_width-width).to_mm.round
              else
                nwall = walls[House.cwall.get[0].to_i + 1]
                plane = [Geom::Point3d.new(nwall.get[5][0]),Geom::Vector3d.new(nwall.get[3])]
                #right_dis = anchor_point.distance_to_plane plane
                right_dis = (bottom_width-width).to_mm.round
              end
            else
              pwall = walls[House.cwall.get[0].to_i - 1]
              plane = [Geom::Point3d.new(pwall.get[5][0]),Geom::Vector3d.new(pwall.get[3])]
              #left_dis = anchor_point.distance_to_plane plane
              left_dis = (bottom_width-width).to_mm.round
              right_dis = 0
            end
          else
            if c.get_attribute("column_owner_wall","wall#{walls.size - 1}") != nil
              right_dis = 0
              nwall = walls[1]
              plane = [Geom::Point3d.new(nwall.get[5][0]),Geom::Vector3d.new(nwall.get[3])]
              #left_dis = anchor_point.distance_to_plane plane
              left_dis = (bottom_width-width).to_mm.round
            else
              pwall = walls[walls.size - 1]
              plane = [Geom::Point3d.new(pwall.get[5][0]),Geom::Vector3d.new(pwall.get[3])]
              #right_dis = anchor_point.distance_to_plane plane
              right_dis = (bottom_width-width).to_mm.round
              left_dis = 0
            end
           
          end
          dis = left_dis
          left_dis = right_dis
          right_dis = dis

          # column_attr[i].push(left_dis.to_mm.round)
          tmp.push(left_dis)
          # column_attr[i].push(right_dis.to_mm.round)
          tmp.push(right_dis)
          column_attr.push(tmp)
          # i+=1
        }
        girdes_attr = []
        #全部属性，二维数组
        wall_and_connected_attr = [wall_attr,door_attr,window_attr,column_attr,girdes_attr]
        return wall_and_connected_attr
      end

      # def find_inner_wall_face
      #   result = @entity[0]
      #   trs = result.transformation
      #   trs = trs.inverse
      #   p1 = @inner_points[0]
      #   p2 = @inner_points[1]
      #   p3 = @inner_points[2]
      #   p1 = p1.transform trs
      #   p2 = p2.transform trs
      #   p3 = p3.transform trs
      #   i = 0
      #   face_array = []
      #   minus = 0
      #   fi = 0
      #   result.entities.each{ |entity|
      #     if entity.is_a? Sketchup::Face
      #       face_array[i] = entity
      #       r1 = entity.classify_point(p1) == 2
      #       r2 = entity.classify_point(p2) == 2
      #       r3 = entity.classify_point(p3) == 2
      #       r = r1 && r2 && r3
      #       if r
      #         fi = i
      #         # puts "成功找到内墙面"
      #       end
      #       i += 1
      #     end
      #   }
      #   inner_wall = face_array[fi]
      #   # wall.set_entity(0,result)
      #   # wall.set_entity(1,text)
      #   # wall.set_entity(2,inner_wall)
      #   @entity[2] = inner_wall
      # end
    end

  	def self.measure_wall
      #为wall实例赋值
      wall = Wall.new
      House.room.set_mobject(wall)
      wall.set_data_from_measure
      #绘制墙面
      walls = House.room.get["mobjects"]["BFJO::House::Wall"]
      House.room.draw_outline
      House.count = 2
      state="'"+"准备测量第#{walls.size+1}面墙："+"'"
      House.Web.execute_script("show("+"#{state}"+")")
      if walls.size >= 4 
        state="'"+"[提示]您已测量#{walls.size}面墙，如还有墙面则继续测量，如封闭请点击‘封闭墙面’"+"'"
        House.Web.execute_script("show("+"#{state}"+")")
      end
  	end

    def self.encircle(option)
      if option == "0"
      	House.room.enclose_wall
      end
      if option == "1"
        House.room.direct_enclose_wall
      end
    end
  end
end