shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float line_thickness : hint_range(0.0, 10.0) = 1.0;

// precision: Higher = smoother corners, but more GPU usage. 
// 16 is usually enough for characters.
const int PRECISION = 64; 

void fragment() {
	vec2 size = TEXTURE_PIXEL_SIZE * line_thickness;
	float outline = 0.0;
	
	// Iterate in a circle around the pixel
	for (int i = 0; i < PRECISION; i++) {
		// Calculate the angle for this sample
		float angle = (float(i) * 6.28318) / float(PRECISION);
		
		// Create an offset vector based on that angle
		vec2 offset = vec2(sin(angle), cos(angle)) * size;
		
		// Check the pixel at that offset
		outline += texture(TEXTURE, UV + offset).a;
	}
	
	// Clamp to 0-1 range
	outline = min(outline, 1.0);
	
	vec4 color = texture(TEXTURE, UV);
	
	// If the original pixel is transparent, but we found neighbors, draw the outline
	COLOR = mix(color, line_color, outline - color.a);
}