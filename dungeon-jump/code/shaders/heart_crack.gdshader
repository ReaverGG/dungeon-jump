shader_type canvas_item;

// 0.0 = Normal, 1.0 = Broken/Grey
uniform float crack_progress : hint_range(0.0, 1.0) = 0.0;

// How wide the gap gets at maximum separation
uniform float max_separation = 0.1;

// Controls how wide the zigzag goes left and right
uniform float bolt_width = 0.05;

// --- BOLT SHAPE DEFINITION ---
// We define the bolt in 3 vertical sections.
// You can tweak these Y positions to change where the turns happen.
const float y_turn_1 = 0.35;
const float y_turn_2 = 0.65;

float get_bolt_seam_x(float y) {
	// Start at the center
	float center_x = 0.5;
	float offset = 0.0;

	// Section 1: Top part, zig-zag RIGHT
	if (y < y_turn_1) {
		// Map y from range [0.0, y_turn_1] to [0.0, 1.0]
		float rel_y = y / y_turn_1;
		// Move from center (0.0) to right (+bolt_width)
		offset = mix(0.0, bolt_width, rel_y);
	}
	// Section 2: Middle part, zig-zag sharp LEFT
	else if (y < y_turn_2) {
		// Map y from range [y_turn_1, y_turn_2] to [0.0, 1.0]
		float rel_y = (y - y_turn_1) / (y_turn_2 - y_turn_1);
		// Move from right (+bolt_width) to left (-bolt_width)
		offset = mix(bolt_width, -bolt_width, rel_y);
	}
	// Section 3: Bottom part, zig-zag back towards CENTER/RIGHT tip
	else {
		// Map y from range [y_turn_2, 1.0] to [0.0, 1.0]
		float rel_y = (y - y_turn_2) / (1.0 - y_turn_2);
		// Move from left (-bolt_width) to slightly right of center (bolt_width * 0.5)
		offset = mix(-bolt_width, bolt_width * 0.5, rel_y);
	}

	return center_x + offset;
}

void fragment() {
	// 1. Calculate the clean seam position for the current Y
	float seam_x = get_bolt_seam_x(UV.y);

	// 2. Calculate separation amount based on progress
	// Taper: Full separation at top (y=0), zero at bottom (y=1)
	float current_separation = max_separation * crack_progress * (1.0 - UV.y);

	vec2 sample_uv = UV;
	float alpha_mask = 1.0;

	// 3. Split Logic
	// Are we on the left side of the calculated seam?
	if (UV.x < seam_x) {
		// Pull texture from the right
		sample_uv.x += current_separation;

		// Check if we pulled past the seam (creating the gap)
		// We must check against the seam position at the NEW sampled Y
		// (Though for vertical bolts, sample_uv.y is mostly same as UV.y)
		float seam_at_sample = get_bolt_seam_x(sample_uv.y);
		if (sample_uv.x > seam_at_sample) {
			alpha_mask = 0.0;
		}
	}
	// Are we on the right side?
	else {
		// Pull texture from the left
		sample_uv.x -= current_separation;

		float seam_at_sample = get_bolt_seam_x(sample_uv.y);
		if (sample_uv.x < seam_at_sample) {
			alpha_mask = 0.0;
		}
	}

	// 4. Sample and Apply
	vec4 color = texture(TEXTURE, sample_uv);
	// Apply the gap
	color.a = min(color.a, alpha_mask);

	// 5. Desaturation
	float grey = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	color.rgb = mix(color.rgb, vec3(grey), crack_progress);

	COLOR = color;
}