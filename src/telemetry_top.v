// =======================================================
// Module: telemetry_top.v
// Purpose: Top-level system integrating telemetry, fuel,
// slope, and cruise control.
// =======================================================
module telemetry_top #(
    parameter integer TIME_STEP = 10
)(
    input clk,
    input reset,
    input [15:0] position_in,
    input signed [15:0] slope_angle,
    input signed [31:0] target_speed,
    output [15:0] velocity,
    output signed [31:0] acceleration_final,
    output [31:0] distance,
    output [63:0] total_fuel,
    output [1:0] alert_flags
);

    wire [15:0] pos_curr, pos_prev;
    wire [15:0] delta_pos, delta_vel;
    wire [15:0] vel_prev;
    wire signed [31:0] acceleration_raw;
    wire signed [31:0] control_accel;
    wire signed [31:0] acceleration_with_slope;

    // Position tracking
    position_reg u_pos(
        .clk(clk), .reset(reset), .position_in(position_in),
        .pos_curr(pos_curr), .pos_prev(pos_prev)
    );

    // Delta calculations
    delta_calc u_delta(
        .pos_curr(pos_curr), .pos_prev(pos_prev),
        .vel_curr(velocity), .vel_prev(vel_prev),
        .delta_pos(delta_pos), .delta_vel(delta_vel)
    );

    // Velocity
    velocity_calc #(.TIME_STEP(TIME_STEP)) u_vel(
        .clk(clk), .reset(reset),
        .delta_pos(delta_pos),
        .velocity(velocity), .vel_prev(vel_prev)
    );

    // Distance
    distance_counter u_dist(
        .clk(clk), .reset(reset),
        .delta_pos(delta_pos),
        .distance(distance)
    );

    // Raw acceleration
    accel_calc #(.TIME_STEP(TIME_STEP)) u_accel(
        .clk(clk), .reset(reset),
        .delta_vel(delta_vel),
        .acceleration(acceleration_raw)
    );

    // Slope-adjusted acceleration
    hill_slope_calc u_slope(
        .acceleration_in(acceleration_raw),
        .slope_angle(slope_angle),
        .acceleration_out(acceleration_with_slope)
    );

    // Cruise control
    tom_cruise_calc u_cruise(
        .clk(clk),
        .reset(reset),
        .velocity({16'd0, velocity}),
        .target_speed(target_speed),
        .control_accel(control_accel)
    );

    // Combine effects
    assign acceleration_final = acceleration_with_slope + control_accel;

    // Fuel estimator
    fuel_estimator u_fuel(
        .clk(clk),
        .reset(reset),
        .velocity({16'd0, velocity}),
        .total_fuel(total_fuel)
    );

    // Alert system
    alert_unit u_alert(
        .velocity(velocity),
        .acceleration(acceleration_final[15:0]),
        .alert_flags(alert_flags)
    );

endmodule
