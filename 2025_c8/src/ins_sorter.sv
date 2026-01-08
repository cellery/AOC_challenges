//Insert sorter is a shift register that shifts in new values and will sort them either min or max depending on params

module ins_sorter #(
    parameter NUM_POINTS = 1000,
    parameter DIM_W      = 17,
    parameter SORT_OP    = 0 //0 - min sort, 1 - max sort
) (
    input logic                            clk,
    input logic                            rst_n,
    
    //Dist/point tuple to use for sorting
    input logic [((DIM_W+1)*2+2)-1:0]      approx_dist,
    input logic [$clog2(NUM_POINTS)-1:0]   pointa_in,
    input logic [$clog2(NUM_POINTS)-1:0]   pointb_in,
    input logic                            dist_vld,

    //Output point tuple for network LUT
    output logic [$clog2(NUM_POINTS)-1:0]  pointa_out,
    output logic [$clog2(NUM_POINTS)-1:0]  pointb_out,
    output logic                           points_vld
);

endmodule