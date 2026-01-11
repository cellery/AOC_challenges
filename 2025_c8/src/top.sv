import aoc_types_pkg::*;

module top #(
    parameter NUM_POINTS = `NUM_POINTS,
    parameter NUM_CONNS  = `NUM_CONNS,
    parameter DIM_W      = `DIM_W,
    parameter NUM_NTWRKS = `NUM_NTWRKS
) (
    input  logic                              clk,
    input  logic                              rst_n,
                 
    //Input points                 
    input  logic [DIM_W-1:0]                  xloc,
    input  logic [DIM_W-1:0]                  yloc,
    input  logic [DIM_W-1:0]                  zloc,
    input  logic                              locs_vld,
    output logic                              locs_rdy,

    //Output answer
    output logic [$clog2(NUM_POINTS/2)*3-1:0] answer,
    output logic                              answer_vld
);

    //Dist calculator nets
    logic [DIM_W-1:0]                  locs [3];
    conn_t                             conn;
    logic                              conn_vld;
    
    //Network sorting nets   
    logic [$clog2(NUM_POINTS)-1:0]     pointa_sort;
    logic [$clog2(NUM_POINTS)-1:0]     pointb_sort;
    logic                              points_sort_vld;
    logic [$clog2(NUM_POINTS/2)-1:0]   ntwrk_sz [NUM_NTWRKS];
    logic                              ntwrk_sz_vld;

    //Answer logic
    logic [$clog2(NUM_POINTS/2)*3-1:0] answer_i;

    assign locs[0] = xloc;
    assign locs[1] = yloc;
    assign locs[2] = zloc;

    dist_calc  #(
        .NUM_POINTS(NUM_POINTS),
        .DIM_W     (DIM_W)
    ) dist_calc_i (
        .clk        (clk),
        .rst_n      (rst_n),
        
        .locs       (locs),
        .locs_vld   (locs_vld),
        .locs_rdy   (locs_rdy),
    
        .conn       (conn),
        .conn_vld   (conn_vld)
    );

    ins_sorter  #(
        .NUM_POINTS(NUM_POINTS),
        .NUM_CONNS (NUM_CONNS),
        .DIM_W     (DIM_W)
    ) ins_sorter_i (
        .clk         (clk),
        .rst_n       (rst_n),

        .conn_in     (conn),
        .conn_in_vld (conn_vld),

        .pointa_out  (pointa_sort),
        .pointb_out  (pointb_sort),
        .points_vld  (points_sort_vld)
    );

    point_ntwrk  #(
        .NUM_POINTS(NUM_POINTS),
        .NUM_NTWRKS(NUM_NTWRKS)
    ) point_ntwrk_i (
        .clk         (clk),
        .rst_n       (rst_n),
        
        .pointa_in   (pointa_sort),
        .pointb_in   (pointb_sort),
        .points_vld  (points_sort_vld),
    
        .ntwrk_sz    (ntwrk_sz),
        .ntwrk_sz_vld(ntwrk_sz_vld)
    );

    //TODO - This could cause timing issues if NUM_NTWRKS becomes large
    always_comb begin : network_prod
        answer_i = 0;
        for (int i=0;i<NUM_NTWRKS;i=i+1) begin
            answer_i = answer_i * ntwrk_sz[i];
        end
    end 
    assign answer = answer_i;
    assign answer_vld = ntwrk_sz_vld;

endmodule