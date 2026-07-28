#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_progress;
uniform float u_fade_in;
uniform float u_score;

out vec4 fragColor;

float hash(vec2 p) {
  p = fract(p * vec2(5.3983, 5.4427));
  p += dot(p, p + 3.5453123);
  return fract(p.x * p.y);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);

  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));

  vec2 u = f * f * (3.0 - 2.0 * f);

  return mix(a, b, u.x)
       + (c - a) * u.y * (1.0 - u.x)
       + (d - b) * u.x * u.y;
}

void main() {
  float maxNoiseStrength = 0.12;
  float baseRadius = 0.45;
  float edgeThickness = 0.20;

  float noiseStrength = mix(maxNoiseStrength, maxNoiseStrength * 0.1, u_progress);

  vec2 uv = FlutterFragCoord().xy / u_resolution;
  vec2 pos = uv - vec2(0.5);
  pos.x *= u_resolution.x / u_resolution.y;

  float r = length(pos);
  float n = noise(pos * 3.5 + u_time * 0.3);
  float bubbleRadius = baseRadius - noiseStrength * n;

  float edge = smoothstep(bubbleRadius - edgeThickness, bubbleRadius, r);
  float aa = 4.0 / u_resolution.y;
  float circleMask = smoothstep(bubbleRadius, bubbleRadius - aa, r);

  vec3 blueColor = vec3(0.1255, 0.4471, 0.8784);
  vec3 grayColor = vec3(0.3, 0.31, 0.37);

  float colorT = smoothstep(0.45, 0.55, u_score / 100.0);
  vec3 edgeColor = mix(grayColor, blueColor, colorT);

  edgeColor = mix(vec3(0.3, 0.31, 0.37), edgeColor, smoothstep(0.0, 0.05, u_fade_in));

  vec3 color = edgeColor * edge * circleMask;
  float alpha = edge * circleMask;

  fragColor = vec4(color, alpha);
}
