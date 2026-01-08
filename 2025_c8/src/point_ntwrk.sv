module point_ntwrk #(
    parameter NUM_POINTS = 1000,
    parameter NUM_NTWRKS = 3
) (
    input logic                             clk,
    input logic                             rst_n,
  
    //Input point tuple for network LUT  
    input logic [$clog2(NUM_POINTS)-1:0]    pointa_in,
    input logic [$clog2(NUM_POINTS)-1:0]    pointb_in,
    input logic                             points_vld,

    //Output network sizes
    output logic [$clog2(NUM_POINTS/2)-1:0] ntwrk_sz [NUM_NTWRKS],
    output logic                            ntwrk_sz_vld
);

endmodule