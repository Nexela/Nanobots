Proto = {}
--Quick to use empty sprite
Proto.empty_sprite ={
  filename = "__core__/graphics/empty.png",
  priority = "extra-high",
  width = 1,
  height = 1
}

--Quick to use empty animation
Proto.empty_animation = {
  filename = Proto.empty_sprite.filename,
  width = Proto.empty_sprite.width,
  height = Proto.empty_sprite.height,
  line_length = 1,
  frame_count = 1,
  shift = { -0.5, 0.5},
  animation_speed = 0
}

return Proto
