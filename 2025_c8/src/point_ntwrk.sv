import aoc_types_pkg::*;

module point_ntwrk #(
    parameter NUM_POINTS = 1000,
    parameter NUM_NTWRKS = 3
) (
    input  logic                             clk,
    input  logic                             rst_n,
  
    //Input point tuple for network LUT  
    input  logic [$clog2(NUM_POINTS)-1:0]    pointa_in,
    input  logic [$clog2(NUM_POINTS)-1:0]    pointb_in,
    input  logic                             points_in_vld,
    output logic                             points_in_rdy,

    //Output network sizes
    output logic  [$clog2(NUM_POINTS/2)-1:0] ntwrk_sz [NUM_NTWRKS],
    output logic                             ntwrk_sz_vld
);

    logic [$clog2(MAX_NTWRKS)-1:0] max_ntwrk_id;

    //Point -> Network signals 
    logic [$clog2(MAX_NTWRKS)-1:0] ntwrka_lu_id;
    logic [$clog2(MAX_NTWRKS)-1:0] ntwrkb_lu_id;
    logic [$clog2(NUM_POINTS)-1:0] pointa_in_r;
    logic [$clog2(NUM_POINTS)-1:0] pointb_in_r;
    logic                          read_in_point;
    logic                          read_in_point_r;

    logic                          pointa_ntwrk_wr_en;
    logic [$clog2(NUM_POINTS)-1:0] pointa_ntwrk_wr_addr;
    logic [$clog2(MAX_NTWRKS)-1:0] pointa_ntwrk_wr_data;
    logic                          pointb_ntwrk_wr_en;
    logic [$clog2(NUM_POINTS)-1:0] pointb_ntwrk_wr_addr;
    logic [$clog2(MAX_NTWRKS)-1:0] pointb_ntwrk_wr_data;


    //Point -> Network signals
    ntwrk_cmd_id_t                 point_ntwrk_action;

    //Network lookup/remap table signals
    logic                          lookupa_active;
    logic                          lookupa_done;
    logic                          lookupa_ren;
    logic [$clog2(MAX_NTWRKS)-1:0] lookupa_raddr;
    logic [$clog2(MAX_NTWRKS)-1:0] lookupa_rdata;
    logic [$clog2(MAX_NTWRKS)-1:0] lookupa_ntwrk;

    logic                          lookupb_active;
    logic                          lookupb_done;
    logic                          lookupb_ren;
    logic [$clog2(MAX_NTWRKS)-1:0] lookupb_raddr;
    logic [$clog2(MAX_NTWRKS)-1:0] lookupb_rdata;
    logic [$clog2(MAX_NTWRKS)-1:0] lookupb_ntwrk;

    logic                          remap_active;
    logic                          remap_done;
    ntwrk_cmd_id_t                 remap_ntwrk_action;

    assign pointa_ntwrk_wr_en   = read_in_point_r && (point_ntwrk_action == NEW || point_ntwrk_action == WR_A);
    assign pointb_ntwrk_wr_en   = read_in_point_r && (point_ntwrk_action == NEW || point_ntwrk_action == WR_B);
    assign pointa_ntwrk_wr_addr = pointa_in_r; //For now always the registered read address but may have to be updated later
    assign pointb_ntwrk_wr_addr = pointb_in_r; //For now always the registered read address but may have to be updated later
    assign pointa_ntwrk_wr_data = (point_ntwrk_action == WR_A) ? ntwrkb_lu_id : max_ntwrk_id;
    assign pointb_ntwrk_wr_data = (point_ntwrk_action == WR_B) ? ntwrka_lu_id : max_ntwrk_id;

    //Ready logic
    assign read_in_point = points_in_vld && points_in_rdy;
    always_comb begin
        if(read_in_point_r) begin //Can't read in next point after the last read
            points_in_rdy = 1'b0;
        end else if(pointa_ntwrk_wr_en || pointb_ntwrk_wr_en) begin //Can't read in next point while writing the same point
            points_in_rdy = (pointa_in != pointa_ntwrk_wr_addr && pointa_in != pointb_ntwrk_wr_addr) && (pointb_in != pointb_ntwrk_wr_addr && pointb_in != pointa_ntwrk_wr_addr);
        end else if(remap_active) begin
            points_in_rdy = 1'b0;
        end else begin
            points_in_rdy = 1'b1;
        end
    end

    mdpram #(
        .DEPTH(NUM_POINTS),
        .WIDTH($clog2(MAX_NTWRKS)),
        .RD_LAT(1),
        .NUM_RD(2),
        .NUM_WR(2)
    ) point_ntwrk_lut (
        .clk   (clk),
        .rst_n (rst_n),

        .raddr ({pointa_in, pointb_in}),
        .ren   ({points_in_vld, points_in_vld}),
        .rdata ({ntwrka_lu_id, ntwrkb_lu_id}),

        .waddr ({pointa_ntwrk_wr_addr, pointb_ntwrk_wr_addr}),
        .wen   ({pointa_ntwrk_wr_en, pointb_ntwrk_wr_en}),
        .wdata ({pointa_ntwrk_wr_data, pointb_ntwrk_wr_data})
    );

    always_ff @(posedge clk) begin
        pointa_in_r          <= pointa_in;
        pointb_in_r          <= pointb_in;
        max_ntwrk_id         <= point_ntwrk_action == NEW ? max_ntwrk_id+1 : max_ntwrk_id; 
        read_in_point_r      <= read_in_point;
        
        if(!rst_n) begin
            max_ntwrk_id         <= 'd1; //0 network id is reserved for invalid network id
        end
    end

    //Based on the network IDs from the Point -> Network LUT we decide on our next action
    always_comb begin
        if(read_in_point_r) begin
            if ((ntwrka_lu_id == '0) ^ (ntwrkb_lu_id == '0)) begin //add to existing network
                point_ntwrk_action = (ntwrka_lu_id == '0) ? WR_A : WR_B;
            end else if((ntwrka_lu_id == '0) && (ntwrkb_lu_id == '0)) begin //Create new network
                point_ntwrk_action = NEW;
            end else if (ntwrka_lu_id != ntwrkb_lu_id) begin //Look up if we network IDs are remapped before we make decision
                point_ntwrk_action = LOOKUP;
            end else begin
                point_ntwrk_action = IGNORE;
            end
        end else begin
            point_ntwrk_action = IGNORE;
        end
    end

    //Keep track of lookup status, a and b can have different lookup times so need to track separate
    always_ff @(posedge clk) begin
        lookupa_active        <= !lookupa_active ? (point_ntwrk_action == LOOKUP) : !lookupa_done;
        lookupa_raddr         <= (point_ntwrk_action == LOOKUP) ? ntwrka_lu_id : lookupa_rdata;
        lookupa_ren           <= (point_ntwrk_action == LOOKUP) || (lookupa_active && !lookupa_done);
        lookupa_ntwrk         <= (point_ntwrk_action == LOOKUP) ? ntwrka_lu_id : ((lookupa_active && lookupa_rdata != '0) ? lookupa_rdata : lookupa_ntwrk);

        lookupb_active        <= !lookupb_active ? (point_ntwrk_action == LOOKUP) : !lookupb_done;
        lookupb_raddr         <= (point_ntwrk_action == LOOKUP) ? ntwrkb_lu_id : lookupb_rdata;
        lookupb_ren           <= (point_ntwrk_action == LOOKUP) || (lookupb_active && !lookupb_done);
        lookupb_ntwrk         <= (point_ntwrk_action == LOOKUP) ? ntwrkb_lu_id : ((lookupb_active && lookupb_rdata != '0) ? lookupb_rdata : lookupb_ntwrk);

        remap_active          <= !remap_active ? (point_ntwrk_action == LOOKUP) : remap_done;
        
        if(!rst_n) begin
            lookupa_active    <= 1'b0;
            lookupa_raddr     <= '0;
            lookupa_ren       <= 1'b0;
            lookupa_ntwrk     <= '0;

            lookupb_active    <= 1'b0;
            lookupb_raddr     <= '0;
            lookupb_ren       <= 1'b0;
            lookupb_ntwrk     <= '0;

            remap_active      <= 1'b0;
        end
    end

    //Lookup is done once we read 0 from the remap table
    assign lookupa_done = lookupa_active && lookupa_rdata == '0;
    assign lookupb_done = lookupa_active && lookupb_rdata == '0;

    //With final network ids we need to decide on next action based on these newer ids (merge or update pointer -> network LUT)
    always_comb begin
        if(remap_active && !lookupa_active && !lookupb_active) begin
            if (lookupa_ntwrk != lookupb_ntwrk) begin //Look up if we network IDs are remapped before we make decision
                remap_ntwrk_action = MERGE;
            end else begin
                remap_ntwrk_action = IGNORE;
            end
        end else begin
            remap_ntwrk_action = IGNORE;
        end
    end

    //Table contains a linked list for network remapping
    //TODO - Collapse linked lists with more than 2 nodes to speed up search time
    /*
    mdpram #(
        .DEPTH(NUM_POINTS),
        .WIDTH($clog2(MAX_NTWRKS)),
        .RD_LAT(1),
        .NUM_RD(2),
        .NUM_WR(2)
    ) point_ntwrk_lut (
        .clk   (clk),
        .rst_n (rst_n),

        .raddr ({pointa_in, pointb_in}),
        .ren   ({points_in_vld, points_in_vld}),
        .rdata ({ntwrka_lu_id, ntwrkb_lu_id}),

        .waddr ({pointa_ntwrk_wr_addr, pointb_ntwrk_wr_addr}),
        .wen   ({pointa_ntwrk_wr_en, pointb_ntwrk_wr_en}),
        .wdata ({pointa_ntwrk_wr_data, pointb_ntwrk_wr_data})
    );
    */




endmodule