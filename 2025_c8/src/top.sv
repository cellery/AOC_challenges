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
    output logic    [$clog2(NUM_CONNS)*3-1:0] answer,
    output logic                              answer_vld
);

    localparam ANSWER_SZ = $clog2(NUM_CONNS)*3;
    localparam NTWRK_SZ  = $clog2(NUM_CONNS)+1;

    //Dist calculator nets
    logic [DIM_W-1:0]                  locs [3];
    conn_t                             conn;
    logic                              conn_vld;
    logic                              dist_done;
    
    //Network sorting nets   
    logic [$clog2(NUM_POINTS)-1:0]     pointa_sort_out;
    logic [$clog2(NUM_POINTS)-1:0]     pointb_sort_out;
    logic                              points_sort_out_vld;
    logic                              points_sort_out_rdy;

    logic [$clog2(NUM_POINTS)-1:0]     pointa_sort_in;
    logic [$clog2(NUM_POINTS)-1:0]     pointb_sort_in;
    logic                              points_sort_in_vld;
    logic                              points_sort_in_rdy;

    logic                              sort_points_fifo_afull;
    logic                              sort_points_fifo_full;
    logic                              sort_points_fifo_empty;

    logic             [NTWRK_SZ-1:0]   ntwrk_sz [NUM_NTWRKS];
    logic                              ntwrk_sz_final;

    //Answer logic
    logic [ANSWER_SZ-1:0] answer_i;

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
        .conn_vld   (conn_vld),
        .done       (dist_done)
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
        .dist_done   (dist_done),

        .pointa_out  (pointa_sort_out),
        .pointb_out  (pointb_sort_out),
        .points_vld  (points_sort_out_vld),
        .points_rdy  (points_sort_out_rdy)
    );

    assign points_sort_out_rdy = !sort_points_fifo_afull; //Use almost full as there is one extra cycle of delay in the sorter block
    assign points_sort_in_vld = !sort_points_fifo_empty;
    sfifo #(
        .DWIDTH($clog2(NUM_POINTS)*2),
        .DEPTH(16),
        .AFULL(3) 
    ) sort_points_fifo (
        .clk  (clk),
        .rst_n(rst_n),

        .din  ({pointa_sort_out, pointb_sort_out}),
        .wr_en(points_sort_out_vld),

        .dout ({pointa_sort_in, pointb_sort_in}),
        .rd_en(points_sort_in_rdy),

        .full (sort_points_fifo_full),
        .afull(sort_points_fifo_afull),
        .empty(sort_points_fifo_empty)
    );

    point_ntwrk  #(
        .NUM_POINTS(NUM_POINTS),
        .NUM_NTWRKS(NUM_NTWRKS),
        .NUM_CONNS(NUM_CONNS)
    ) point_ntwrk_i (
        .clk            (clk),
        .rst_n          (rst_n),
        
        .pointa_in      (pointa_sort_in),
        .pointb_in      (pointb_sort_in),
        .points_in_vld  (points_sort_in_vld),
        .points_in_rdy  (points_sort_in_rdy),
    
        .ntwrk_sz       (ntwrk_sz),
        .ntwrk_sz_final (ntwrk_sz_final)
    );

    //TODO - This could cause timing issues if NUM_NTWRKS becomes large
    always_comb begin : network_prod
        answer_i = {{ANSWER_SZ-NTWRK_SZ{1'b0}}, ntwrk_sz[0]};
        for (int i=1;i<NUM_NTWRKS;i=i+1) begin
            answer_i = answer_i * ntwrk_sz[i];
        end
    end 
    assign answer = answer_i;
    assign answer_vld = ntwrk_sz_final;

endmodule