uniform float u_exposure;
uniform vec3 u_white_point;
uniform float u_vignette;
uniform float u_rgbm_mul;
uniform int u_potato;
uniform bool u_yolo_glow;

vec3 Tonemap_ACES(vec3 x) {
	float a = 2.51;
	float b = 0.03;
	float c = 2.43;
	float d = 0.59;
	float e = 0.14;
	return clamp((x*(a*x+b))/(x*(c*x+d)+e), 0.0, 1.0);
}

float vignette(vec2 uv) {
	vec2	center = vec2(0.5, 0.5);
	float distance_from_center = distance(uv, center);
	float power = 1.7;
	float offset = 2.75;
	return 1.0 - pow((distance_from_center*2.0) / (center.x * offset), power);
}

// Sigmoid function, sign(v)*pow(pow(abs(v), -2) + pow(s, -2), 1.0/-2)
#define soft_lim(v,s)	( (v*s)*(1.0/sqrt(s*s + v*v)) )

// Weighted power mean, p = 0.5
#define wpmean(a,b,w)	(pow(abs(w)*sqrt(abs(a)) + abs(1.0-w)*sqrt(abs(b)), vec3(2.0)))

// Max/Min RGB components
#define max3(RGB) ( max((RGB).r, max((RGB).g, (RGB).b)) )
#define min3(RGB) ( min((RGB).r, min((RGB).g, (RGB).b)) )

// Mean of Rec. 709 & 601 luma coefficients
// const vec3 luma = vec3(0.2558, 0.6511, 0.0931);
const vec3 luma = vec3(0.212656, 0.715158, 0.072186);

vec3 vibrance(vec3 c0, float saturation, float lim_luma) {
	float luma = sqrt(dot(clamp(c0*abs(c0), 0.0, 1.0), luma));
	c0 = clamp(c0, 0.0, 1.0);

	// Calc colour saturation change
	vec3 diff_luma = c0 - luma;
	vec3 c_diff = diff_luma*(saturation + 1.0) - diff_luma;

	// 120% of c_diff clamped to max visible range + overshoot
	vec3 rlc_diff = clamp((c_diff*1.2) + c0, -0.0001, 1.0001) - c0;

	// Calc max saturation-increase without altering RGB ratios
	float poslim = (1.0002 - luma)/(abs(max3(diff_luma)) + 0.0001);
	float neglim = (luma + 0.0002)/(abs(min3(diff_luma)) + 0.0001);

	vec3 diffmax = diff_luma*min(min(poslim, neglim), 32.0) - diff_luma;

	// Soft limit diff
	c_diff = soft_lim( c_diff, max(wpmean(diffmax, rlc_diff, lim_luma), 1.0e-6) );

	return clamp(c0 + c_diff, 0.0, 1.0);
}

vec3 rgbe8_decode(vec4 _rgbe8)
{
	float exponent = _rgbe8.w * 255.0 - 128.0;
	vec3 rgb = _rgbe8.xyz * exp2(exponent);
	return rgb;
}

#ifdef GL_ES
#	define USE_RGBE 1
#endif

#define POTATO_MODE
#ifdef POTATO_MODE
float dither8x8(vec2 position, float brightness) {
	int x = int(mod(position.x, 8.0));
	int y = int(mod(position.y, 8.0));
	int index = x + y * 8;
	float limit = 0.0;

	if (x < 8) {
		if (index == 0) limit = 0.015625;
		if (index == 1) limit = 0.515625;
		if (index == 2) limit = 0.140625;
		if (index == 3) limit = 0.640625;
		if (index == 4) limit = 0.046875;
		if (index == 5) limit = 0.546875;
		if (index == 6) limit = 0.171875;
		if (index == 7) limit = 0.671875;
		if (index == 8) limit = 0.765625;
		if (index == 9) limit = 0.265625;
		if (index == 10) limit = 0.890625;
		if (index == 11) limit = 0.390625;
		if (index == 12) limit = 0.796875;
		if (index == 13) limit = 0.296875;
		if (index == 14) limit = 0.921875;
		if (index == 15) limit = 0.421875;
		if (index == 16) limit = 0.203125;
		if (index == 17) limit = 0.703125;
		if (index == 18) limit = 0.078125;
		if (index == 19) limit = 0.578125;
		if (index == 20) limit = 0.234375;
		if (index == 21) limit = 0.734375;
		if (index == 22) limit = 0.109375;
		if (index == 23) limit = 0.609375;
		if (index == 24) limit = 0.953125;
		if (index == 25) limit = 0.453125;
		if (index == 26) limit = 0.828125;
		if (index == 27) limit = 0.328125;
		if (index == 28) limit = 0.984375;
		if (index == 29) limit = 0.484375;
		if (index == 30) limit = 0.859375;
		if (index == 31) limit = 0.359375;
		if (index == 32) limit = 0.0625;
		if (index == 33) limit = 0.5625;
		if (index == 34) limit = 0.1875;
		if (index == 35) limit = 0.6875;
		if (index == 36) limit = 0.03125;
		if (index == 37) limit = 0.53125;
		if (index == 38) limit = 0.15625;
		if (index == 39) limit = 0.65625;
		if (index == 40) limit = 0.8125;
		if (index == 41) limit = 0.3125;
		if (index == 42) limit = 0.9375;
		if (index == 43) limit = 0.4375;
		if (index == 44) limit = 0.78125;
		if (index == 45) limit = 0.28125;
		if (index == 46) limit = 0.90625;
		if (index == 47) limit = 0.40625;
		if (index == 48) limit = 0.25;
		if (index == 49) limit = 0.75;
		if (index == 50) limit = 0.125;
		if (index == 51) limit = 0.625;
		if (index == 52) limit = 0.21875;
		if (index == 53) limit = 0.71875;
		if (index == 54) limit = 0.09375;
		if (index == 55) limit = 0.59375;
		if (index == 56) limit = 1.0;
		if (index == 57) limit = 0.5;
		if (index == 58) limit = 0.875;
		if (index == 59) limit = 0.375;
		if (index == 60) limit = 0.96875;
		if (index == 61) limit = 0.46875;
		if (index == 62) limit = 0.84375;
		if (index == 63) limit = 0.34375;
	}

	return brightness < limit ? 0.0 : 1.0;
}

