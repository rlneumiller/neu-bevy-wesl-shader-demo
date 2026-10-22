import bevy_pbr::render::forward_io::VertexOutput;
import bevy_pbr::render::mesh_view_bindings::globals;

@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    // --- Pulsating factor (0.5 to 1.5 range) ---
    let speed = 3.0;
    let pulse = sin(globals.time * speed) * 0.5 + 1.0;

    // --- Starburst from UV ---
    // Center the UV around (0.5, 0.5)
    let centered = in.uv - vec2<f32>(0.5, 0.5);
    
    // Angle in radians around the sphere's UV center
    let angle = atan2(centered.y, centered.x);
    
    // Number of spikes/rays
    let ray_count = 12.0;
    
    // Create sharp rays using a power function on the absolute sine
    // abs(sin(angle * ray_count / 2.0)) gives repeating peaks
    let raw_ray = abs(sin(angle * ray_count * 0.5));
    let sharp_ray = pow(raw_ray, 8.0);
    
    // Radial falloff so rays fade toward the edges of the UV
    let dist = length(centered);
    let falloff = 1.0 - smoothstep(0.0, 0.5, dist);
    
    // --- Combine ---
    let intensity = sharp_ray * falloff * pulse;
    
    // Color: bright white-yellow core fading to orange edge
    let core_color = vec3<f32>(1.0, 1.0, 0.8);
    let edge_color = vec3<f32>(1.0, 0.4, 0.0);
    let final_color = mix(edge_color, core_color, falloff) * intensity;
    
    // Add a subtle base glow so the sphere isn't fully black between rays
    let base_glow = vec3<f32>(0.1, 0.05, 0.02) * pulse;
    
    return vec4<f32>(final_color + base_glow, 1.0);
}