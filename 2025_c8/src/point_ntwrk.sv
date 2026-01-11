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

    localparam MAX_NTWRKS = $clog2(NUM_POINTS/2);

    logic [$clog2(NUM_POINTS)-1:0] raddrs [2];
    logic                          rens [2];
    logic [$clog2(MAX_NTWRKS)-1:0] rdatas [2];
    assign raddrs = '{pointa_in, pointb_in};
    assign rens   = '{points_vld, points_vld};

    //logic [$clog2(NUM_POINTS)-1:0] waddrs [2];
    //logic                          wens [2];
    //logic [$clog2(MAX_NTWRKS)-1:0] wdatas [2];
//
    //mdpram #(
    //    .DEPTH(NUM_POINTS),
    //    .WIDTH($clog2(MAX_NTWRKS)),
    //    .RD_LAT(1),
    //    .NUM_RD(2),
    //    .NUM_WR(2)
    //) point_ntwrk_lut (
    //    .clk   (clk),
    //    .rst_n (rst_n),
//
    //    .raddr (raddrs),
    //    .ren   (rens),
    //    .rdata (rdatas),
//
    //    .waddr (waddrs),
    //    .wen   (wens),
    //    .wdata (wdatas)
    //);

endmodule