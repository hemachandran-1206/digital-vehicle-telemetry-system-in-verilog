// =======================================================
// Module: delta_calc.v
// Purpose: Compute delta position and delta velocity
// =======================================================
module delta_calc(
    input [15:0] pos_curr,
    input [15:0] pos_prev,
    input [15:0] vel_curr,
    input [15:0] vel_prev,
    output [15:0] delta_pos,
    output [15:0] delta_vel
);
    assign delta_pos = pos_curr - pos_prev;
    assign delta_vel = vel_curr - vel_prev;
endmodule
