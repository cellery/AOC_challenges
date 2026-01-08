//Module calculates approximate distances between 2 3D points
//Will keep track of all points in a memory

module dist_calc #(
    parameter NUM_POINTS = 1000,
    parameter DIM_W      = 17
) (
    input logic                            clk,
    input logic                            rst_n,

    //Input points               
    input logic [DIM_W-1:0]                xloc,
    input logic [DIM_W-1:0]                yloc,
    input logic [DIM_W-1:0]                zloc,
    input logic                            loc_vld,
  
    //Output approx distance and points
    //Number of bits needed for approx dist is based on this dist formula:  (Xa-Xb)^2 + (Ya-Yb)^2 + (Za-Zb)^2
    output logic [((DIM_W+1)*2+2)-1:0]     approx_dist,
    output logic [$clog2(NUM_POINTS)-1:0]  pointa,
    output logic [$clog2(NUM_POINTS)-1:0]  pointb,
    output logic                           dist_vld
);
endmodule