// [Reference Code]
//
// float random(in float2 _st)
// {
//     return frac(sin(dot(_st.xy, float2(12.9898, 78.233))) * 43758.5453123);
// }
//
// float noise(in float2 uv)
// {
//     float2 i = floor(uv);
//     float2 f = frac(uv);
//
//     // Four corners in 2D of a tile
//     float a = random(i);
//     float b = random(i + float2(1.0, 0.0));
//     float c = random(i + float2(0.0, 1.0));
//     float d = random(i + float2(1.0, 1.0));
//
//     float2 u = f * f * (3.0 - 2.0 * f);
//
//     return lerp(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
// }
//
// #define NUM_OCTAVES 5
//
// float fbm(float2 uv)
// {
//     float v = 0.0;
//     float a = 0.5;
//     const float2 shift = float2(100.0, 100.0);
//
//     // Rotate to reduce axial bias
//     const float2x2 rot = float2x2(cos(.5), sin(.5),
//                                   -sin(.5), cos(.5));
//
//     for (int i = 0; i < NUM_OCTAVES; ++i)
//     {
//         v += a * noise(uv);
//         uv = mul(uv, rot) * 2.0 + shift;
//         a *= 0.5;
//     }
//
//     return v;
// }

#include "Assets/Shaders/fbm.hlsl"

float _ParallaxStrength;
float _CloudTime;

float CloudNoise(float2 uv)
{
    const float2 q = float2(fbm(uv + _CloudTime * .01), fbm(uv) + 1.);

    const float2 r = float2(
        fbm(uv + 1.0 * q + float2(1.7, 9.2) + 0.15 * _CloudTime),
        fbm(uv + 1.0 * q + float2(8.3, 2.8) + 0.126 * _CloudTime)
    );

    return fbm(uv + r);
}

float2 ParallaxOffset(float2 uv, float2 viewDir)
{
    float height = CloudNoise(uv);
    height -= 0.5;
    height *= _ParallaxStrength;
    return viewDir * height;
}

#define PARALLAX_FUNCTION ParallaxRaymarching
float2 ParallaxRaymarching(float2 uv, float2 viewDir)
{
    float2 uvOffset = 0;
    float stepSize = 0.1;
    float2 uvDelta = viewDir * (stepSize * _ParallaxStrength);

    float stepHeight = 1;
    float surfaceHeight = CloudNoise(uv);

    float2 prevUVOffset = uvOffset;
    float prevStepHeight = stepHeight;
    float prevSurfaceHeight = surfaceHeight;

    for (int i = 1; i < 10 && stepHeight > surfaceHeight; i++)
    {
        prevUVOffset = uvOffset;
        prevStepHeight = stepHeight;
        prevSurfaceHeight = surfaceHeight;

        uvOffset -= uvDelta;
        stepHeight -= stepSize;
        surfaceHeight = CloudNoise(uv + uvOffset);
    }

    const float prevDifference = prevStepHeight - prevSurfaceHeight;
    const float difference = surfaceHeight - stepHeight;
    const float t = prevDifference / (prevDifference + difference);
    uvOffset = prevUVOffset - uvDelta * t;

    return uvOffset;
}

float ParallaxCloudNoise(float3 tangentViewDir, float2 uv, out float2 uv2)
{
    tangentViewDir = normalize(tangentViewDir);
    tangentViewDir.xy = tangentViewDir.xy / (tangentViewDir.z + 0.42);

    #if !defined(PARALLAX_FUNCTION)
    #define PARALLAX_FUNCTION ParallaxOffset
    #endif

    float2 uvOffset = PARALLAX_FUNCTION(uv, tangentViewDir);
    uv.xy += uvOffset;

	uv2 = uv.xy;
    return CloudNoise(uv);
}

void FBM_float(float2 uv, out float value)
{
    value = fbm(uv);
}

void CloudNoise_float(float2 uv, float time, out float value)
{
    _CloudTime = time;
    value = CloudNoise(uv);
}

void ParallaxCloudNoise_float(float3 viewDir, float parallaxStrength, float2 uv, float time, out float height, out float2 uv2)
{
    _CloudTime = time;
    _ParallaxStrength = -parallaxStrength;
    height = ParallaxCloudNoise(viewDir, uv, uv2);
}
