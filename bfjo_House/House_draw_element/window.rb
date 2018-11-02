module BFJO
  module House
    class Window < BFJO::House::MObject
      @@window_num = 0
      def initialize
        super
        @@window_num += 1
        @id = "窗" + "#{@@window_num}"
        @used_to_return["id"] = @id
        @type = "normal_window"
        @wid
        @used_to_return["type"] = @type
      end

      def set_type(type)
        @type = type
        @used_to_return["type"] = @type
      end

      def set_wid(wid)
        @wid = wid
        @used_to_return["wid"] = @wid
      end

      def self.reset_num
        @@window_num = 0
      end

      def self.num_delete
        @@window_num -= 1
      end

      def set_data_from_measure
        #使用数据绘制窗
        inner_face = []
        walls = House.room.get["mobjects"]["BFJO::House::Wall"]
        walls.each{ |wall|
          point = wall.get["inner_points"][0]
          vector = wall.get["normal_vector"]
          plane = [point,vector]
          inner_face.push(plane)
        }
        #对角两点测窗
        if House.measure_option == 0 || House.measure_option == 1
          window_points = []
          if House.measure_option == 0
            l = 7
          elsif House.measure_option == 1
            l = 1
          end
              
          for i in 0..l
            window_points.push(House.cpoints[House.cpoints.size - l - 1 + i])
          end
          mi = Geometry::find_belong_wall(window_points,inner_face)
          
          #找到投影点
          for i in 0..l
            window_points[i] = window_points[i].project_to_plane inner_face[mi]
          end

          if House.measure_option == 0
            window_point1 = Geometry::intersect_between_lines(window_points[0],window_points[1],window_points[2],window_points[3])
            window_point2 = Geometry::intersect_between_lines(window_points[4],window_points[5],window_points[6],window_points[7])
          elsif House.measure_option == 1
            window_point1 = window_points[0]
            window_point2 = window_points[1]
          end

          inner_points = walls[mi].get["inner_points"]
          v1 = inner_points[1] - inner_points[0]
          check_point1 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,window_point1.z)
          check_point2 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,window_point2.z)
          v2 = window_point1 - check_point1
          v3 = window_point2 - check_point2
          if v1.angle_between(v2) > 0.01
            window_point1.x = inner_points[0].x
            window_point1.y = inner_points[0].y
          end
          if v1.angle_between(v3) > 0.01
            window_point2.x = inner_points[0].x
            window_point2.y = inner_points[0].y
          end
          check_point1 = Geom::Point3d.new(inner_points[1].x,inner_points[1].y,window_point1.z)
          check_point2 = Geom::Point3d.new(inner_points[1].x,inner_points[1].y,window_point2.z)
          v2 = window_point1 - check_point1
          v3 = window_point2 - check_point2
          if v1.angle_between(v2) < 0.01 
            window_point1.x = inner_points[1].x
            window_point1.y = inner_points[1].y
          end
          if v1.angle_between(v3) < 0.01 
            window_point2.x = inner_points[1].x
            window_point2.y = inner_points[1].y
          end

          set_wid("#{mi + 1}")
          set_point(0,window_point1)
          set_point(1,window_point2)
          @su_model.draw(self)
        #转角飘窗
        elsif House.measure_option == 3 
          #p1为左上角点，p2为右下角点，p3确定左边飘窗厚度，p4确定右边飘窗厚度
          point1 = House.cpoints[House.cpoints.size - 4]
          point2 = House.cpoints[House.cpoints.size - 3]
          wpoint1 = House.cpoints[House.cpoints.size - 2]
          wpoint2 = House.cpoints[House.cpoints.size - 1]
          #确定转角飘窗附属的两个墙面
          mdist1 = 0
          mdist2 = 0
          cdist1 = 0
          cdist2 = 0
          mi1 = 0
          mi2 = 0
          i = 0
          while i < inner_face.size
            dist1 = point1.distance_to_plane inner_face[i]
            dist2 = point2.distance_to_plane inner_face[i]
            if i == 0
              cdist1 = dist1
              mdist1 = dist1 
              cdist2 = dist2
              mdist2 = dist2 
            else
              cdist1 = dist1
              cdist2 = dist2
              if cdist1 < mdist1
                mdist1 = cdist1
                mi1 = i
              end
              if cdist2 < mdist2
                mdist2 = cdist2
                mi2 = i
              end
            end
            i += 1
          end
          point1 = point1.project_to_plane inner_face[mi1]
          point2 = point2.project_to_plane inner_face[mi2]
          vec1 = walls[mi1].get["normal_vector"]
          vec2 = walls[mi2].get["normal_vector"]
          dis1 = wpoint1.distance_to_plane inner_face[mi1]
          dis2 = wpoint2.distance_to_plane inner_face[mi2]
          vec1.length = dis1
          vec2.length = dis2
          tr1 = Geom::Transformation.translation(vec1)
          tr2 = Geom::Transformation.translation(vec2)
          point1.transform! tr1
          point2.transform! tr2
          point3 = [point1.x,point1.y,point1.z]
          point3.z = point2.z
          wpoint1.z = point2.z
          wpoint2.z = point2.z
          #求L型飘窗外轮廓交点
          intersect_point = Geometry::intersect_between_lines(point3,wpoint1,point2,wpoint2)

          belong_wall = "#{mi1 + 1},#{mi2 + 1}"
          puts "belong_wall,#{belong_wall}"
          set_wid(belong_wall)
          set_type('L_bay_window')
          #point1为外轮廓左上角点，point2为外轮廓右下角点，point3为左下角点，intersect_point为L型飘窗外轮廓交点
          @points.push(point1)
          @points.push(point2)
          @points.push(point3)
          @points.push(intersect_point)
          @su_model.draw(self)
        #飘窗
        elsif House.measure_option == 2
          #1,2为对角两点，第3点确定厚度
          window_point1 = House.cpoints[House.cpoints.size - 3]
          window_point2 = House.cpoints[House.cpoints.size - 2]
          window_point3 = House.cpoints[House.cpoints.size - 1]

          window_points = [window_point1,window_point2]
          mi = Geometry::find_belong_wall(window_points,inner_face)
          
          window_point1 = window_point1.project_to_plane inner_face[mi]
          window_point2 = window_point2.project_to_plane inner_face[mi]

          inner_points = walls[mi].get["inner_points"]
          v1 = inner_points[1] - inner_points[0]
          check_point1 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,window_point1.z)
          check_point2 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,window_point2.z)
          v2 = window_point1 - check_point1
          v3 = window_point2 - check_point2
          if v1.angle_between(v2) > 0.01
            window_point1.x = inner_points[0].x
            window_point1.y = inner_points[0].y
          end
          if v1.angle_between(v3) > 0.01
            window_point2.x = inner_points[0].x
            window_point2.y = inner_points[0].y
          end
          check_point1 = Geom::Point3d.new(inner_points[1].x,inner_points[1].y,window_point1.z)
          check_point2 = Geom::Point3d.new(inner_points[1].x,inner_points[1].y,window_point2.z)
          v2 = window_point1 - check_point1
          v3 = window_point2 - check_point2
          if v1.angle_between(v2) < 0.01 
            window_point1.x = inner_points[1].x
            window_point1.y = inner_points[1].y
          end
          if v1.angle_between(v3) < 0.01 
            window_point2.x = inner_points[1].x
            window_point2.y = inner_points[1].y
          end

          set_wid("#{mi + 1}")
          set_type('bay_window')
          @points.push(window_point1)
          @points.push(window_point2)
          @points.push(window_point3)
        end 
      end

      def set_data_from_file(window_hash)
        @id = window_hash["id"]
        set_id(@id)
        set_wid(window_hash["wid"])
        i = 0
        window_hash["window_points"].each{ |point|  
          point = [point.x.mm,point.y.mm,point.z.mm]
          point.transform! House.origin_tr
          set_point(i,point)
          i += 1
        }
        set_type(window_hash["window_type"])
      end

      def create_dim
        if @type == "normal_window" || @type == "bay_window"
          point1 = @points[0]
          point2 = @points[1]
          midp = Geom::Point3d.new((point1.x + point2.x) / 2,(point1.y + point2.y) / 2,(point1.z + point2.z) / 2)
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
          
          if @type = "normal_window"
            outter_points = wall.get["outter_points"]
            outter_face = [outter_points[0],offset3]
            point8 = point6.project_to_plane outter_face
            v1.length = 0.1
            @mdimension.create_dim(point6,point8,v1,@id,"redraw_depth",1)
          else
            outter_point = @points[2]
            outter_face = [outter_point,offset3]
            point8 = point6.project_to_plane outter_face
            v1.length = 0.1
            @mdimension.create_dim(point6,point8,v1,@id,"redraw_depth",1)
          end
        else
          point1 = Geom::Point3d.new(@points[0].x,@points[0].y,@points[0].z)
          point2 = Geom::Point3d.new(@points[1].x,@points[1].y,@points[1].z)
          point3 = Geom::Point3d.new(@points[2].x,@points[2].y,point1.z)
          point4 = Geom::Point3d.new(@points[3].x,@points[3].y,@points[3].z)

          walls = House.room.get["mobjects"]["BFJO::House::Wall"]
          id = @wid.split(",")
          wall1 = walls[id[0].to_i - 1]
          wall2 = walls[id[1].to_i - 1]

          inner_points1 = wall1.get["inner_points"]
          iface1 = [inner_points1[0],wall1.get["normal_vector"]]
          point3 = point3.project_to_plane iface1
          point5 = Geom::Point3d.new(inner_points1[1].x,inner_points1[1].y,point1.z)
          offset1 = Geom::Vector3d.new(0,0,14)
          @mdimension.create_dim(point3,point5,offset1,@id,"redraw_lwidth",1)

          inner_points2 = wall2.get["inner_points"]
          iface = [inner_points2[0],wall2.get["normal_vector"]]
          point6 = point2.project_to_plane iface
          point6.z = point1.z
          @mdimension.create_dim(point5,point6,offset1,@id,"redraw_rwidth",1)

          point7 = Geom::Point3d.new(point3.x,point3.y,@points[2].z)
          offset2 = Geom::Vector3d.new(inner_points1[0].x - inner_points1[1].x,inner_points1[0].y - inner_points1[1].y,inner_points1[0].z - inner_points1[1].z)
          offset2.length = 14
          offset2r = offset2.reverse
          @mdimension.create_dim(point3,point7,offset2r,@id,"redraw_height",2)

          point8 = Geom::Point3d.new(point5.x,point5.y,@points[2].z)
          point9 = Geom::Point3d.new(inner_points1[1].x,inner_points1[1].y,inner_points1[1].z)
          offset2.length = 5
          @mdimension.create_dim(point8,point9,offset2,@id,"redraw_ground",1)

          midpz = (point1.z + point7.z) / 2 
          point10 = Geom::Point3d.new(point3.x,point3.y,midpz)
          point11 = Geom::Point3d.new(inner_points1[0].x,inner_points1[0].y,midpz)
          offset3 = wall1.get["normal_vector"]
          offset3 = offset3.reverse
          offset3.length = 1
          @mdimension.create_dim(point10,point11,offset3,@id,"redraw_left2wall",1)
          
          point12 = Geom::Point3d.new(point6.x,point6.y,midpz)
          point13 = Geom::Point3d.new(inner_points2[1].x,inner_points2[1].y,midpz)
          offset4 = wall2.get["normal_vector"]
          offset4.length = 0.1
          @mdimension.create_dim(point12,point13,offset4,@id,"redraw_right2wall",1)

          point14 = Geom::Point3d.new((point3.x + point5.x) / 2,(point3.y + point5.y) / 2,point2.z)
          oface1 = [point1,offset3]
          point15 = point14.project_to_plane oface1
          offset5 = Geom::Vector3d.new(0,0,1)
          @mdimension.create_dim(point14,point15,offset5,@id,"redraw_ldepth",1)

          point16 = Geom::Point3d.new((point5.x + point6.x) / 2,(point5.y + point6.y) / 2,point2.z)
          oface2 = [point2,offset4]
          point17 = point16.project_to_plane oface2
          @mdimension.create_dim(point16,point17,offset5,@id,"redraw_rdepth",1)
        end
      end
    end

  	def self.measure_window
  		window = Window.new
      window.set_data_from_measure
      House.room.set_mobject(window)
      window.get["su_model"].draw(window)
      #还原标志
      state ="'[End]测量窗户结束'"
      House.Web.execute_script("show("+"#{state}"+")") #
      message="'窗户测量完成'"
      House.Web.execute_script("showMessage("+"#{message}"+")")
  	end
  end
end