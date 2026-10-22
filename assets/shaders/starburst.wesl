import bevy_pbr::render::forward_io::VertexOutput;
import bevy_pbr::render::mesh_view_bindings::{globals, view};

@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    let normal_vs = normalize((view.view_from_world * vec4(in.world_normal, 0.0)).xyz);

    // 2. Calculate the 2D angle from the center of the screen
    let angle = atan2(normal_vs.y, normal_vs.x);

    // 3. Create the Starburst Rays
    let ray_count = 16.0;
    let raw_ray = abs(sin(angle * ray_count * 0.5));

    // 15.0 makes them sharp, but not so thin they flicker
    let sharp_ray = pow(raw_ray, 15.0);

    // 4. Radial Falloff
    // How far from the center of the sphere are we? (0.0 at center, 1.0 at edges)
    let dist_from_center = length(normal_vs.xy);

    // Fade out the rays as they reach the edge of the sphere
    let edge_fade = 1.0 - smoothstep(0.2, 0.9, dist_from_center);

    // 5. Pulsating Effect (Heartbeat style)
    let pulse_speed = 6.0;
    // sin() goes from -1 to 1, so * 0.5 + 0.5 makes it 0 to 1
    let pulse = sin(globals.time * pulse_speed) * 0.5 + 0.5;

    // Fast flicker for sparks
    let flicker = sin(globals.time * 50.0) * 0.1 + 0.9;

    // Combine into final ray intensity
    let intensity = sharp_ray * edge_fade * (pulse * flicker);

    // 6. Colors
    // Mix between a bright hot white/yellow and a deep orange
    let ray_color = vec3<f32>(1.0, 0.4, 0.0);
    let core_color = vec3<f32>(1.0, 0.95, 0.8);

    // The closer to the ray center, the whiter it is
    let mixed_ray = mix(ray_color, core_color, sharp_ray);

    // 7. Central Core Glow
    // The center of the sphere faces the camera (normal_vs.z is close to 1.0)
    let center_glow_factor = pow(max(normal_vs.z, 0.0), 5.0);
    let core = vec3<f32>(1.0, 0.9, 0.6) * center_glow_factor * 3.0 * (pulse + 0.5);

    // 8. Final Output
    // Multiplying by 8.0 pushes it into HDR territory so Bloom kicks in
    let final_rays = mixed_ray * intensity * 8.0;

    // Combine the HDR rays and the core
    let final_color = final_rays + core;

    // Calculate luminance. Since final_color is HDR (can be > 1.0), 
    // we divide by a factor (e.g., 5.0) to bring the brightest parts 
    // down to a 0.0-1.0 range for the alpha channel.
    let luminance = dot(final_color, vec3<f32>(0.2126, 0.7152, 0.0722));
    let alpha = clamp(luminance / 5.0, 0.0, 1.0);

    return vec4<f32>(final_color, alpha);
}
