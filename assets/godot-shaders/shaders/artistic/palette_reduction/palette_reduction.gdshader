shader_type spatial;

render_mode unshaded, fog_disabled;

uniform sampler2D palette_texture : filter_nearest, repeat_disable; // Your 1-pixel tall palette image

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest;

uniform float HUE_WEIGHT : hint_range(0.0, 10.0, 0.01) = 1.0;
uniform float SATURATION_WEIGHT : hint_range(0.0, 10.0, 0.01) = 1.0;
uniform float VALUE_WEIGHT : hint_range(0.0, 10.0, 0.01) = 1.0;



void vertex() {
	//POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

// Converts an RGB color to HSV.
vec3 rgb2hsv(vec3 c) {
    float cMax = max(max(c.r, c.g), c.b);
    float cMin = min(min(c.r, c.g), c.b);
    float delta = cMax - cMin;

    float h = 0.0;
    if(delta < 0.00001) {
        h = 0.0;
    } else if(cMax == c.r) {
        h = mod(((c.g - c.b) / delta), 6.0);
    } else if(cMax == c.g) {
        h = ((c.b - c.r) / delta) + 2.0;
    } else {
        h = ((c.r - c.g) / delta) + 4.0;
    }
    h /= 6.0;
    if(h < 0.0) h += 1.0;

    float s = (cMax <= 0.0) ? 0.0 : (delta / cMax);
    float v = cMax;
    return vec3(h, s, v);
}

// Converts an HSV color back to RGB.
vec3 hsv2rgb(vec3 c) {
    float h = c.x * 6.0;
    float s = c.y;
    float v = c.z;

    float c_val = v * s;
    float x = c_val * (1.0 - abs(mod(h, 2.0) - 1.0));
    vec3 rgb;

    if (0.0 <= h && h < 1.0) {
        rgb = vec3(c_val, x, 0.0);
    } else if (1.0 <= h && h < 2.0) {
        rgb = vec3(x, c_val, 0.0);
    } else if (2.0 <= h && h < 3.0) {
        rgb = vec3(0.0, c_val, x);
    } else if (3.0 <= h && h < 4.0) {
        rgb = vec3(0.0, x, c_val);
    } else if (4.0 <= h && h < 5.0) {
        rgb = vec3(x, 0.0, c_val);
    } else if (5.0 <= h && h < 6.0) {
        rgb = vec3(c_val, 0.0, x);
    } else {
        rgb = vec3(0.0, 0.0, 0.0);
    }
    float m = v - c_val;
    return rgb + vec3(m);
}

float hue_distance(float h1, float h2) {
    float d = abs(h1 - h2);
    return min(d, 1.0 - d); // Assuming hue values are normalized between 0 and 1
}

float saturation_distance(float s1, float s2) {
    return abs(s1 - s2);
}

float value_distance(float v1, float v2) {
    return abs(v1 - v2);
}

float get_color_distance_weighted(vec3 color1, vec3 color2) {
	// Example of weighted distance (adjust weights as needed)
    vec3 color1_weighted = color1 * vec3(0.299, 0.587, 0.114); // Common luminance weights
    vec3 color2_weighted = color2 * vec3(0.299, 0.587, 0.114);
    return distance(color1_weighted, color2_weighted);
}

void fragment() {

	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV); // Or texture(TEXTURE, UV) for a sprite

    vec4 closest_palette_color = vec4(0.0);
    float min_distance = 100000.0; // A large initial value

    // Assuming palette_texture is 1 pixel tall and its width is the number of colors
    float palette_width = float(textureSize(palette_texture, 0).x);

	vec4 palette_color;
	float current_distance;
    for (float i = 0.0; i < palette_width; i += 1.0) {
        palette_color = texture(palette_texture, vec2(i / palette_width, 0.5));
        current_distance = distance(screen_color.rgb, palette_color.rgb);
		//current_distance = length(screen_color.rgb - palette_color.rgb);
        //current_distance = get_color_distance_weighted(screen_color.rgb, palette_color.rgb);

		vec3 screen_color_hsv = rgb2hsv(screen_color.rgb);
		vec3 palette_color_hsv = rgb2hsv(palette_color.rgb);

		float h_dist = hue_distance(screen_color_hsv.x, palette_color_hsv.x);
	    float s_dist = saturation_distance(screen_color_hsv.y, palette_color_hsv.y);
	    float v_dist = value_distance(screen_color_hsv.z, palette_color_hsv.z);


		current_distance = (h_dist * HUE_WEIGHT) + (s_dist * SATURATION_WEIGHT) + (v_dist * VALUE_WEIGHT);
		//current_distance = abs(screen_color_hsv.r - palette_color_hsv.r);
		//current_distance = min(current_distance, 1.0 - current_distance);

		if (current_distance < min_distance) {
            min_distance = current_distance;
            closest_palette_color = palette_color;
        }
    }

    ALBEDO = closest_palette_color.rgb;

}

