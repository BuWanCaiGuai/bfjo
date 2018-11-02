require 'sketchup.rb'
module Geometry
  #两线的交点
  #输入两直线（直线上两点）
  #使用Sketchup两直线求交点的方法
  #输出两直线交点
  def self.intersect_between_lines(line_1_start_point,line_1_end_point,line_2_start_point,line_2_end_point)
    point = Geom::Point3d.new
    line1 = [Geom::Point3d.new(line_1_start_point.x,line_1_start_point.y,line_1_start_point.z), Geom::Point3d.new(line_1_end_point.x,line_1_end_point.y,line_1_end_point.z)]
    line2 = [Geom::Point3d.new(line_2_start_point.x,line_2_start_point.y,line_2_start_point.z), Geom::Point3d.new(line_2_end_point.x,line_2_end_point.y,line_2_end_point.z)]
    point = Geom.intersect_line_line(line1, line2)
    return point
  end #两线的交点

  #坐标轴转换（需要用到Sketchup中的函数和数据结构）
  def self.reset_axes(pt1,pt2,zaxis)
    xaxis1 = Geom::Vector3d.new(1, 0, 0)
    yaxis1 = Geom::Vector3d.new(0, 1, 0)
    zaxis1 = Geom::Vector3d.new(0, 0, 1)
    xaxis2 = pt1.vector_to(pt2) #x轴
    yaxis2 = zaxis * xaxis2 #y轴
    Sketchup.active_model.axes.set(pt1, xaxis2, yaxis2, zaxis)
    tr = Sketchup.active_model.axes.transformation
    tr.invert!
    Sketchup.active_model.axes.set([0,0,0], xaxis1, yaxis1, zaxis1)
    return tr
  end

  def self.find_belong_wall(points,inner_face)
    #确定两点到各个内墙面的距离之和，并取其中最小值对应的墙面
    mdist = 0
    mi = 0
    i = 0
    result = ""
    psize = points.size
    while i < inner_face.size
      dists = []
      points.each{ |point|  
        dists.push(point.distance_to_plane inner_face[i])
      }
      dist = 0
      dists.each{ |d|  
        dist += d
      }
      if i == 0
        mdist = dist 
      elsif dist < mdist
        mdist = dist
        mi = i
      end
      i += 1
    end
    return mi
  end

  #直线的拟合
  #输入：拟合用点集合，拟合直线的两个端点
  #输出拟合直线的两个端点
  def self.fit_line(points,point1,point2)
    sum_point_x = 0.0
    sum_point_y = 0.0
    sum_point_x_square = 0.0
    sum_point_x_plus_y = 0.0        
    num = points.size

    i = 0
    while i < num
      sum_point_x += points[i].x
      sum_point_y += points[i].y
      sum_point_x_square += points[i].x ** 2
      sum_point_x_plus_y += points[i].x * points[i].y
      i += 1
    end

    #直线y=kx+b
    delta = sum_point_x_square * num - sum_point_x ** 2 # delta = 0, k = infinite
    alpha = sum_point_x_plus_y * num - sum_point_x * sum_point_y # alpha = 0, k = 0
    gama = sum_point_y * sum_point_x_square - sum_point_x * sum_point_x_plus_y

    if delta != 0.0 && alpha != 0.0 #k不等于0且k不为无穷大
      k = alpha / delta
      b = gama / delta
      point2.x = (points.last.x + k * points.last.y - k * b) / (k * k + 1)
      point2.y = k * point2.x + b
      point2.z = 0.0
      point1.x = (points.first.x + k * points.first.y - k * b) / (k * k + 1)
      point1.y = k * point1.x + b
      point1.z = 0.0
    elsif alpha == 0 #直线垂直于y轴
      tempy = gama / delta
      point2.x = points.last.x
      point2.y = tempy          
      point2.z = 0.0
      point1.x = points.first.x
      point1.y = tempy          
      point1.z = 0.0
    else #直线垂直于x轴
      tempx = -gama / alpha
      point2.x = tempx
      point2.y = points.last.y
      point2.z = 0.0
      point1.x = tempx
      point1.y = points.first.y
      point1.z = 0.0
    end
  end #直线的拟合
     
  #求经过三点的圆的圆心，三点两条线段，分别求线段的中垂线，两条中垂线的交点即圆心
  def self.centerpoint_for_tripoints(point1,point2,point3)
    if point1.y == point2.y && point2.y == point3.y
      UI.messagebox("经过这三点的圆不存在！", MB_OK)
    elsif point1.y == point2.y
      point2,point3 = point3,point2  #交换变量值
    elsif point2.y == point3.y
      point1,point2 = point2,point1
    end

    #(point1,point2)的中垂线垂足
    foot_point_1 = Geom::Point3d.new
    foot_point_1.x = (point1.x + point2.x) / 2.0
    foot_point_1.y = (point1.y + point2.y) / 2.0
    foot_point_1.z = 0.0

    #(point1,point2)的中垂线的斜率        
    k1 = (point1.x - point2.x) / (point2.y - point1.y)

    #(point2,point3)的中垂线垂足
    foot_point_2 = Geom::Point3d.new
    foot_point_2.x = (point2.x + point3.x) / 2.0
    foot_point_2.y = (point2.y + point3.y) / 2.0
    foot_point_2.z = 0.0

    #(point2,point3)的中垂线的斜率        
    k2 = (point2.x - point3.x) / (point3.y - point2.y)

    centerpoint = Geom::Point3d.new
    centerpoint.x = (foot_point_2.y - foot_point_1.y + k1 * foot_point_1.x - k2 * foot_point_2.x) / (k1 - k2)
    centerpoint.y = k1 * (centerpoint.x - foot_point_1.x) + foot_point_1.y 
    centerpoint.z = 0.0
      
    return centerpoint
  end #三点圆

  #坐标变换
  def self.coordinate_conversion(p1,p2,pt)
    
    p1p2 =( (p2.x - p1.x)**2 + (p2.y-p1.y)**2 )**(0.5)

    sina = (p2.y-p1.y) / p1p2
    cosa = (p2.x-p1.x) / p1p2

    point = Geom::Point3d.new
    point.x = (pt.x - p1.x)*cosa + (pt.y - p1.y)*sina
    point.y = (pt.y - p1.y)*cosa - (pt.x - p1.x)*sina
    point.z = 0.0

    return point
  end#坐标变换

  #点到直线的距离
  def self.distance_point_to_line(line_start,line_end,point)
    delta = line_end.x - line_start.x
    if delta != 0 
      b =(line_end.x * line_start.y  - line_start.x * line_end.y ) / delta 
      k = (line_end.y - line_start.y) / delta
      alpha =  ( k ** 2 + 1 )**( 1.0 / 2)

      distance = (k * point.x - point.y + b).abs / alpha
    else
      distance = (point.x - line_start.x).abs
    end
    return distance
  end#点到线的距离

  #点到直线的垂足
  def self.foot_point_to_line(line_start,line_end,point)
    delta = line_end.x - line_start.x
    beta = line_end.y - line_start.y
    per_point = Geom::Point3d.new
    if delta == 0
      per_point.y = point.y
      per_point.x = line_start.x
    elsif beta == 0
      per_point.x = point.x
      per_point.y = line_start.y
    else
      b =(line_end.x * line_start.y  - line_start.x * line_end.y ) / delta 
      k = (line_end.y - line_start.y) / delta 
      per_point.x = ( point.y + point.x / k - b ) / ( k + 1 / k)
      per_point.y = k * per_point.x + b
    end
    return per_point
  end #点到直线的垂足

  def self.midpoint_between_2point(point1,point2)
    midpoint = Geom::Point3d.new
    
    midpoint.x =  (point1.x + point2.x) / 2.0
    midpoint.y =  (point1.y + point2.y) / 2.0
    midpoint.z =  (point1.z + point2.z) / 2.0

    return midpoint
  end

end