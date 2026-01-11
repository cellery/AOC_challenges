//Module calculates approximate distances between 2 3D points
//Will keep track of all points in a memory

import aoc_types_pkg::*;

module dist_calc #(
    parameter NUM_POINTS = 1000,
    parameter DIM_W      = 17
) (
    input  logic                           clk,
    input  logic                           rst_n,

    //Input points               
    input  logic [DIM_W-1:0]               locs [3],
    input  logic                           locs_vld,
    output logic                           locs_rdy,
  
    //Output approx distance and points
    //Number of bits needed for approx dist is based on this dist formula:  (Xa-Xb)^2 + (Ya-Yb)^2 + (Za-Zb)^2
    output conn_t                          conn,
    output logic                           conn_vld
);

    localparam DIST_W = (DIM_W+1)*2+2;

    logic [DIM_W-1:0]                 wr_locs_r [3];
    logic [$clog2(NUM_POINTS)-1:0]    wr_point_ind;
    logic [$clog2(NUM_POINTS)-1:0]    wr_point_ind_r;
    logic                             wr_point_inc;
    logic                             wr_point_rdy;

    logic [DIM_W-1:0]                 rd_locs [3];
    logic [$clog2(NUM_POINTS)-1:0]    rd_point_ind; 
    logic [$clog2(NUM_POINTS)-1:0]    rd_point_ind_r; 
    logic                             rd_point_rst;
    logic                             rd_point_inc;
    logic                             rd_point_inc_r;

    logic [DIM_W-1:0]                 dists [3];

    logic                             done;

    //Write/read pointer logic. Write pointer increments when we've calculated all distances with the current point
    //Read pointer increments from 0 up to current write pointer and resets back to 0 until we're done
    assign wr_point_inc = locs_vld && locs_rdy;
    assign locs_rdy = wr_point_rdy;
    assign wr_point_rdy = wr_point_ind < 1 || rd_point_ind == wr_point_ind - 1;
    assign rd_point_inc = wr_point_ind >= 1 && !done;

    always_ff @(posedge clk) begin
        wr_point_ind    <= wr_point_inc ? wr_point_ind+1 : wr_point_ind;
        wr_point_ind_r  <= wr_point_ind;
        rd_point_ind    <= wr_point_inc ? '0 : (rd_point_inc ? rd_point_ind+1 : rd_point_ind);
        rd_point_ind_r  <= rd_point_ind;
        rd_point_inc_r  <= rd_point_inc;

        if(!rst_n) begin
            wr_point_ind  <= '0;
            rd_point_ind  <= '0;
        end
    end

    //Use delayed version of wr_points to match delay of rd_points from memory 
    always_ff @(posedge clk) begin
        wr_locs_r <= locs;

        if(!rst_n) begin
            wr_locs_r  <= '{default: '0};
        end
    end

    generate 
        for(genvar i=0;i<3;i=i+1) begin
            sdpram #(
                .DEPTH(NUM_POINTS), 
                .WIDTH(DIM_W),
                .RD_LAT(1),
                .WR_MODE(1)
            ) loc_memory (
                .clk  (clk),
                .rst_n(rst_n),

                .raddr(rd_point_ind),
                .ren  (1'b1),
                .rdata(rd_locs[i]),

                .waddr(wr_point_ind),
                .wen  (locs_vld && locs_rdy),
                .wdata(locs[i])
            );
            assign dists[i] = wr_locs_r[i] > rd_locs[i] ? wr_locs_r[i] - rd_locs[i] : rd_locs[i] - wr_locs_r[i];
        end
    endgenerate


    assign conn.distance = {{DIST_W-DIM_W{1'b0}},dists[0]}**2 + {{DIST_W-DIM_W{1'b0}},dists[1]}**2 + {{DIST_W-DIM_W{1'b0}},dists[2]}**2;
    assign conn.pointa = rd_point_ind_r;
    assign conn.pointb = wr_point_ind_r;
    assign conn_vld = rd_point_inc_r; 
    
    assign done = wr_point_ind == NUM_POINTS && rd_point_ind == NUM_POINTS;
endmodule