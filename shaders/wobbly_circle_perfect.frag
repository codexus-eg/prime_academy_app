#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform float u_time;

out vec4 fragColor;

void main() {
  float baseRadius = 0.45;
  float edgeThickness = 0.38;

  vec2 uv = FlutterFragCoord().xy / u_resolution;
  vec2 pos = uv - vec2(0.5);
  pos.x *= u_resolution.x / u_resolution.y;

  float r = length(pos);
  float edge = smoothstep(baseRadius - edgeThickness, baseRadius, r);
  float aa = 4.0 / u_resolution.y;
  float circleMask = smoothstep(baseRadius, baseRadius - aa, r);

  vec3 edgeColor = vec3(0.1255, 0.4471, 0.8784);

  vec3 color = edgeColor * edge * circleMask;
  float alpha = edge * circleMask;

  fragColor = vec4(color, alpha);
}
