module BFJO
  module House  
    class Girder < BFJO::House::MObject
      @@girder_num = 0
      def initialize
        super
        @@girder_num += 1
        @id = "梁" + "#{@@girder_num}"
        set_id(@id)
        @type = 'corner_girder'
      end

      def set_type(type)
        @type = type
        @used_to_return["type"] = @type
      end

      def self.num_delete
        @@girder_num -= 1
      end

      def self.reset_num
        @@girder_num = 0
      end

      def set_data_from_measure
        layers = House.model.layers
        #使用数据绘制梁柱
        #角梁的投影点
        if House.measure_option == 1
          record_point0 = House.cpoints[House.cpoints.size - 2] 
          #投影点映射到地面
          record_point0.z = 0
          record_point1 = House.cpoints[House.cpoints.size - 1]
        elsif House.measure_option == 2
          record_point0 = House.cpoints[House.cpoints.size - 4] 
          record_point1 = House.cpoints[House.cpoints.size - 3]
          #投影点映射到地面
          record_point0.z = 0
          record_point1.z = 0
          record_point2 = House.cpoints[House.cpoints.size - 2] 
          record_point3 = House.cpoints[House.cpoints.size - 1] 
        end
       
        walls = House.room.get["mobjects"]["BFJO::House::Wall"]
        #记录梁所在的墙的数组下标
        inner_face = []
        walls = House.room.get["mobjects"]["BFJO::House::Wall"]
        walls.each{ |wall|
          point = wall.get["inner_points"][0]
          vector = wall.get["normal_vector"]
          plane = [point,vector]
          inner_face.push(plane)
        }
        points = [record_point0]
        mi = Geometry::find_belong_wall(points,inner_face)
        #当前墙
        current_wall = walls[mi]
        #当前墙所在的平面
        current_plane = [current_wall.get["inner_points"][0],current_wall.get["normal_vector"]]
        #测量角梁
        if House.measure_option == 1
          set_type('corner_girder')
          #获取左右墙
          if mi == 0 #如果是第一面墙
            previous_wall = walls[walls.size - 1]
            next_wall = walls[1]
          elsif mi == walls.size - 1 #如果是最后一面墙
            previous_wall = walls[0]
            next_wall = walls[walls.size - 2]
          else
            previous_wall = walls[mi - 1]
            next_wall = walls[mi + 1]
          end
          #得到天花板平面
          ceiling_plane = House.current_ceiling
          #前一面墙
          previous_plane = [previous_wall.get["inner_points"][0],previous_wall.get["normal_vector"]]
          #下一道墙
          next_plane = [next_wall.get["inner_points"][0],next_wall.get["normal_vector"]]
          inner_point1 = current_wall.get["inner_points"][0]
          inner_point2 = current_wall.get["inner_points"][1]
          x1 = record_point1.x
          y1 = record_point1.y
          z1 = record_point1.z
          outer_line = [Geom::Point3d.new(x1,y1,z1),Geom::Vector3d.new(inner_point2.x- inner_point1.x,inner_point2.y-inner_point1.y,inner_point2.z-inner_point1.z)]
          p1 = Geom.intersect_line_plane(outer_line, previous_plane )
          p5 = Geom.intersect_line_plane(outer_line, next_plane )
          vertical_line1 = [Geom::Point3d.new(p1.x,p1.y,p1.z),Geom::Vector3d.new(0, 0, 1)]
          p4 = Geom.intersect_line_plane(vertical_line1, ceiling_plane)
          vertical_line2 = [Geom::Point3d.new(p5.x,p5.y,p5.z),Geom::Vector3d.new(0, 0, 1)]
          p8 = Geom.intersect_line_plane(vertical_line2, ceiling_plane)
          p_tmp = record_point1.project_to_plane current_plane 
          x_tmp = p_tmp.x
          y_tmp = p_tmp.y
          z_tmp = p_tmp.z
          inner_line = [Geom::Point3d.new(x_tmp,y_tmp,z_tmp),Geom::Vector3d.new(inner_point2.x- inner_point1.x,inner_point2.y-inner_point1.y,inner_point2.z-inner_point1.z)]
          p2 = Geom.intersect_line_plane(inner_line, previous_plane )
          p6 = Geom.intersect_line_plane(inner_line, next_plane )
          vertical_line3 = [Geom::Point3d.new(p2.x,p2.y,p2.z),Geom::Vector3d.new(0, 0, 1)]
          p3 = Geom.intersect_line_plane(vertical_line3, ceiling_plane)
          vertical_line4 = [Geom::Point3d.new(p6.x,p6.y,p6.z),Geom::Vector3d.new(0, 0, 1)]
          p7 = Geom.intersect_line_plane(vertical_line4, ceiling_plane)
          # p3-----p4      p7-----p8  
          # |      |       |      |
          # |      |       |      |
          # p2-----p1      p6-----p5 从左往右看
          set_point(0,p1)
          set_point(1,p2)
          set_point(2,p3)
          set_point(3,p4)
          set_point(4,p5)
          set_point(5,p6)
          set_point(6,p7)
          set_point(7,p8)
          #girder_group = girder.draw
          #     p4 高
          # p2  | 
          # \   |
          #  \  |
          #   \ |
          # 深 \|__________ p5 宽
          #     p1         
          # height = p1.distance(p4)
          # width = p1.distance(p5)
          # depth = p1.distance(p2)
          # #为柱设置属性，value值为层的编号
          # girder_group.set_attribute "girde","type","corner_girde"
          # girder_group.set_attribute "girde_owner_wall","wall#{walls[mi].get["id"]}",walls[mi].get["id"].to_i
        #房中梁
        elsif House.measure_option == 2
          set_type('mid_girder')
          #梁连接的第一面墙
          current_wall_1 = current_wall
          current_plane_1 = current_plane
          #梁连接的第二面墙（对墙）
          current_wall_2 = nil
          current_plane_2 = nil
          points = [record_point1]
          mi = Geometry::find_belong_wall(points,inner_face)
          #记录房中梁所在的第二面墙
          current_wall_2 = walls[mi]
          #记录房中梁所在的第二面墙所在平面
          current_plane_2 = [current_wall_2.get["inner_points"][0],current_wall_2.get["normal_vector"]]
          #如果对墙不等于空
          if  current_wall_2 != nil
            # p2------p3                 p6------p7 
            # |        |                 |       |
            # |        |                 |       |
            # p1------p4   p1p5连线      p5------p8
            p1 = record_point2.project_to_plane  current_plane_1
            p4 = record_point3.project_to_plane  current_plane_1
            p5 = p1.project_to_plane  current_plane_2
            p8 = p4.project_to_plane  current_plane_2

            ceiling_plane =  House.current_ceiling
            p2 = p1.project_to_plane ceiling_plane
            p3 = p4.project_to_plane ceiling_plane
            p6 = p5.project_to_plane ceiling_plane
            p7 = p8.project_to_plane ceiling_plane
            set_point(0,p4)
            set_point(1,p1)
            set_point(2,p2)
            set_point(3,p3)
            set_point(4,p8)
            set_point(5,p5)
            set_point(6,p6)
            set_point(7,p7)
          end
        end  
      end

      def set_data_from_file(girder_hash)
        i = 0
        @id = girder_hash["id"]
        set_id(@id)
        set_type(girder_hash["type"])
        girder_hash["girder_points"].each{ |point|  
          point = [point.x.mm,point.y.mm,point.z.mm]
          point.transform! House.origin_tr
          set_point(i,point)
          i += 1
        }
      end

      def create_dim
        point1 = @points[0]
        point2 = @points[1]
        point3 = @points[5]
        point4 = @points[4]
        point5 = @points[3]

        midp1 = Geometry::intersect_between_lines(point1,point3,point2,point4)
        midp2 = Geom::Point3d.new(midp1.x,midp1.y,0)
        midp3 = Geom::Point3d.new((point1.x + point4.x) / 2,(point1.y + point4.y) / 2,(point1.z + point4.z) / 2)
        midp4 = Geom::Point3d.new((point2.x + point3.x) / 2,(point2.y + point3.y) / 2,(point2.z + point3.z) / 2)

        midp5 = Geom::Point3d.new(midp3.x,midp3.y,point5.z)
        v1 = Geom::Vector3d.new(point4.x - point1.x,point4.y - point1.y,point4.z - point1.z)
        v2 = Geom::Vector3d.new(point5.x - point1.x,point5.y - point1.y,point5.z - point1.z)
        v3 = v1 * v2
        v3.length = 10

        @mdimension.create_dim(midp1,midp2,v3,@id,"redraw_ground",1)
        if @type == "corner_girder"
          offset1 = Geom::Vector3d.new(0,0,-10)
          @mdimension.create_dim(midp3,midp4,offset1,@id,"redraw_depth",1)
          @mdimension.create_dim(midp3,midp5,v3,@id,"redraw_height",1)
        end
      end
    end
    #测量梁
    def self.measure_girder
      girder = Girder.new 
      girder.set_data_from_measure
      House.room.set_mobject(girder)
      girder.get["su_model"].draw(girder)
      state="'[End]梁测量完毕'"
      House.Web.execute_script("show("+"#{state}"+")")
      message="'梁测量完成！'"
      House.Web.execute_script("showMessage("+"#{message}"+")")
    end
  end
end