vec3 dither8x8(vec2 position, vec3 color) {
	return color * dither8x8(position, dot(luma, color));
}

vec4 dither8x8(vec2 position, vec4 color) {
	return vec4(color.rgb * dither8x8(position, dot(luma, color.rgb)), 1.0);
}
#endif

vec4 blur5(sampler2D image, vec2 uv, float lod, vec2 direction) {
	vec4 color = vec4(0.0);
	vec2 off1 = vec2(1.3333333333333333) * direction;
	vec2 resolution = love_ScreenSize.xy;
	for (int i = 0; i < int(lod); i++) {
		resolution.xy *= 0.5;
	}
	color += Texel(image, uv, lod) * 0.29411764705882354;
	color += Texel(image, uv + (off1 / resolution), lod) * 0.35294117647058826;
	color += Texel(image, uv - (off1 / resolution), lod) * 0.35294117647058826;
	return color; 
}

vec4 blur9(sampler2D image, vec2 uv, float lod, vec2 direction) {
	vec4 color = vec4(0.0);
	vec2 off1 = vec2(1.3846153846) * direction;
	vec2 off2 = vec2(3.2307692308) * direction;
	vec2 resolution = love_ScreenSize.xy;
	for (int i = 0; i < int(lod); i++) {
		resolution.xy *= 0.5;
	}
	color += Texel(image, uv, lod) * 0.2270270270;
	color += Texel(image, uv + (off1 / resolution), lod) * 0.3162162162;
	color += Texel(image, uv - (off1 / resolution), lod) * 0.3162162162;
	color += Texel(image, uv + (off2 / resolution), lod) * 0.0702702703;
	color += Texel(image, uv - (off2 / resolution), lod) * 0.0702702703;
	return color;
}

vec4 blur(sampler2D image, vec2 uv, float lod, float blur_size) {
	// return blur9(image, uv, lod, vec2(blur_size, 0.0)) + blur9(image, uv, lod, vec2(0.0, blur_size));
	return blur5(image, uv, lod, vec2(blur_size, 0.0)) + blur5(image, uv, lod, vec2(0.0, blur_size));
}

vec4 effect(vec4 vcol, Image texture, vec2 texture_coords, vec2 sc) {
	vec2 uv = vec2(texture_coords.x, 1.0-texture_coords.y);
	vec4 texColorM = Texel(texture, uv, 0.0);

	if (u_yolo_glow) {
		float blur_size = 1.0;
		vec4 texColorM1 = blur(texture, uv, 0.5, blur_size);
		vec4 texColorM2 = blur(texture, uv, 1.5, blur_size);
		// vec4 texColorM3 = blur(texture, uv, 1.5, blur_size*2.0);

		vec4 fuzzy = texColorM + texColorM1 * 0.75 + texColorM2 * 0.25;// + texColorM3 * 0.125;
		fuzzy /= 2.0;

		texColorM = mix(texColorM, fuzzy, 0.20);
	}

#ifdef USE_RGBE
	vec3 texColor = rgbe8_decode(texColorM);

#	ifndef LOVE_GAMMA_CORRECT
	texColor = linearToGammaFast(color);
#	endif

	texColor = pow(texColor, vec3(u_rgbm_mul));
#else
	vec3 texColor = texColorM.rgb;
#	ifndef GL_ES
	// encoding color this way reduces banding on rg11b10f/rgb10a2
	texColor = sqrt(texColor);
#	endif
#endif
	// texColor *= texColor;

	texColor *= exp2(u_exposure);
	texColor *= min(1.0, vignette(texture_coords) + (1.0-u_vignette));

	// vec3 color = texColor;

	vec3 white = Tonemap_ACES(vec3(1000.0));
	vec3 white_point = u_white_point;
	// white_point.r *= 1.5;
	vec3 color = Tonemap_ACES(texColor/white_point)*white;

	// bump up final saturation...
	color = vibrance(color, 0.3, 0.65);
	// color = vibrance(color, 0.2, 0.65);

#ifdef USE_RGBE
	color *= 1.2;
#endif

#ifdef POTATO_MODE
	if (u_potato == 1) {
		color = mix(color, dither8x8(love_PixelCoord * 0.25, color), 0.10);
	}
#endif

	return vec4(color, 1.0);
}
