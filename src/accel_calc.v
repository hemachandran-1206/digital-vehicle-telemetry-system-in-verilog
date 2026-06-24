// =======================================================
// Module: accel_calc.v
// Purpose: Compute acceleration from delta velocity
// =======================================================
module accel_calc #(
    parameter integer TIME_STEP = 10
)(
    input clk,
    input reset,
    input signed [15:0] delta_vel,
    output reg signed [31:0] acceleration
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            acceleration <= 32'sd0;
        else
            acceleration <= delta_vel / TIME_STEP;
    end
endmodule
