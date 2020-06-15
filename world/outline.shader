shader_type canvas_item;
render_mode unshaded;

uniform float width = 1;
uniform vec4 color : hint_color = vec4(0, 0, 0, 1);
uniform vec2 tile_size = vec2(16, 16);

void fragment() {
	vec2 texture_tile_size = tile_size * TEXTURE_PIXEL_SIZE;
	vec2 tile = UV / texture_tile_size;
	vec2 min_uv = floor(tile) * texture_tile_size + TEXTURE_PIXEL_SIZE / 2.0;
	vec2 max_uv = ceil(tile) * texture_tile_size - TEXTURE_PIXEL_SIZE / 2.0;
	float weight = -8.0 * texture(TEXTURE, UV).a
		+ texture(TEXTURE, clamp(UV + TEXTURE_PIXEL_SIZE * vec2(width, width), min_uv, max_uv)).a
		+ texture(TEXTURE, clamp(UV + TEXTURE_PIXEL_SIZE * vec2(0, width), min_uv, max_uv)).a
		+ texture(TEXTURE, clamp(UV + TEXTURE_PIXEL_SIZE * vec2(-width, width), min_uv, max_uv)).a
		+ texture(TEXTURE, clamp(UV + TEXTURE_PIXEL_SIZE * vec2(-width, 0), min_uv, max_uv)).a
		+ texture(TEXTURE, clamp(UV + TEXTURE_PIXEL_SIZE * vec2(-width, -width), min_uv, max_uv)).a
		+ texture(TEXTURE, clamp(UV + TEXTURE_PIXEL_SIZE * vec2(0, -width), min_uv, max_uv)).a
		+ texture(TEXTURE, clamp(UV + TEXTURE_PIXEL_SIZE * vec2(width, -width), min_uv, max_uv)).a
		+ texture(TEXTURE, clamp(UV + TEXTURE_PIXEL_SIZE * vec2(width, 0), min_uv, max_uv)).a;
	COLOR = color * vec4(1, 1, 1, clamp(weight, 0, 1));
}