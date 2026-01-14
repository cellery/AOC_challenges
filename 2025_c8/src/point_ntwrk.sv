import aoc_types_pkg::*;

module point_ntwrk #(
    parameter NUM_POINTS = 1000,
    parameter NUM_CONNS = 1000,
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

    //Points to new network id when we create one
    logic [$clog2(NUM_CONNS)-1:0] max_ntwrk_id;

    //Point -> Network signals 
    logic [$clog2(NUM_CONNS)-1:0]  ntwrka_lu_id;
    logic [$clog2(NUM_CONNS)-1:0]  ntwrkb_lu_id;
    logic [$clog2(NUM_POINTS)-1:0] pointa_in_r;
    logic [$clog2(NUM_POINTS)-1:0] pointb_in_r;
    logic                          read_in_point;
    logic                          read_in_point_r;

    logic                          pointa_ntwrk_wr_en;
    logic [$clog2(NUM_POINTS)-1:0] pointa_ntwrk_wr_addr;
    logic [$clog2(NUM_CONNS)-1:0]  pointa_ntwrk_wr_data;
    logic                          pointb_ntwrk_wr_en;
    logic [$clog2(NUM_POINTS)-1:0] pointb_ntwrk_wr_addr;
    logic [$clog2(NUM_CONNS)-1:0]  pointb_ntwrk_wr_data;


    //Point -> Network signals
    ntwrk_cmd_id_t                 point_ntwrk_action;

    //Network lookup/remap table signals
    logic                          lookupa_active;
    logic                          lookupa_en;
    logic [$clog2(NUM_CONNS)-1:0]  lookupa_raddr;
    logic [$clog2(NUM_CONNS)-1:0]  lookupa_rdata;
    logic [$clog2(NUM_CONNS)-1:0]  lookupa_ntwrk;
    logic                          lookupa_wen;
    logic [$clog2(NUM_CONNS)-1:0]  lookupa_waddr;
    logic [$clog2(NUM_CONNS)-1:0]  lookupa_wdata;
    logic [$clog2(NUM_POINTS)-1:0] lookupa_orig_point;
    logic [$clog2(NUM_CONNS)-1:0]  lookupa_orig_ntwrk;

    logic                          lookupb_active;
    logic                          lookupb_en;
    logic [$clog2(NUM_CONNS)-1:0]  lookupb_raddr;
    logic [$clog2(NUM_CONNS)-1:0]  lookupb_rdata;
    logic [$clog2(NUM_CONNS)-1:0]  lookupb_ntwrk;
    logic                          lookupb_wen;
    logic [$clog2(NUM_CONNS)-1:0]  lookupb_waddr;
    logic [$clog2(NUM_CONNS)-1:0]  lookupb_wdata;
    logic [$clog2(NUM_POINTS)-1:0] lookupb_orig_point;
    logic [$clog2(NUM_CONNS)-1:0]  lookupb_orig_ntwrk;

    logic                          remap_active;
    logic                          remap_done;
    ntwrk_cmd_id_t                 remap_ntwrk_action;

    assign pointa_ntwrk_wr_en   = point_ntwrk_action == NEW || point_ntwrk_action == WR_A || remap_ntwrk_action == WR_A || remap_ntwrk_action == MERGE;
    assign pointb_ntwrk_wr_en   = point_ntwrk_action == NEW || point_ntwrk_action == WR_B || remap_ntwrk_action == WR_B || remap_ntwrk_action == MERGE;
    assign pointa_ntwrk_wr_addr = (remap_ntwrk_action == WR_A || remap_ntwrk_action == MERGE) ? lookupa_orig_point : pointa_in_r; 
    assign pointb_ntwrk_wr_addr = (remap_ntwrk_action == WR_B || remap_ntwrk_action == MERGE) ? lookupb_orig_point : pointb_in_r; 
    assign pointa_ntwrk_wr_data = remap_ntwrk_action == WR_A ? lookupb_ntwrk : ((point_ntwrk_action == WR_A) ? ntwrkb_lu_id : max_ntwrk_id);
    assign pointb_ntwrk_wr_data = remap_ntwrk_action == WR_B ? lookupa_ntwrk : ((point_ntwrk_action == WR_B) ? ntwrka_lu_id : max_ntwrk_id);

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
        .WIDTH($clog2(NUM_CONNS)),
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
        max_ntwrk_id         <= (point_ntwrk_action == NEW || remap_ntwrk_action == MERGE) ? max_ntwrk_id+1 : max_ntwrk_id; 
        read_in_point_r      <= read_in_point;
        
        if(!rst_n) begin
            max_ntwrk_id         <= 'd1; //0 network id is reserved for invalid network id
        end
    end

    //Based on the network IDs from the Point -> Network LUT we decide on our next action
    always_comb begin
        if(read_in_point_r) begin
            if((ntwrka_lu_id == '0) && (ntwrkb_lu_id == '0)) begin //Create new network
                point_ntwrk_action = NEW;
            end else if (ntwrka_lu_id != ntwrkb_lu_id) begin //Look up if our network IDs are remapped before we make decision
                point_ntwrk_action = LOOKUP;
            end else begin
                point_ntwrk_action = IGNORE;
            end
        end else begin
            point_ntwrk_action = IGNORE;
        end
    end

    //Keep track of lookup/remap status, a and b can have different lookup times so need to track separate
    assign lookupa_en     = (point_ntwrk_action == LOOKUP) && ntwrka_lu_id != '0;
    assign lookupa_active = lookupa_en || lookupa_rdata != '0;
    assign lookupa_raddr  = (point_ntwrk_action == LOOKUP) ? ntwrka_lu_id : lookupa_rdata;

    assign lookupb_en     = (point_ntwrk_action == LOOKUP) && ntwrkb_lu_id != '0;
    assign lookupb_active = lookupb_en || lookupb_rdata != '0;
    assign lookupb_raddr  = (point_ntwrk_action == LOOKUP) ? ntwrkb_lu_id : lookupb_rdata;

    always_ff @(posedge clk) begin
        lookupa_orig_point    <= (point_ntwrk_action == LOOKUP) ? pointa_in_r : lookupa_orig_point;
        lookupa_orig_ntwrk    <= (point_ntwrk_action == LOOKUP) ? ntwrka_lu_id : lookupa_orig_ntwrk;
        lookupa_ntwrk         <= (point_ntwrk_action == LOOKUP) ? ntwrka_lu_id : ((lookupa_rdata != '0) ? lookupa_rdata : lookupa_ntwrk);

        lookupb_orig_point    <= (point_ntwrk_action == LOOKUP) ? pointb_in_r : lookupb_orig_point;
        lookupb_orig_ntwrk    <= (point_ntwrk_action == LOOKUP) ? ntwrkb_lu_id : lookupb_orig_ntwrk;
        lookupb_ntwrk         <= (point_ntwrk_action == LOOKUP) ? ntwrkb_lu_id : ((lookupb_rdata != '0) ? lookupb_rdata : lookupb_ntwrk);
 
        remap_active          <= !remap_active ? (point_ntwrk_action == LOOKUP) : !remap_done;
        
        if(!rst_n) begin
            lookupa_orig_point <= '0;
            lookupa_orig_ntwrk <= '0;
            lookupa_ntwrk      <= '0;

            lookupb_orig_point <= '0;
            lookupb_orig_ntwrk <= '0;
            lookupb_ntwrk      <= '0;

            remap_active      <= 1'b0;
        end
    end

    //With final network ids we need to decide on next action based on these newer ids (merge and/or update pointer -> network LUT)
    always_comb begin
        if(remap_active && !lookupa_active && !lookupb_active) begin
            if ((lookupa_ntwrk == '0) ^ (lookupb_ntwrk == '0)) begin //add to existing network
                remap_ntwrk_action = (lookupa_ntwrk == '0) ? WR_A : WR_B;
            end else if (lookupa_ntwrk != lookupb_ntwrk) begin
                remap_ntwrk_action = MERGE;
            end else begin
                remap_ntwrk_action = UPDATE;
            end
        end else begin
            remap_ntwrk_action = IGNORE;
        end
    end

    //Update remap table if we need to merge and make a new network or if we need to update pointers for existing remaps
    assign lookupa_wen   = remap_ntwrk_action == MERGE || (remap_ntwrk_action == UPDATE && lookupa_orig_ntwrk != lookupa_ntwrk);
    assign lookupb_wen   = remap_ntwrk_action == MERGE || (remap_ntwrk_action == UPDATE && lookupb_orig_ntwrk != lookupb_ntwrk);
    assign lookupa_waddr = remap_ntwrk_action == MERGE ? lookupa_ntwrk : lookupa_orig_ntwrk; 
    assign lookupb_waddr = remap_ntwrk_action == MERGE ? lookupb_ntwrk : lookupb_orig_ntwrk; 
    assign lookupa_wdata = remap_ntwrk_action == MERGE ? max_ntwrk_id : lookupa_ntwrk;
    assign lookupb_wdata = remap_ntwrk_action == MERGE ? max_ntwrk_id : lookupb_ntwrk;

    assign remap_done = remap_active && remap_ntwrk_action != IGNORE;

    //Table contains a linked list for network remapping
    //TODO - Collapse linked lists with more than 2 nodes to speed up search time
    mdpram #(
        .DEPTH(NUM_CONNS),
        .WIDTH($clog2(NUM_CONNS)),
        .RD_LAT(1),
        .NUM_RD(2),
        .NUM_WR(2)
    ) ntwrk_remap_lut (
        .clk   (clk),
        .rst_n (rst_n),

        .raddr ({lookupa_raddr,  lookupb_raddr}),
        .ren   ({lookupa_active, lookupb_active}),
        .rdata ({lookupa_rdata,  lookupb_rdata}),

        .waddr ({lookupa_waddr, lookupb_waddr}),
        .wen   ({lookupa_wen,   lookupb_wen}),
        .wdata ({lookupa_wdata, lookupb_wdata})
    );

endmodule