shader_type canvas_item;

uniform float skew = 0.;
uniform sampler2D noise_tex;
uniform float wind_speed = 1.0;
//uniform float time = 0.0; // 已由内置TIME变量实现

vec2 swing(float strength, vec2 uv){
	vec2 xy = vec2(uv.x, 1.0 - uv.y);
	vec2 displaced_xy = vec2(uv.x + (xy.y * xy.y) * strength * .1, uv.y);
	return displaced_xy;
}

void vertex() {
	// 仅传递基础UV坐标
}

void fragment() {
	// swing(wind_speed);
	// swing(skew);
	vec2 uv = mix(swing(wind_speed * 3. * sin(TIME * wind_speed) * texture(noise_tex, vec2(TIME/1234., TIME/2345.)).r, UV),  swing(skew, UV), .5);
	COLOR = texture(TEXTURE, uv);
	//COLOR = texture(TEXTURE, vec2(sin(TIME), UV.y));
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
