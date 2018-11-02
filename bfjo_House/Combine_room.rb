module BFJO
  module House
    class Room_observer < Sketchup::EntitiesObserver
      def onElementModified(entities, entity)
        if !entity.deleted? && House.has_transformed == 0
          if entity.typename == "Group" && entity.get_attribute("house_mobject","type") == "room"
            roomname = entity.get_attribute("house_mobject","id")
            puts roomname
            room1 = House.house.get["rooms"]["#{roomname}"]
            puts room1.get["id"]
            bb1 = entity.bounds
            room2 = []
            entities.each{ |e|  
              if !e.deleted?
                if e.typename == "Group" && e.get_attribute("house_mobject","type") == "room" && e != entity
                  bb2 = e.bounds
                  puts bb1.intersect(bb2).empty?
                  if bb1.intersect(bb2).empty? != true
                    if room2 == []
                      roomname_array = e.get_attribute("house_mobject","id")
                      roomname_array = roomname_array.split(",")
                      puts roomname_array
                      roomname_array.each{ |roomname|  
                        room2.push(House.house.get["rooms"]["#{roomname}"])
                        # puts room2[0].get[0]
                      }
                    else
                      UI.messagebox("当前房间与多个房间重叠")
                      room2 = []
                    end
                  end
                end
              end
            }
            if room2 != []
              room2.each{ |room|  
                House.combine_room(room1,room)
                puts room.get["id"]
              }
            end
          end
        end
      end

      # def onElementAdded(entities, entity)
      #   if !entity.deleted?
      #     if entity.typename == "Group" && (entity.get_attribute("wall","id") != nil || entity.get_attribute("type","room") == 1)
      #       puts "undo::group::onElementAdded: #{entity}"
      #       House.last_entity.push(entity)
      #     end
      #   end
      # end
    end
    
  	def self.start_combine_room
      puts "start"
      House.has_transformed = 0
      House.Web.canClick = 1
  		House.entities.add_observer(House.room_observer)

      state="'拼接房屋'"
      House.current_work = '拼接房屋'
      House.Web.execute_script("show("+"#{state}"+")")
  	end

  	def self.combine_room(room1,room2)
      House.has_transformed = 1
  		walls1 = room1.get["mobjects"]["BFJO::House::Wall"]
      walls2 = room2.get["mobjects"]["BFJO::House::Wall"]
      tr1 = House.room_tr["#{room1.get["id"]}"].inverse  #数据点对应的模型的tr
      tr2 = room1.get["su_model"].get["entity"].transformation  #当前实际模型对应的tr

      std_floor_vector = Geom::Vector3d.new(0,0,1)
      floor_vector = std_floor_vector.transform tr2
      if floor_vector.angle_between(std_floor_vector) > 0.001
        std_normal = std_floor_vector * floor_vector
        std_point = Geom::Point3d.new(0,0,0)
        angle = floor_vector.angle_between std_floor_vector
        std_rt = Geom::Transformation.rotation(std_point,std_normal,angle)
        floor_vector.transform! std_rt
        if floor_vector.angle_between(std_floor_vector) > 0.001
          std_rt = Geom::Transformation.rotation(std_point,std_normal,-angle)
        end
        room1.get["su_model"].get["entity"].transform! std_rt
        tr2 = room1.get["su_model"].get["entity"].transformation
      end
      
      tr3 = House.room_tr["#{room2.get["id"]}"].inverse
      tr4 = room2.get["su_model"].get["entity"].transformation

      std_floor_vector = Geom::Vector3d.new(0,0,1)
      floor_vector = std_floor_vector.transform tr4
      if floor_vector.angle_between(std_floor_vector) > 0.001
        std_normal = std_floor_vector * floor_vector
        std_point = Geom::Point3d.new(0,0,0)
        angle = floor_vector.angle_between std_floor_vector
        std_rt = Geom::Transformation.rotation(std_point,std_normal,angle)
        floor_vector.transform! std_rt
        if floor_vector.angle_between(std_floor_vector) > 0.001
          std_rt = Geom::Transformation.rotation(std_point,std_normal,-angle)
        end
        room1.get["su_model"].get["entity"].transform! std_rt
        tr4 = room1.get["su_model"].get["entity"].transformation
      end

      midps1 = self.get_midp_array(room1,tr1,tr2)
      puts "adiabdiabd"
      puts midps1
      midps2 = self.get_midp_array(room2,tr3,tr4)
      puts midps2
      mdis = 999999
      allmdis = 999999
      i1 = 0
      i2 = 0
      mi1 = 0
      mi2 = 0
      wid1 = 0
      wid2 = 0
      have_door = 0
      midps1.each{ |wallid1,midp1a|
        i1 = 0
        if midp1a != []
          midp1a.each{ |midp1|
            temp_mi = 0
            temp_wid = 0
            midps2.each{ |wallid2,midp2a|
              i2 = 0
              if midp2a != []
                have_door = 1
                midp2a.each{ |midp2|  #找出当前midp1对应的距离最小的midp2
                  dis = midp2.distance midp1
                  if dis < mdis
                    mdis = dis
                    temp_mi = i2
                    temp_wid = wallid2
                  end
                  i2 += 1
                }
              end
            }
            if mdis < allmdis 
              allmdis = mdis
              mi1 = i1
              mi2 = temp_mi
              wid1 = wallid1
              wid2 = temp_wid
            end
            i1 += 1
          }
        end
      }
      if have_door == 1
        House.model.start_operation('合并房间', true)
        # puts "wid1:#{wid1},mi1:#{mi1},wid2:#{wid2},mi2:#{mi2}"
        wall1 = walls1[wid1.to_i - 1]
        wall2 = walls2[wid2.to_i - 1]
        vec1 = Geom::Vector3d.new(wall1.get["normal_vector"].x,wall1.get["normal_vector"].y,wall1.get["normal_vector"].z)
        vec2 = Geom::Vector3d.new(wall2.get["normal_vector"].x,wall2.get["normal_vector"].y,wall2.get["normal_vector"].z)
        #对墙的法向量做transform
        vec1 = vec1.transform tr1  #不使用transform!防止改变源数据
        vec1 = vec1.transform tr2
        vec1.reverse!  #reverse后变为两墙面法向量相同的情况
        vec2 = vec2.transform tr3
        vec2 = vec2.transform tr4
        normal = Geom::Vector3d.new(0,0,1)
        angle = vec1.angle_between vec2
        rt = Geom::Transformation.rotation([0,0,0],normal,angle)
        vec3 = vec1.transform rt
        # puts "v3 angle v2#{vec3.angle_between(vec2)}"
        if vec3.angle_between(vec2) > 0.01
          angle = 2 * Math::PI - angle
          rt = Geom::Transformation.rotation([0,0,0], normal, angle)
        end
        room1_entity = room1.get["su_model"].get["entity"].transform! rt

        new_tr = room1_entity.transformation
        puts "ccccc"
        puts wid1,mi1
        puts wid2,mi2
        midp1 = midps1["#{wid1}"][mi1]
        puts midp1
        midp1 = midp1.transform tr2.inverse
        midp1 = midp1.transform new_tr
        apoint = [wall1.get["outter_points"][0].x,wall1.get["outter_points"][0].y,wall1.get["outter_points"][0].z]
        apoint = apoint.transform tr1
        apoint = apoint.transform new_tr
        plane_vec = Geom::Vector3d.new(wall1.get["normal_vector"].x,wall1.get["normal_vector"].y,wall1.get["normal_vector"].z)
        plane_vec = plane_vec.transform tr1
        plane_vec = plane_vec.transform new_tr
        plane = [apoint,plane_vec]
        midp1 = midp1.project_to_plane plane  #投影到外墙面
        midp2 = midps2["#{wid2}"][mi2]
        vec = midp1.vector_to(midp2)
        vec.length = midp1.distance midp2
        tr = Geom::Transformation.translation(vec)
        room1_entity.transform! tr

        new_tr = room1_entity.transformation
        House.model.commit_operation
        #人工判断拼接是否合适，若合适则将2个房间合并为一个group，否则回退房屋的旋转
        result = UI.messagebox("拼接正确？", MB_OKCANCEL)  
        if result == IDOK #如果确认合并则修改相应数据
          result = UI.messagebox("请选择合并或重合（确定则合并，取消则重合）", MB_OKCANCEL)
          if result == IDOK
            layers = House.model.layers
            House.model.active_layer = layers[0]
            layers.remove("#{room1.get["id"]}")
            layers.remove("#{room2.get["id"]}")
            new_room_name = room1.get["id"] + "," + room2.get["id"]
            puts new_room_name
            room1.set_id("#{new_room_name}")
            room2.set_id("#{new_room_name}")
            layers.add("#{new_room_name}")
            House.model.active_layer = layers["#{new_room_name}"]
            room2_entity = room2.get["su_model"].get["entity"]
            room1_array = room1_entity.explode
            room2_array = room2_entity.explode
            new_room_array = []
            room1_array.each{ |entity|
              # puts "entity:#{entity}"
              if entity.typename == "Group" || entity.typename == "Text"
                s = entity.get_attribute("house_mobject","id")
                id = s.reverse.to_i
                if id != nil
                  walls1[id - 1].set_entity(0,entity)
                  if id != wid1.to_i
                    new_room_array.push(entity)
                  end
                else
                  new_room_array.push(entity)
                end
              end
            }
            room2_array.each{ |entity|  
              if entity.typename == "Group" || entity.typename == "Text"
                s = entity.get_attribute("house_mobject","id")
                id = s.reverse.to_i
                if id != nil
                  walls2[id - 1].set_entity(0,entity)
                  if id != wid2.to_i
                    new_room_array.push(entity)
                  end
                else
                  new_room_array.push(entity)
                end
              end
            }
            wall1_entity = wall1.get["su_model"].get["entity"]
            wall2_entity = wall2.get["su_model"].get["entity"]
            combine_wall = wall1_entity.union wall2_entity
            combine_wall.set_attribute "house_mobject","type","wall"
            combine_wall.set_attribute "house_mobject","id",wall1.get["id"]
            combine_wall.set_attribute "house_mobject","id",wall2.get["id"]
            new_room_array.push(combine_wall)
            wall1.get["su_model"].set_entity(combine_wall)
            wall2.get["su_model"].set_entity(combine_wall)
            puts new_room_array
            new_room_entity = House.entities.add_group new_room_array
            new_room_entity.set_attribute "type","room",1
            new_room_entity.set_attribute "room","name","#{new_room_name}"
            room1.get["su_model"].set_entity(new_room_entity)
            room2.get["su_model"].set_entity(new_room_entity)
          end
          self.update_data(room1,tr1,new_tr)
          self.update_data(room2,tr3,tr4)
          # House.entities.add_cpoint wall1.get[6][0]
          House.has_transformed = 0

          message="'房屋拼接完成！'"
          House.Web.execute_script("showMessage("+"#{message}"+")")
          
        else  #如果取消则回退房屋的旋转
          Sketchup.undo  
          House.has_transformed = 0
        end
        House.Web.canClick = 0
        House.entities.remove_observer(House.room_observer)
      else
        UI.messagebox("其中一个房间没有门")
        House.entities.remove_observer(House.room_observer)
      end
  	end

    def self.update_data(room,tr1,tr2)
      House.room_tr["#{room.get["id"]}"] = room.get["su_model"].get["entity"].transformation
      walls = room.get["mobjects"]["BFJO::House::Wall"]
      columns = room.get["mobjects"]["BFJO::House::Column"]
      girders = room.get["mobjects"]["BFJO::House::Girder"]
      electricities = room.get["mobjects"]["BFJO::House::Electricity"]
      skirtingline = room.get["mobjects"]["BFJO::House::Skirtingline"]
      tripoint_pipes = room.get["mobjects"]["BFJO::House::Tripoint_pipe"]
      water_pipes = room.get["mobjects"]["BFJO::House::Water_pipe"]
      windows = room.get["mobjects"]["BFJO::House::Window"]
      doors = room.get["mobjects"]["BFJO::House::Door"]
      i = 0
      walls.each{ |wall|
        i += 1
        puts i
        wall.get["normal_vector"].transform! tr1
        wall.get["normal_vector"].transform! tr2
        self.data_transform(wall.get["inner_points"],tr1,tr2)
        self.data_transform(wall.get["outter_points"],tr1,tr2)
      }
      if doors != [] && doors != nil
        doors.each{ |door|
          self.data_transform(door.get["points"],tr1,tr2)
        }
      end
      if columns != [] && columns != nil
        columns.each{ |column|   
          self.data_transform(column.get["points"],tr1,tr2)
        }
      end
      if girders != [] && girders != nil
        girders.each{ |girder|  
          self.data_transform(girder.get["points"],tr1,tr2)
        }
      end
      if electricities != [] && electricities != nil
        electricities.each{ |electricity|  
          self.data_transform(electricity.get["points"],tr1,tr2)
          electricity.get["normal"].transform! tr1
          electricity.get["normal"].transform! tr2
          if electricity.get["edge_vector"] != nil
            electricity.get["edge_vector"].transform! tr1
            electricity.get["edge_vector"].transform! tr2
          end
        }
      end
      if skirtingline != [] && skirtingline != nil
        self.data_transform(skirtingline.get["points"],tr1,tr2)
      end
      if tripoint_pipes != [] && tripoint_pipes != nil
        tripoint_pipes.each{ |tripoint_pipe|  
          tripoint_pipe.get["points"][0].transform! tr1
          tripoint_pipe.get["points"][0].transform! tr2
        }
      end
      if water_pipes != [] && water_pipes != nil
        water_pipes.each{ |water_pipe|  
          water_pipe.get["points"][0].transform! tr1
          water_pipe.get["points"][0].transform! tr2
        }
      end
      if windows != [] && windows != nil
        windows.each{ |window|  
          self.data_transform(window.get["points"],tr1,tr2)
        }
      end
    end

    def self.data_transform(array,tr1,tr2)
      if array != []
        array.each{ |point|  
          point.transform! tr1
          point.transform! tr2
          # House.entities.add_cpoint point
        }
      end
      # return point
    end

    def self.get_midp_array(room,tr1,tr2)
      midps = {}
      doors = room.get["mobjects"]["BFJO::House::Door"]
      doors.each{ |door|
        p1 = [door.get["points"][0].x,door.get["points"][0].y,door.get["points"][0].z]
        p2 = [door.get["points"][1].x,door.get["points"][1].y,door.get["points"][1].z]
        if p1.z > p2.z
          p2.z = p1.z
        else
          p1.z = p2.z
        end
        midp = [(p1.x + p2.x) / 2,(p1.y + p2.y) / 2,p1.z]
        midp = midp.transform tr1
        midp = midp.transform tr2
        # House.entities.add_cpoint midp
        midps["#{door.get["wid"]}"] = []
        midps["#{door.get["wid"]}"].push(midp)
      }
      return midps
    end
  end
end