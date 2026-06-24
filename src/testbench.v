// =======================================================
// Module: testbench.v
// Purpose: Testbench for telemetry_top.v
// CS203 Project - Car Telemetry System
// =======================================================

`timescale 1ns / 1ps

module testbench;

    // --- Parameters ---
    parameter integer TIME_STEP   = 10;
    parameter integer CLK_PERIOD  = 10;
    parameter integer DELAY_CYCLES = 3;

    // --- Signals ---
    reg clk;
    reg reset;
    reg [15:0] position_in;
    reg signed [15:0] slope_angle;
    reg signed [31:0] target_speed;

    // --- Outputs ---
    wire [15:0] velocity;
    wire signed [31:0] acceleration_final;
    wire [31:0] distance;
    wire [63:0] total_fuel;
    wire [1:0] alert_flags;

    // --- Locals ---
    integer i;
    integer desired_vel;
    integer delta_pos_calc;

    // --- DUT ---
    telemetry_top #(.TIME_STEP(TIME_STEP)) DUT (
        .clk(clk),
        .reset(reset),
        .position_in(position_in),
        .slope_angle(slope_angle),
        .target_speed(target_speed),
        .velocity(velocity),
        .acceleration_final(acceleration_final),
        .distance(distance),
        .total_fuel(total_fuel),
        .alert_flags(alert_flags)
    );

    // --- Clock Generation ---
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // --- Display Task ---
    // Shows signed acceleration correctly using %0d
    task display_status;
        input [63:0] scenario;
        input integer step;
        input [127:0] note;
        begin
            $display("  @%6t ps | %-10s | step=%0d | pos=%6d | vel=%4d | accel=%6d | fuel=%6d | alert=%2b | %s",
                     $time, scenario, step, position_in, $signed(velocity), 
                     $signed(acceleration_final), $signed(total_fuel), alert_flags, note);
        end
    endtask

    // --- Scenario Task ---
    // Updates position_in, waits for pipeline to settle (2 cycles), then displays
    task run_scenario_step;
        input [63:0] scenario_name;
        input integer step_num;
        input integer target_vel;
        input signed [15:0] slope;
        input integer target_spd;
        input [127:0] note;
        begin
            target_speed = target_spd;
            slope_angle = slope;
            desired_vel = target_vel;
            delta_pos_calc = desired_vel * TIME_STEP;
            position_in = position_in + delta_pos_calc;
            
            // Wait for position capture + velocity computation + pipeline settle
            @(posedge clk);  // Cycle 1: position_reg captures new position_in
            @(posedge clk);  // Cycle 2: delta_calc + velocity_calc settle
            #1;              // Small delay after posedge for display
            display_status(scenario_name, step_num, note);
        end
    endtask

    // --- Simulation ---
    initial begin
        $dumpfile("telemetry_top.vcd");
        $dumpvars(0, testbench);

        $display("================================================================================");
        $display("  CS203 PROJECT - CAR TELEMETRY SYSTEM");
        $display("  TIME_STEP=%0d, CLK_PERIOD=%0d ns, CLOCK_FREQ=%0d MHz", TIME_STEP, CLK_PERIOD, 1000/CLK_PERIOD);
        $display("================================================================================");
        $display("  Legend: alert_flags = {overspeed, harsh_brake}");
        $display("  Note:  $time is in ps (1ns = 1000ps). Clock period = %0d ns = %0d ps", CLK_PERIOD, CLK_PERIOD*1000);
        $display("================================================================================");

        // --- Reset ---
        reset = 1;
        position_in = 16'd0;
        slope_angle = 16'd0;
        target_speed = 32'd0;
        @(posedge clk); @(posedge clk);
        reset = 0;
        $display("\n>> RESET COMPLETE @ T=%0t ps (%0t ns)\n", $time, $time/1000);

        // --- Scenario 1: Acceleration ---
        $display("--------------------------------------------------------------------------------");
        $display("  SCENARIO 1: ACCELERATION (Target Speed: 50)");
        $display("  Expected: velocity increases 10 -> 20 -> 30 -> 40 -> 50 -> 60 -> 70 -> 80");
        $display("--------------------------------------------------------------------------------");
        for (i = 0; i < 8; i = i + 1) begin
            run_scenario_step("ACCEL", i, 10*(i+1), 16'd0, 32'd50, "Speed increasing");
        end
        repeat(DELAY_CYCLES) @(posedge clk);

        // --- Scenario 2: Constant Speed ---
        $display("\n--------------------------------------------------------------------------------");
        $display("  SCENARIO 2: CONSTANT SPEED (Target Speed: 50)");
        $display("  Expected: velocity = 50, acceleration -> 0 (cruise control balanced)");
        $display("--------------------------------------------------------------------------------");
        for (i = 0; i < 5; i = i + 1) begin
            run_scenario_step("CONST", i, 50, 16'd0, 32'd50, "Steady cruise");
        end
        repeat(DELAY_CYCLES) @(posedge clk);

        // --- Scenario 3: Overspeed Alert ---
        $display("\n--------------------------------------------------------------------------------");
        $display("  SCENARIO 3: OVERSPEED (Alert flag[1] expected, velocity > 100)");
        $display("  Expected: velocity = 120, alert_flags = 2'b10 (overspeed)");
        $display("--------------------------------------------------------------------------------");
        for (i = 0; i < 5; i = i + 1) begin
            run_scenario_step("OVER", i, 120, 16'd0, 32'd40, "Velocity > 100");
        end
        repeat(DELAY_CYCLES) @(posedge clk);

        // --- Scenario 4: Harsh Braking ---
        $display("\n--------------------------------------------------------------------------------");
        $display("  SCENARIO 4: HARSH BRAKE (Alert flag[0] expected, accel < -20)");
        $display("  Expected: velocity drops, negative acceleration, alert_flags = 2'b01");
        $display("--------------------------------------------------------------------------------");
        for (i = 0; i < 5; i = i + 1) begin
            if (i == 0)
                run_scenario_step("BRAKE", i, 50, 16'd0, 32'd0, "Rapid deceleration");
            else if (i == 1)
                run_scenario_step("BRAKE", i, 0, 16'd0, 32'd0, "Full stop");
            else
                run_scenario_step("BRAKE", i, 0, 16'd0, 32'd0, "Holding stop");
        end
        repeat(DELAY_CYCLES) @(posedge clk);

        // --- Settling ---
        $display("\n--------------------------------------------------------------------------------");
        $display("  SETTLING AFTER BRAKE (Target Speed: 20)");
        $display("  Expected: velocity stabilizes at 20, acceleration positive to maintain speed");
        $display("--------------------------------------------------------------------------------");
        for (i = 0; i < 3; i = i + 1) begin
            run_scenario_step("SET", i, 20, 16'd0, 32'd20, "Stabilizing");
        end
        repeat(DELAY_CYCLES) @(posedge clk);

        // --- Scenario 5: Uphill Slope ---
        $display("\n--------------------------------------------------------------------------------");
        $display("  SCENARIO 5: UPHILL SLOPE (+10 degrees)");
        $display("  Expected: acceleration reduced by ~10 due to gravity");
        $display("--------------------------------------------------------------------------------");
        for (i = 0; i < 5; i = i + 1) begin
            run_scenario_step("UPHILL", i, 50, 16'd10, 32'd50, "Gravity fighting");
        end
        repeat(DELAY_CYCLES) @(posedge clk);

        // --- Scenario 6: Downhill Slope ---
        $display("\n--------------------------------------------------------------------------------");
        $display("  SCENARIO 6: DOWNHILL SLOPE (-10 degrees)");
        $display("  Expected: acceleration increased by ~10 due to gravity assist");
        $display("--------------------------------------------------------------------------------");
        for (i = 0; i < 5; i = i + 1) begin
            run_scenario_step("DOWN", i, 50, -16'd10, 32'd50, "Gravity assisting");
        end

        $display("\n================================================================================");
        $display("  SIMULATION COMPLETE");
        $display("================================================================================");
        $finish;
    end

endmodule
