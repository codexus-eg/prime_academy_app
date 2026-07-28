// Copied from prime_academy-main/client/src/components/course/lesson/WobblyCircle.tsx
(function () {
  const VERTEX_SHADER = `
attribute vec4 position;
void main() {
  gl_Position = position;
}
`;

  const FRAGMENT_SHADER_WOBBLE = `
precision highp float;

uniform vec2  u_resolution;
uniform float u_time;
uniform float u_progress;
uniform float u_fade_in;
uniform float u_score;

float hash(vec2 p){
  p = fract(p * vec2(5.3983, 5.4427));
  p += dot(p, p + 3.5453123);
  return fract(p.x * p.y);
}

float noise(vec2 p){
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

void main(){
  float maxNoiseStrength = 0.12;
  float baseRadius       = 0.45;
  float edgeThickness    = 0.20;

  float noiseStrength = mix(maxNoiseStrength, maxNoiseStrength * 0.1, u_progress);

  vec2 uv  = gl_FragCoord.xy / u_resolution.xy;
  vec2 pos = uv - vec2(0.5);
  pos.x   *= u_resolution.x / u_resolution.y;

  float r            = length(pos);
  float n            = noise(pos * 3.5 + u_time * 0.3);
  float bubbleRadius = baseRadius - noiseStrength * n;

  float edge       = smoothstep(bubbleRadius - edgeThickness, bubbleRadius, r);
  float aa         = 4.0 / u_resolution.y;
  float circleMask = smoothstep(bubbleRadius, bubbleRadius - aa, r);

  vec3 blueColor = vec3(0.1255, 0.4471, 0.8784);
  vec3 grayColor = vec3(0.3,    0.31,   0.37   );

  float colorT   = smoothstep(0.45, 0.55, u_score / 100.0);
  vec3 edgeColor = mix(grayColor, blueColor, colorT);

  edgeColor = mix(vec3(0.3, 0.31, 0.37), edgeColor, smoothstep(0.0, 0.05, u_fade_in));

  vec3  color = edgeColor * edge * circleMask;
  float alpha = edge * circleMask;

  gl_FragColor = vec4(color, alpha);
}
`;

  const FRAGMENT_SHADER_PERFECT = `
precision highp float;

uniform vec2  u_resolution;
uniform float u_time;

void main(){
  float baseRadius    = 0.45;
  float edgeThickness = 0.38;

  vec2 uv  = gl_FragCoord.xy / u_resolution.xy;
  vec2 pos = uv - vec2(0.5);
  pos.x   *= u_resolution.x / u_resolution.y;

  float r          = length(pos);
  float edge       = smoothstep(baseRadius - edgeThickness, baseRadius, r);
  float aa         = 4.0 / u_resolution.y;
  float circleMask = smoothstep(baseRadius, baseRadius - aa, r);

  vec3 edgeColor = vec3(0.1255, 0.4471, 0.8784);

  gl_FragColor = vec4(edgeColor * edge * circleMask, edge * circleMask);
}
`;

  function createShader(gl, type, source) {
    const shader = gl.createShader(type);
    if (!shader) return null;
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      console.error(gl.getShaderInfoLog(shader));
      gl.deleteShader(shader);
      return null;
    }
    return shader;
  }

  function createProgram(gl, vertSrc, fragSrc) {
    const vert = createShader(gl, gl.VERTEX_SHADER, vertSrc);
    const frag = createShader(gl, gl.FRAGMENT_SHADER, fragSrc);
    if (!vert || !frag) return null;

    const program = gl.createProgram();
    if (!program) return null;

    gl.attachShader(program, vert);
    gl.attachShader(program, frag);
    gl.linkProgram(program);
    return program;
  }

  const instances = new WeakMap();

  function unmount(canvas) {
    const inst = instances.get(canvas);
    if (!inst) return;
    if (inst.animId) cancelAnimationFrame(inst.animId);
    instances.delete(canvas);
  }

  function mount(canvas, options) {
    unmount(canvas);

    const size = options.size;
    const staticWobble = !!options.staticWobble;
    const isPerfect = !!options.isPerfect;
    const scoreRef = { current: options.score ?? 10 };

    const DPR = window.devicePixelRatio || 1;
    canvas.width = size * DPR;
    canvas.height = size * DPR;
    canvas.style.width = size + 'px';
    canvas.style.height = size + 'px';

    const gl = canvas.getContext('webgl', {
      alpha: true,
      premultipliedAlpha: false,
    });
    if (!gl) return;

    const program = createProgram(
      gl,
      VERTEX_SHADER,
      isPerfect ? FRAGMENT_SHADER_PERFECT : FRAGMENT_SHADER_WOBBLE
    );
    if (!program) return;

    const positions = new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]);
    const buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(gl.ARRAY_BUFFER, positions, gl.STATIC_DRAW);

    const posAttr = gl.getAttribLocation(program, 'position');
    gl.enableVertexAttribArray(posAttr);
    gl.vertexAttribPointer(posAttr, 2, gl.FLOAT, false, 0, 0);

    const uResolution = gl.getUniformLocation(program, 'u_resolution');
    const uTime = gl.getUniformLocation(program, 'u_time');
    const uProgress = isPerfect
      ? null
      : gl.getUniformLocation(program, 'u_progress');
    const uFadeIn = isPerfect
      ? null
      : gl.getUniformLocation(program, 'u_fade_in');
    const uScore = isPerfect ? null : gl.getUniformLocation(program, 'u_score');

    gl.useProgram(program);
    gl.enable(gl.BLEND);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    const startTime = performance.now();
    let animId = 0;

    function render() {
      const elapsed = (performance.now() - startTime) / 1000;
      const currentScore = scoreRef.current;

      gl.viewport(0, 0, size * DPR, size * DPR);
      gl.clearColor(0, 0, 0, 0);
      gl.clear(gl.COLOR_BUFFER_BIT);

      gl.uniform2f(uResolution, size * DPR, size * DPR);
      gl.uniform1f(uTime, elapsed);

      if (uProgress) {
        gl.uniform1f(uProgress, staticWobble ? 0 : currentScore / 100);
      }
      if (uFadeIn) {
        gl.uniform1f(uFadeIn, 1.0);
      }
      if (uScore) {
        gl.uniform1f(uScore, currentScore);
      }

      gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
      animId = requestAnimationFrame(render);
    }

    render();

    instances.set(canvas, { animId, scoreRef, size, staticWobble, isPerfect });
  }

  function updateScore(canvas, score) {
    const inst = instances.get(canvas);
    if (inst) inst.scoreRef.current = score;
  }

  function remount(canvas, options) {
    mount(canvas, options);
  }

  window.PrimeWobblyCircle = { mount, unmount, updateScore, remount };
})();
