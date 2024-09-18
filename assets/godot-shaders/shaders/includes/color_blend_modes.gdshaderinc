/*

From : https://godotshaders.com/snippet/blending-modes/

Blending modes functions
Multiply     a * b
Screen       1 - (1 - a) * (1 - b)
Darken       min(a, b)
Lighten      max(a, b)
Difference   abs(a - b)
Exclusion    a + b - 2 * a * b
Overlay      a < 0.5 ? (2.0 * a * b) : (1.0 - 2.0 * (1.0 - a) * (1.0 - b))
Hard light   b < 0.5 ? (2.0 * a * b) : (1.0 - 2.0 * (1.0 - a) * (1.0 - b))
Soft light   b < 0.5 ? (2.0 * a * b + a * a * (1.0 - 2.0 * b)) : (sqrt(a) * (2.0 * b - 1.0) + (2.0 * a) * (1.0 - b))
Color dodge  a / (1.0 - b)
Linear dodge a + b
Burn         1.0 - (1 - a) / b
Linear burn  a + b - 1.0

*/

//	Multiply
vec4 multiply(vec4 base, vec4 blend){
	return base * blend;
}

//	Screen
vec4 screen(vec4 base, vec4 blend){
	return 1.0 - (1.0 - base) * (1.0 - blend);
}

//	Darken
vec4 darken(vec4 base, vec4 blend){
	return min(base, blend);
}

//	Lighten
vec4 lighten(vec4 base, vec4 blend){
	return max(base, blend);
}

//	Difference
vec4 difference(vec4 base, vec4 blend){
	return abs(base - blend);
}

//	Exclusion
vec4 exclusion(vec4 base, vec4 blend){
	return base + blend - 2.0 * base * blend;
}

//	Overlay
vec4 overlay(vec4 base, vec4 blend){
	vec4 limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}

//	Hard light
vec4 hard_light(vec4 base, vec4 blend){
	vec4 limit = step(0.5, blend);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}

//	Soft light
vec4 soft_light(vec4 base, vec4 blend){
	vec4 limit = step(0.5, blend);
	return mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend), sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend), limit);
}

//	Color dodge
vec4 color_dodge(vec4 base, vec4 blend){
	return base / (1.0 - blend);
}

//	Linear dodge
vec4 linear_dodge(vec4 base, vec4 blend){
	return base + blend;
}

//	Color burn
vec4 color_burn(vec4 base, vec4 blend){
	return 1.0 - (1.0 - base) / blend;
}

//	Linear burn
vec4 linear_burn (vec4 base, vec4 blend){
	return base + blend - 1.0;
}
