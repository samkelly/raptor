

def smart_resize_bounds(sw, sh, dw, dh)
  raise "dest width and dest height cannot both be nil!"  if dw.nil? && dh.nil?
  voff = 0.0; hoff = 0.0
  tdw = dw; tdh = dh;
  tsw = sw; tsh = sh;
  tdw = tdh * tsw / tsh if dw.nil?
  tdh = tdw * tsh / tsw if dh.nil?
  if !dw.nil? && !dh.nil?
    voff = tdh - (tsh * tdw) / tsw
    hoff = tdw - (tdh * tsw) / tsh
    voff = 0.0 if voff < 0.0
    hoff = 0.0 if hoff < 0.0
  end
  x = (hoff / 2.0).floor
  y = (voff / 2.0).floor
  w = (tdw - hoff).floor
  h = (tdh - voff).floor
  while true
    w += 1; next if w + x * 2 < dw
    w -= 1; next if w + x * 2 > dw
    h += 1; next if h + y * 2 < dh
    h -= 1; next if h + y * 2 > dh
    break
  end
  {x: x, y: y, w: w, h: h}
end

def get_image_gradient(img, grayscale=false)
  img = ChunkyPNG::Image.from_file(img) if img.is_a? String
  width = img.dimension.width
  height = img.dimension.height
  img2 = img.clone
  width.times do |x|
    height.times do |y|
      orig_color = img2[x, y]
      next if orig_color == 0
      vpos = Proc.new do |tx, ty|
        ret = nil
        if tx >= 0 && tx < width && ty >= 0 && ty < height
          ret = [tx, ty]
        else
          ret = [x, y]
        end
        ret
      end
      points = []
      points << vpos.(x - 1, y)
      points << vpos.(x - 1, y - 1)
      points << vpos.(x, y - 1)
      colors = []
      points.each {|point| colors << ChunkyPNG::Color.to_truecolor_bytes(img2[point[0], point[1]])}
      orig_color_bytes = ChunkyPNG::Color.to_truecolor_bytes(orig_color)
      avg_diff = [0.0, 0.0, 0.0]
      colors.each do |color|
        diff = [(color[0] - orig_color_bytes[0]).abs,
                (color[1] - orig_color_bytes[1]).abs,
                (color[2] - orig_color_bytes[2]).abs]
        avg_diff[0] += diff[0].to_f
        avg_diff[1] += diff[1].to_f
        avg_diff[2] += diff[2].to_f
      end
      avg_diff[0] = (avg_diff[0] / points.size).round
      avg_diff[1] = (avg_diff[1] / points.size).round
      avg_diff[2] = (avg_diff[2] / points.size).round
      if grayscale
        a = ((avg_diff[0].to_f + avg_diff[1].to_f + avg_diff[2].to_f) / 3.0).round
        avg_diff = [a, a, a]
      end
      img[x, y] = ChunkyPNG::Color.rgba(avg_diff[0], avg_diff[1], avg_diff[2], 255)
    end
    #puts "x: #{x}" if x % 100 == 0
  end
  #puts "saving image..."
  #img.save('test_output.png')
  img
end
