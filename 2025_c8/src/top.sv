module top #(
    parameter NUM_POINTS = 1000,
    parameter DIM_W      = 17,
    parameter NUM_NTWRKS = 3
) (
    input logic             clk,
    input logic             rst_n,

    //Input points
    input logic [DIM_W-1:0] xloc,
    input logic [DIM_W-1:0] yloc,
    input logic [DIM_W-1:0] zloc,
    input logic             loc_vld,

    //Output answer
    output logic [$clog2(NUM_POINTS/2)*3-1:0] answer,
    output logic                              answer_vld
);

//Dist calculator nets
logic [((DIM_W+1)*2+2)-1:0]        approx_dist;
logic [$clog2(NUM_POINTS)-1:0]     pointa;
logic [$clog2(NUM_POINTS)-1:0]     pointb;
logic                              dist_vld;
   
//Network sorting nets   
logic [$clog2(NUM_POINTS)-1:0]     pointa_sort;
logic [$clog2(NUM_POINTS)-1:0]     pointb_sort;
logic                              points_sort_vld;
logic [$clog2(NUM_POINTS/2)-1:0]   ntwrk_sz [NUM_NTWRKS];
logic                              ntwrk_sz_vld;

//Answer logic
logic [$clog2(NUM_POINTS/2)*3-1:0] answer_i;

dist_calc  #(
    .NUM_POINTS(NUM_POINTS),
    .DIM_W     (DIM_W)
) dist_calc_i (
    .clk        (clk),
    .rst_n      (rst_n),
    
    .xloc       (xloc),
    .yloc       (yloc),
    .zloc       (zloc),
    .loc_vld    (loc_vld),
  
    .approx_dist(approx_dist),
    .pointa     (pointa),
    .pointb     (pointb),
    .dist_vld   (dist_vld)
);

ins_sorter  #(
    .NUM_POINTS(NUM_POINTS),
    .DIM_W     (DIM_W)
) ins_sorter_i (
    .clk        (clk),
    .rst_n      (rst_n),

    .approx_dist(approx_dist),
    .pointa_in  (pointa),
    .pointb_in  (pointb),
    .dist_vld   (dist_vld),

    .pointa_out (pointa_sort),
    .pointb_out (pointb_sort),
    .points_vld (points_sort_vld)
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