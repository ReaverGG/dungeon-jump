shader_type canvas_item;

// --- TINT SETTINGS ---
group_uniforms Tint_Settings;
// The color you want to tint the sprite (e.g., Red for damage, White for flash)
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// How strong the tint is. 0.0 = Original Sprite, 1.0 = Fully Tinted
uniform float tint_amount : hint_range(0.0, 1.0) = 0.0;

// --- GLOW SETTINGS ---
group_uniforms Glow_Settings;
// The color of the glow light
uniform vec4 glow_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
// Strength of the glow. Values > 1.0 will trigger HDR Bloom in WorldEnvironment
uniform float glow_intensity : hint_range(0.0, 5.0) = 0.0;
// Make the glow pulse automatically (Optional)
uniform float pulse_speed : hint_range(0.0, 10.0) = 0.0;

void fragment() {
	// 1. Get the original sprite color
	vec4 original_color = texture(TEXTURE, UV);

	// 2. Apply Tint
	// We mix the original color with the tint color based on the tint_amount
	// We multiply by original_color.a so we don't tint the transparent background
	vec3 tinted_rgb = mix(original_color.rgb, tint_color.rgb, tint_amount);

	// 3. Calculate Glow
	// If pulse_speed is greater than 0, we calculate a sine wave factor
	float pulse = 1.0;
	if (pulse_speed > 0.0) {
		pulse = (sin(TIME * pulse_speed) + 1.0) * 0.5; // Oscillates between 0.0 and 1.0
	}

	// Calculate final glow vector
	vec3 glow_rgb = glow_color.rgb * glow_intensity * pulse;

	// 4. Combine
	// Add the glow to the tinted sprite.
	// We maintain the original alpha channel so the shape of the sprite doesn't change.
	COLOR = vec4(tinted_rgb + glow_rgb, original_color.a);
}