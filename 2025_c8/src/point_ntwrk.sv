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
    output logic       [$clog2(NUM_CONNS):0] ntwrk_sz [NUM_NTWRKS],
    output logic                             ntwrk_sz_final
);

    localparam NTWRK_ID_W = $clog2(NUM_CONNS+1);
    localparam NTWRK_SZ_W = $clog2(NUM_CONNS) + 1;

    //Points to new network id when we create one
    logic [NTWRK_ID_W-1:0] max_ntwrk_id;
    logic [NTWRK_ID_W-1:0] max_ntwrk_id_r;

    //Point -> Network signals 
    logic [NTWRK_ID_W-1:0]  ntwrka_lu_id;
    logic [NTWRK_ID_W-1:0]  ntwrkb_lu_id;
    logic [$clog2(NUM_POINTS)-1:0] pointa_in_r;
    logic [$clog2(NUM_POINTS)-1:0] pointb_in_r;
    logic                          read_in_point;
    logic                          read_in_point_r;

    logic                          pointa_ntwrk_wr_en;
    logic [$clog2(NUM_POINTS)-1:0] pointa_ntwrk_wr_addr;
    logic [NTWRK_ID_W-1:0]  pointa_ntwrk_wr_data;
    logic                          pointb_ntwrk_wr_en;
    logic [$clog2(NUM_POINTS)-1:0] pointb_ntwrk_wr_addr;
    logic [NTWRK_ID_W-1:0]  pointb_ntwrk_wr_data;


    //Point -> Network signals
    ntwrk_cmd_id_t                 point_ntwrk_action;
    logic                          point_ntwrk_started;
    logic                          point_ntwrk_finished;

    //Network lookup/remap table signals
    logic                          lookupa_active;
    logic                          lookupa_en;
    logic [NTWRK_ID_W-1:0]  lookupa_raddr;
    logic [NTWRK_ID_W-1:0]  lookupa_rdata;
    logic [NTWRK_ID_W-1:0]  lookupa_ntwrk;
    logic                          lookupa_wen;
    logic [NTWRK_ID_W-1:0]  lookupa_waddr;
    logic [NTWRK_ID_W-1:0]  lookupa_wdata;
    logic [$clog2(NUM_POINTS)-1:0] lookupa_orig_point;
    logic [NTWRK_ID_W-1:0]  lookupa_orig_ntwrk;

    logic                          lookupb_active;
    logic                          lookupb_en;
    logic [NTWRK_ID_W-1:0]  lookupb_raddr;
    logic [NTWRK_ID_W-1:0]  lookupb_rdata;
    logic [NTWRK_ID_W-1:0]  lookupb_ntwrk;
    logic                          lookupb_wen;
    logic [NTWRK_ID_W-1:0]  lookupb_waddr;
    logic [NTWRK_ID_W-1:0]  lookupb_wdata;
    logic [$clog2(NUM_POINTS)-1:0] lookupb_orig_point;
    logic [NTWRK_ID_W-1:0]  lookupb_orig_ntwrk;

    //Remap signals, active while we're doing lookups for a/b networks
    logic                          remap_active;
    logic                          remap_done;
    ntwrk_cmd_id_t                 remap_ntwrk_action;
    ntwrk_cmd_id_t                 remap_ntwrk_action_r;

    //Network size table signals
    logic   [NTWRK_ID_W-1:0]  ntwrka_sz_raddr;
    logic   [NTWRK_ID_W-1:0]  ntwrka_sz_raddr_r;
    logic                          ntwrka_sz_ren;
    logic                          ntwrka_sz_ren_r;
    logic   [NTWRK_SZ_W-1:0]  ntwrka_sz_rdata;
    logic   [NTWRK_ID_W-1:0]  ntwrka_sz_waddr;
    logic                          ntwrka_sz_wen;
    logic   [NTWRK_SZ_W-1:0]  ntwrka_sz_wdata;
 
    logic   [NTWRK_ID_W-1:0]  ntwrkb_sz_raddr;
    logic   [NTWRK_ID_W-1:0]  ntwrkb_sz_raddr_r;
    logic                          ntwrkb_sz_ren;
    logic                          ntwrkb_sz_ren_r;
    logic   [NTWRK_SZ_W-1:0]  ntwrkb_sz_rdata;
    logic   [NTWRK_ID_W-1:0]  ntwrkb_sz_waddr;
    logic                          ntwrkb_sz_wen;
    logic   [NTWRK_SZ_W-1:0]  ntwrkb_sz_wdata;

    //Network size tracking
    logic          [NUM_CONNS-1:0] ntwrk_sz_vld; //Register for tracking which network sizes are valid
    logic                          ntwrk_sz_search_start;
    logic                          ntwrk_sz_search_done;
    logic                          ntwrk_sz_search_active;
    logic                          ntwrk_sz_search_active_r;
    logic    [NTWRK_ID_W-1:0] ntwrk_sz_search_addr;

    logic   [NTWRK_SZ_W-1:0]  ntwrk_max_sz[NUM_NTWRKS];
    logic        [NUM_NTWRKS-1:0]  ntwrk_max_sz_gt;
    logic        [NUM_NTWRKS-1:0]  ntwrk_max_sz_gt_prev;
    

    //Ready logic, we have to backpressure whenever we get a new point until we can update all tables with this new connection as needed
    //TODO - See if we can pipeline this better and not backpressure as frequently, can we read old point data out and still use it?
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

    //Point to network table should be updated anytime a new network is created or merged or we are connecting the point to an existing network
    assign pointa_ntwrk_wr_en   = point_ntwrk_action == NEW || remap_ntwrk_action == WR_A || remap_ntwrk_action == MERGE;
    assign pointb_ntwrk_wr_en   = point_ntwrk_action == NEW || remap_ntwrk_action == WR_B || remap_ntwrk_action == MERGE;
    assign pointa_ntwrk_wr_addr = (remap_ntwrk_action == WR_A || remap_ntwrk_action == MERGE) ? lookupa_orig_point : pointa_in_r; 
    assign pointb_ntwrk_wr_addr = (remap_ntwrk_action == WR_B || remap_ntwrk_action == MERGE) ? lookupb_orig_point : pointb_in_r; 
    assign pointa_ntwrk_wr_data = remap_ntwrk_action == WR_A ? lookupb_ntwrk : max_ntwrk_id;
    assign pointb_ntwrk_wr_data = remap_ntwrk_action == WR_B ? lookupa_ntwrk : max_ntwrk_id;

    mdpram #(
        .DEPTH(NUM_POINTS),
        .WIDTH(NTWRK_ID_W),
        .RD_LAT(1),
        .NUM_RD(2),
        .NUM_WR(2)
    ) point_ntwrk_lut (
        .clk   (clk),
        .rst_n (rst_n),

        .raddr ({pointa_in,     pointb_in}),
        .ren   ({points_in_vld, points_in_vld}),
        .rdata ({ntwrka_lu_id,  ntwrkb_lu_id}),

        .waddr ({pointa_ntwrk_wr_addr, pointb_ntwrk_wr_addr}),
        .wen   ({pointa_ntwrk_wr_en, pointb_ntwrk_wr_en}),
        .wdata ({pointa_ntwrk_wr_data, pointb_ntwrk_wr_data})
    );

    always_ff @(posedge clk) begin
        pointa_in_r          <= pointa_in;
        pointb_in_r          <= pointb_in;
        max_ntwrk_id         <= (point_ntwrk_action == NEW || remap_ntwrk_action == MERGE) ? max_ntwrk_id+1 : max_ntwrk_id; 
        read_in_point_r      <= read_in_point;
        point_ntwrk_started  <= !point_ntwrk_started ? read_in_point : point_ntwrk_started;
        point_ntwrk_finished <= point_ntwrk_started ? !points_in_vld : point_ntwrk_finished;
        
        if(!rst_n) begin
            pointa_in_r          <= '0;
            pointb_in_r          <= '0;
            max_ntwrk_id         <= '0;
            read_in_point_r      <= '0;
            point_ntwrk_started  <= '0;
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
        .DEPTH(NUM_CONNS+1), //0 is reserved so we need one extra entry in memory to handle worse number of networks
        .WIDTH(NTWRK_ID_W),
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

    //Read port a is used to do all single network size updates/reads, Port b is used to read out second size for a merge and for final size readout
    assign ntwrka_sz_ren   =  remap_ntwrk_action == WR_A || remap_ntwrk_action == WR_B || remap_ntwrk_action == MERGE;
    assign ntwrka_sz_raddr =  (remap_ntwrk_action == MERGE || remap_ntwrk_action == WR_B) ? lookupa_ntwrk : lookupb_ntwrk;
    assign ntwrkb_sz_ren   =  remap_ntwrk_action == MERGE || ntwrk_sz_search_active;
    assign ntwrkb_sz_raddr =  ntwrk_sz_search_active ? ntwrk_sz_search_addr : lookupb_ntwrk;

    always_ff @(posedge clk) begin
        ntwrka_sz_ren_r      <= ntwrka_sz_ren;
        ntwrkb_sz_ren_r      <= ntwrkb_sz_ren;
        max_ntwrk_id_r       <= max_ntwrk_id;
        remap_ntwrk_action_r <= remap_ntwrk_action;
        ntwrka_sz_raddr_r    <= ntwrka_sz_raddr;
        ntwrkb_sz_raddr_r    <= ntwrkb_sz_raddr;

        if (!rst_n) begin
            ntwrka_sz_ren_r      <= 1'b0;
            ntwrkb_sz_ren_r      <= 1'b0;
            max_ntwrk_id_r       <= '0;
            remap_ntwrk_action_r <= IGNORE;
            ntwrka_sz_raddr_r    <= '0;
            ntwrkb_sz_raddr_r    <= '0;
        end
    end

    assign ntwrka_sz_wen   = point_ntwrk_action == NEW;
    assign ntwrka_sz_waddr = max_ntwrk_id;
    assign ntwrka_sz_wdata = 'd2;

    always_ff @(posedge clk) begin
        for(int i=0; i<NUM_CONNS+1; i++) begin
            if(~rst_n) begin
                ntwrk_sz_vld[i] <= 1'b0;
            end else if((point_ntwrk_action == NEW && i[NTWRK_ID_W-1:0] == max_ntwrk_id) || (remap_ntwrk_action_r == MERGE && i[NTWRK_ID_W-1:0] == max_ntwrk_id_r)) begin
                ntwrk_sz_vld[i] <= 1'b1;
            end else if(remap_ntwrk_action_r == MERGE && (i[NTWRK_ID_W-1:0] == ntwrka_sz_raddr_r || i[NTWRK_ID_W-1:0] == ntwrkb_sz_raddr_r)) begin
                ntwrk_sz_vld[i] <= 1'b0;
            end else begin
                ntwrk_sz_vld[i] <= ntwrk_sz_vld[i];
            end
        end
    end

    assign ntwrkb_sz_wen   = ntwrka_sz_ren_r || ntwrkb_sz_ren_r && !ntwrk_sz_search_active_r;
    assign ntwrkb_sz_waddr = remap_ntwrk_action_r == MERGE ? max_ntwrk_id_r                    : ntwrka_sz_raddr_r;
    assign ntwrkb_sz_wdata = remap_ntwrk_action_r == MERGE ? ntwrka_sz_rdata + ntwrkb_sz_rdata : ntwrka_sz_rdata + 'd1;

    //Table contains a list of memory sizes, need 2 read ports to read out when merging networks.
    //TODO - One of the write ports could probably be optimized away as we only really use it in 
    //       the event that a merge is followed on the next cycle by NEW as on that cycle we have to 
    //       write sizes for two different networks.
    mdpram #(
        .DEPTH(NUM_CONNS+1), //0 is reserved so we need one extra entry in memory to handle worse number of networks
        .WIDTH(NTWRK_SZ_W),
        .RD_LAT(1),
        .NUM_RD(2),
        .NUM_WR(2)
    ) ntwrk_sz_table (
        .clk   (clk),
        .rst_n (rst_n),

        .raddr ({ntwrka_sz_raddr, ntwrkb_sz_raddr}),
        .ren   ({ntwrka_sz_ren,   ntwrkb_sz_ren}),
        .rdata ({ntwrka_sz_rdata, ntwrkb_sz_rdata}),

        .waddr ({ntwrka_sz_waddr, ntwrkb_sz_waddr}),
        .wen   ({ntwrka_sz_wen,   ntwrkb_sz_wen}),
        .wdata ({ntwrka_sz_wdata, ntwrkb_sz_wdata})
    );
    
    //Network size search logic, we start once there are no more new points and all remapping, size tables updates are done
    assign ntwrk_sz_search_start = point_ntwrk_finished && !remap_active && !ntwrkb_sz_wen;
    assign ntwrk_sz_search_done  = ntwrk_sz_search_addr == NUM_CONNS+1;
    assign ntwrk_sz_search_active = ntwrk_sz_search_start && !ntwrk_sz_search_done;
    always_ff @(posedge clk) begin
        ntwrk_sz_search_active_r <= ntwrk_sz_search_active;
        ntwrk_sz_search_addr <= (ntwrk_sz_search_start && !ntwrk_sz_search_done) ? ntwrk_sz_search_addr + 'd1 : ntwrk_sz_search_addr;

        if(!rst_n) begin
            ntwrk_sz_search_active_r   <= 1'b0;
            ntwrk_sz_search_addr       <= 'b0;
        end
    end

    //Simple max insert sorter for tracking largest network sizes
    //NOTE - This could generate a nasty rats nest of wires for large output networks but since 
    //       we only sort 3 at the moment this should be reasonable to synthesize
    //       Alternative more scalable solution would be similar to the ins_sorter block used for conns
    generate
        for(genvar i=0; i<NUM_NTWRKS; i++) begin
            assign ntwrk_max_sz_gt[i]           = ntwrkb_sz_rdata > ntwrk_max_sz[i];
            if(i == 0) begin
                assign ntwrk_max_sz_gt_prev[i]  = 1'b0;
            end else begin
                assign ntwrk_max_sz_gt_prev[i]  = |ntwrk_max_sz_gt[i-1:0];
            end
        end
    endgenerate
    
    always_ff @(posedge clk) begin
        for(int i=0; i<NUM_NTWRKS; i++) begin
            if(!rst_n) begin
                ntwrk_max_sz[i]    <= 'd2;
            end else if (ntwrk_sz_search_active_r && ntwrk_sz_vld[ntwrkb_sz_raddr_r]) begin
                if(ntwrk_max_sz_gt[i] && !ntwrk_max_sz_gt_prev[i]) begin //First index where size is greater so we insert into this register
                    ntwrk_max_sz[i]    <= ntwrkb_sz_rdata;
                end else if(ntwrk_max_sz_gt[i] && ntwrk_max_sz_gt_prev[i]) begin //Data needs to be shifted down
                    ntwrk_max_sz[i] <= ntwrk_max_sz[i-1];
                end
            end
        end
    end

    assign ntwrk_sz       = ntwrk_max_sz;
    assign ntwrk_sz_final = ntwrk_sz_search_done;

endmodule