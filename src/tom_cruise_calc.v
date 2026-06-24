// =======================================================
// Module: tom_cruise_calc.v
// Purpose: Maintain a set target velocity using P-control
// =======================================================
module tom_cruise_calc #(
    parameter signed [15:0] Kp = 16'sd1
)(
    input  clk,
    input  reset,
    input  signed [31:0] velocity,
    input  signed [31:0] target_speed,
    output reg signed [31:0] control_accel
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            control_accel <= 32'sd0;
        else
            control_accel <= Kp * (target_speed - velocity);
    end
endmodule
