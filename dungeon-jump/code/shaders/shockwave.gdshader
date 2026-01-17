shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform vec2 center = vec2(0.5, 0.5);
// Reduced force to 0.02 to prevent "tearing"
uniform float force = 0.02;
uniform float size = 0.0;
uniform float thickness = 0.1;
// Reduced aberration to 0.1 to stop the strobe effect
uniform float aberration = 0.1;
uniform float brightness = 0.5;

void fragment() {
	// 1. Aspect Ratio Fix (Defines scaled_uv)
	float ratio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	vec2 scaled_uv = (SCREEN_UV - vec2(0.5, 0.0)) / vec2(ratio, 1.0) + vec2(0.5, 0.0);
	vec2 scaled_center = (center - vec2(0.5, 0.0)) / vec2(ratio, 1.0) + vec2(0.5, 0.0);

	// 2. Calculate Mask
	float mask = (1.0 - smoothstep(size - 0.1, size, length(scaled_uv - scaled_center))) * smoothstep(size - thickness - 0.1, size - thickness, length(scaled_uv - scaled_center));

	// 3. Displacement
	vec2 disp = normalize(scaled_uv - scaled_center) * force * mask;

	// 4. Chromatic Aberration & Texture Sampling
	// We use the displacement to offset the Red and Blue channels slightly
	vec4 screen_color = texture(screen_texture, SCREEN_UV - disp);
	screen_color.r = texture(screen_texture, SCREEN_UV - disp * (1.0 + aberration)).r;
	screen_color.g = texture(screen_texture, SCREEN_UV - disp).g;
	screen_color.b = texture(screen_texture, SCREEN_UV - disp * (1.0 - aberration)).b;

	// 5. Apply Brightness (The Glow)
	screen_color.rgb = screen_color.rgb + (vec3(1.0) * mask * brightness);

	COLOR = screen_color;
}