module BFJO
  module House
    class Column < BFJO::House::MObject
      @@column_num = 0
      def initialize
        super
        @@column_num += 1
        @id = "柱" + "#{@@column_num}"
        set_id(@id)
        @type
      end

      def self.reset_num
        @@column_num = 0
      end

      def self.num_delete
        @@column_num -= 1
      end

      def set_type(type)
        @type = type
        @used_to_return["type"] = @type
      end

      def create_dim
        point1 = @points[0]
        point2 = @points[1]
        point3 = @points[3]
        v1 = Geom::Vector3d.new(0,0,1)
        v2 = Geom::Vector3d.new(point2.x - point1.x,point2.y - point1.y,0)
        v3 = Geom::Vector3d.new(point3.x - point1.x,point3.y - point1.y,0)
        v4 = v2 * v3
        v5 = v2 * v4
        v6 = v4 * v3
        v5.length = 10
        v6.length = 10
        if @type == "house_mid_column"
          @mdimension.create_dim(point1,point2,v5,@id,"redraw_width",1)
        else
          @mdimension.create_dim(point1,point2,v5,@id,"redraw_width",3)
        end
        if @type == "wall_mid_column" || @type == "house_mid_column"
          @mdimension.create_dim(point1,point3,v6,@id,"redraw_depth",3)
        else
          @mdimension.create_dim(point1,point3,v6,@id,"redraw_depth",1)
        end

        if @type == "house_mid_column" #??????????离最近墙尺寸
          # midp = Geometry::intersect_between_lines(@points[0],@points[2],@points[1],@points[3])
          # walls = 
        end
      end

      def set_data_from_measure
        layers = House.model.layers
        inner_face = []
        walls = House.room.get["mobjects"]["BFJO::House::Wall"]
        walls.each{ |wall|
          point = wall.get["inner_points"][0]
          vector = wall.get["normal_vector"]
          plane = [point,vector]
          inner_face.push(plane)
        }
        #使用数据绘制梁柱
        if House.measure_option == 1
          set_type("corner_column")
          #测量角柱
          point0 = House.cpoints[House.cpoints.size - 2]
          point0.z = 0
          point1 = House.cpoints[House.cpoints.size - 1]
          point1.z = 0
          points = [point0]
          mi = Geometry::find_belong_wall(points,inner_face)
          #获取角柱附属的内墙面，并得到棱角点在墙面的投影点
          plane = inner_face[mi]
          point2 = point1.project_to_plane plane
          if mi == 0 #如果是第一面墙
            previous_wall = walls[walls.size - 1]
            next_wall = walls[1]
          elsif mi == walls.size - 1 #如果是最后一面墙
            previous_wall = walls[walls.size - 2]
            next_wall = walls[0]
          else
            previous_wall = walls[mi - 1]
            next_wall = walls[mi + 1]
          end
          plane1 = [previous_wall.get["inner_points"][0],previous_wall.get["normal_vector"]]
          dis1 = point1.distance_to_plane plane1
          plane2 = [next_wall.get["inner_points"][0],next_wall.get["normal_vector"]]
          dis2 = point1.distance_to_plane plane2
          if dis1 < dis2
            point3 = Geom::Point3d.new(walls[mi].get["inner_points"][0].x,walls[mi].get["inner_points"][0].y,walls[mi].get["inner_points"][0].z)
            point4 = point2
            point2 = point1.project_to_plane plane1
          else
            point3 = Geom::Point3d.new(walls[mi].get["inner_points"][1].x,walls[mi].get["inner_points"][1].y,walls[mi].get["inner_points"][1].z)
            point4 = point1.project_to_plane plane2
          end
          #获取点
          wall_layer_name = "#{House.room.get["id"]}" + walls[mi].get["id"]
          wall_layer = layers[wall_layer_name]
          House.model.active_layer = wall_layer  
          #column_group = column.draw
        elsif House.measure_option == 2
          set_type("wall_mid_column")
          #测量墙中柱
          point0 = House.cpoints[House.cpoints.size - 3]
          point0.z = 0
          point1 = House.cpoints[House.cpoints.size - 2]
          point1.z = 0
          point2 = House.cpoints[House.cpoints.size - 1]
          point2.z = 0
          points = [point0]
          mi = Geometry::find_belong_wall(points,inner_face)
          #获取角柱附属的内墙面，并得到棱角点在墙面的投影点
          plane = inner_face[mi]
          point3 = point2.project_to_plane plane
          point4 = point1.project_to_plane plane

          wall_layer_name = "#{House.room.get["id"]}" + walls[mi].get["id"]
          wall_layer = layers[wall_layer_name]
          House.model.active_layer = wall_layer
          #column_group = column.draw   
        elsif House.measure_option == 3
          set_type("house_mid_column")
          #测量中间柱
          point1 = House.cpoints[House.cpoints.size - 3]
          point1.z = 0
          point2 = House.cpoints[House.cpoints.size - 2]
          point2.z = 0
          point3 = House.cpoints[House.cpoints.size - 1]
          point3.z = 0
          point4 = Geom::Point3d.new(point1.x - point2.x + point3.x,point1.y - point2.y + point3.y,0)
          #设置活跃层为房间所属层
          room_layer = "#{House.room.get["id"]}"
          layer = layers[room_layer]
          House.model.active_layer = layer
        end
        ceiling_point = House.current_ceiling[0]
        ceiling_vector = House.room.get["ceiling_vector"]
        #计算与天花板交点
        a = ceiling_vector.x
        b = ceiling_vector.y
        c = ceiling_vector.z
        d = -(a * ceiling_point.x + b * ceiling_point.y + c * ceiling_point.z)
        z5 = -(a * point1.x + b * point1.y + d) / c
        point5 = [point1.x,point1.y,z5]
        z6 = -(a * point2.x + b * point2.y + d) / c
        point6 = [point2.x,point2.y,z6]
        z7 = -(a * point3.x + b * point3.y + d) / c
        point7 = [point3.x,point3.y,z7]
        z8 = -(a * point4.x + b * point4.y + d) / c
        point8 = [point4.x,point4.y,z8]
        set_point(0,point1)
        set_point(1,point2)
        set_point(2,point3)
        set_point(3,point4)
        set_point(4,point5)
        set_point(5,point6)
        set_point(6,point7)
        set_point(7,point8)
      end

      def set_data_from_file(column_hash)
        i = 0
        @id = column_hash["id"]
        set_id(@id)
        set_type(column_hash["type"])
        column_hash["column_points"].each{ |point|  
          point = [point.x.mm,point.y.mm,point.z.mm]
          point.transform! House.origin_tr
          set_point(i,point)
          i += 1
        }
      end
    end

    def self.measure_column
      column = Column.new
      column.set_data_from_measure
      House.room.set_mobject(column)
      column.get["su_model"].draw(column)
      state = "'[End]测量柱结束'"
      House.Web.execute_script("show("+"#{state}"+")") #
      message = "'柱测量完成！'"
      House.Web.execute_script("showMessage("+"#{message}"+")")
    end
  end
end