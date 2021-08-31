float random(in float2 _st)
{
    return frac(sin(dot(_st.xy, float2(12.9898, 78.233))) * 43758.5453123);
}

float noise(in float2 uv)
{
    float2 i = floor(uv);
    float2 f = frac(uv);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + float2(1.0, 0.0));
    float c = random(i + float2(0.0, 1.0));
    float d = random(i + float2(1.0, 1.0));

    float2 u = f * f * (3.0 - 2.0 * f);

    return lerp(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

#define NUM_OCTAVES 5

float fbm(float2 uv)
{
    float v = 0.0;
    float a = 0.5;
    const float2 shift = float2(100.0, 100.0);

    // Rotate to reduce axial bias
    const float2x2 rot = float2x2(cos(.5), sin(.5),
                                  -sin(.5), cos(.5));

    for (int i = 0; i < NUM_OCTAVES; ++i)
    {
        v += a * noise(uv);
        uv = mul(uv, rot) * 2.0 + shift;
        a *= 0.5;
    }

    return v;
}