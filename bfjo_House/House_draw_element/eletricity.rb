module BFJO
  module House
    class Electricity < BFJO::House::MObject
      @@electricity_num = 0
      def initialize
        super
        @@electricity_num += 1
        @id = "水电" + "#{@@electricity_num}"
        set_id(@id)
        @type = []
        @normal
        @edge_vector
        @num = 1
        @tag
        @used_to_return["num"] = @num
      end

      def set_type(type)
        @type.push(type)
        @used_to_return["type"] = @type
      end

      def set_tag(tag)
        @tag = tag
        @used_to_return["tag"] = @tag
      end

      def set_normal(normal)
        @normal = Geom::Vector3d.new(normal.x,normal.y,normal.z)
        @used_to_return["normal"] = @normal
      end

      def set_edge_vector(vector)
        @edge_vector = Geom::Vector3d.new(vector.x,vector.y,vector.z)
        @used_to_return["edge_vector"] = @edge_vector
      end

      def set_num(num)
        @num = num
        @used_to_return["num"] = @num
      end

      def set_data_from_measure
        electricity_type = House.electricity_map_hash[House.measure_option.to_s]
        electricity_type_flag = House.measure_count[House.current_work][House.measure_option.to_s].to_i
        inner_face = []
        walls = House.room.get["mobjects"]["BFJO::House::Wall"]
        walls.each{ |wall|
          point = wall.get["inner_points"][0]
          vector = wall.get["normal_vector"]
          plane = [point,vector]
          inner_face.push(plane)
        }
        if electricity_type_flag == 1
          point0 = House.cpoints[House.cpoints.size - 1]
          if electricity_type == "gas_on_ground" || electricity_type == "drain"
            plane = House.current_floor
            vector2 = plane[1]
          else
            #确定附属墙
            points = [point0]
            mi = Geometry::find_belong_wall(points,inner_face)
            plane = inner_face[mi]
            vector2 = walls[mi].get["normal_vector"].reverse
            puts mi
            puts vector2
          end

          if electricity_type == "cross_cline"
            midp = [point0.x,point0.y,point0.z]
          else
            midp = [point0.x,point0.y,point0.z]
            midp = midp.project_to_plane plane
          end
          set_point(0,midp)
          set_type(electricity_type_flag)
          set_type(electricity_type)
          set_normal(vector2)
        elsif electricity_type_flag == 2
          set_type(electricity_type_flag)
          set_type(electricity_type)
          cp1 = House.cpoints[House.cpoints.size - 2]
          cp2 = House.cpoints[House.cpoints.size - 1]
          cp_mid = [(cp1.x + cp2.x) / 2,(cp1.y + cp2.y) / 2,(cp1.z + cp2.z) / 2] #20180205
          set_point(0,cp_mid) #20180205
          if electricity_type == "outlet_on_ceiling"
            plane = House.current_ceiling
            ceiling_vector = House.current_ceiling[1].normalize!
            set_normal(ceiling_vector)
            vec1 = Geom::Vector3d.new(1,0,0).normalize!
            set_edge_vector(vec1)
            point1 = cp1.project_to_plane plane
            point3 = cp2.project_to_plane plane
            point2 = [point1.x,point3.y,point1.z]
            point4 = [point3.x,point1.y,point3.z]
          else
            points = [cp1,cp2]
            mi = Geometry::find_belong_wall(points,inner_face)
            plane = inner_face[mi]
            wall_vector = walls[mi].get["normal_vector"].normalize!
            set_normal(wall_vector.reverse)
            inner_points = walls[mi].get["inner_points"]
            vp1 = Geom::Point3d.new(inner_points[1].x,inner_points[1].y,inner_points[1].z)
            vp2 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,inner_points[0].z)
            vec1 = vp1 - vp2
            vec1 = Geom::Vector3d.new(vec1.x,vec1.y,vec1.z).normalize!
            set_edge_vector(vec1)
            point1 = cp1.project_to_plane plane
            point3 = cp2.project_to_plane plane
            point2 = [point1.x,point1.y,point3.z]
            point4 = [point3.x,point3.y,point1.z]
          end
          set_point(1,point1)
          set_point(2,point2)
          set_point(3,point3)
          set_point(4,point4)
        end
      end

      def set_data_from_file(electricity_hash)
        i = 0
        @id = electricity_hash["id"]
        set_id(@id)
        set_num(electricity_hash["num"])
        electricity_hash["electricity_points"].each{ |point|  
          point = [point.x.mm,point.y.mm,point.z.mm]
          point.transform! House.origin_tr
          set_point(i,point)
          i += 1
        }
        if electricity_hash["tag"] != nil
          set_tag(electricity_hash["tag"])
        end
        set_type(electricity_hash["electricity_type"][0])
        set_type(electricity_hash["electricity_type"][1])
        if electricity_hash["electricity_type"][0] == 2
          vector = electricity_hash["electricity_edge_vector"]
          vector = Geom::Vector3d.new(vector.x.mm,vector.y.mm,vector.z.mm)
          set_edge_vector(vector)
        end
        normal = electricity_hash["electricity_vector"]
        normal = Geom::Vector3d.new(normal.x.mm,normal.y.mm,normal.z.mm)
        set_normal(normal)
      end

      def self.reset_num
        @@electricity_num = 0
      end

      def self.num_delete
        @@electricity_num -= 1
      end
    end
    
    def self.measure_electricity
      flag = House.electricity_map_hash[House.measure_option.to_s]
      electricity = Electricity.new
      electricity.set_data_from_measure
      House.room.set_mobject(electricity)
      if flag == "cross_cline"
        House.Web.execute_script("add_cross_cline_tag()") 
      elsif flag != "switch" && flag != "socket"
        electricity.get["su_model"].draw(electricity)
        state = "'[End]水电测量结束'"
        House.Web.execute_script("show("+"#{state}"+")") #
        message = "'水电测量完成'"
        House.Web.execute_script("showMessage("+"#{message}"+")")
      else
        House.Web.execute_script("enter_electricity_num()")
      end
    end

    def self.draw_multi_electricity(num)
      electricity = House.room.get["mobjects"]["BFJO::House::Electricity"]
      electricity = electricity[electricity.size - 1]
      electricity.set_num(num.to_i)
      
      electricity.get["su_model"].draw(electricity)
      House.room.set_mobject(electricity)
      state = "'[End]水电测量结束'"
      House.Web.execute_script("show("+"#{state}"+")") #
      message = "'水电测量完成'"
      House.Web.execute_script("showMessage("+"#{message}"+")")
    end

    def self.get_cross_cline_tag(tag)
      electricity = House.room.get["mobjects"]["BFJO::House::Electricity"]
      electricity = electricity[electricity.size - 1]
      electricity.get["su_model"].draw(electricity)
      electricity.set_tag(tag)
      layers = House.model.layers
      tab_layer_name = "标签"
      tab_layer = layers[tab_layer_name]
      House.model.active_layer = tab_layer
      text = House.entities.add_text tag,electricity.get["points"][0]
      House.entity_group.push(text)
      state = "'[End]水电测量结束'"
      House.Web.execute_script("show("+"#{state}"+")") #
      message = "'水电测量完成'"
      House.Web.execute_script("showMessage("+"#{message}"+")")
    end
  end
end