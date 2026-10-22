import bevy_pbr::render::forward_io::VertexOutput;
import bevy_pbr::render::mesh_view_bindings::{globals, view};
@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    // 1. Get the 3D normal of the sphere. This gives us a perfect 360-degree 
    // coordinate system without the pinching/seams of UVs.
    let normal = normalize(in.world_normal);

    // 2. Calculate the angle around the Y (up) axis.
    // atan2(y, x) gives us an angle from -PI to PI.
    let angle = atan2(normal.z, normal.x);

    // 3. Create the Starburst Rays
    // Higher number = more rays. (e.g., 16.0, 24.0, 32.0)
    let ray_count = 24.0;

    // Create a repeating pattern based on the angle
    let raw_ray = abs(sin(angle * ray_count * 0.5));

    // Make the rays sharp and needle-like. 
    // Higher power = thinner spikes. (e.g., 20.0 to 50.0)
    let sharp_ray = pow(raw_ray, 30.0);

    // 4. Add Radial Falloff (so the tips of the sphere are dark)
    // The normal's Y component is 1.0 at the top, -1.0 at the bottom, 0.0 at the equator.
    // This keeps the rays concentrated around the "equator" of the sphere.
    let equator_focus = 1.0 - abs(normal.y);
    let falloff = pow(equator_focus, 2.0);

    // 5. Pulsating Effect
    let pulse_speed = 5.0;
    let pulse = sin(globals.time * pulse_speed) * 0.5 + 0.5;

    // Add a fast flicker for the "spark" effect
    let flicker = sin(globals.time * 40.0) * 0.2 + 0.8;

    // 6. Combine the light intensity
    let intensity = sharp_ray * falloff * (pulse * flicker);

    // 7. Colors
    // Core is white-hot, rays fade to bright orange/gold.
    let core_color = vec3<f32>(1.0, 1.0, 0.8);
    let ray_color = vec3<f32>(1.0, 0.5, 0.0);

    // Mix colors based on the ray sharpness (the brighter the ray, the whiter it is)
    let mixed_color = mix(ray_color, core_color, sharp_ray);

    // Multiply by intensity to make it glow. 
    // We multiply by a large number (e.g., 5.0) to blow out the color and make it look like a bright light.
    let final_color = mixed_color * intensity * 5.0;

    // Add a glowing core in the dead center of the sphere
    // (The view direction tells us what we are looking at directly)
    let view_dir = normalize(view.world_position - in.world_position.xyz);

    let dot_product = dot(normalize(in.world_normal), view_dir);
    let center_core = pow(max(dot_product, 0.0), 10.0) * (pulse + 0.5);
    let core_glow = vec3<f32>(1.0, 0.8, 0.5) * center_core * 2.0;

    // Final output
    return vec4<f32>(final_color + core_glow, 1.0);
}
