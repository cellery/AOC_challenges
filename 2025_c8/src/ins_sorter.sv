//Insert sorter is a shift register that shifts in new values and will sort them either min or max depending on params
//import aoc_types_pkg::*;

module ins_sorter #(
    parameter NUM_POINTS = 1000,
    parameter NUM_CONNS  = 1000,
    parameter DIM_W      = 17,
    parameter SORT_OP    = 0 //0 - min sort, 1 - max sort
) (
    input logic                            clk,
    input logic                            rst_n,
    
    //Dist/point tuple to use for sorting
    input conn_t                           conn_in,
    input logic                            conn_in_vld,

    //Output point tuple for network LUT
    output logic [$clog2(NUM_POINTS)-1:0]  pointa_out,
    output logic [$clog2(NUM_POINTS)-1:0]  pointb_out,
    output logic                           points_vld
);

    conn_t conn_out     [NUM_CONNS];
    logic  conn_out_vld [NUM_CONNS];

    generate
        for(genvar i=0; i<NUM_CONNS; i++) begin : sort_node_loop
            if(i==0) begin : first_node
                sort_node #(
                    .NUM_POINTS(NUM_POINTS),
                    .DIM_W(DIM_W),
                    .SORT_OP(0)
                ) node (
                    .clk         (clk),
                    .rst_n       (rst_n),
        
                    .conn_in     (conn_in),
                    .conn_in_vld (conn_in_vld),

                    .conn_out     (conn_out[i]),
                    .conn_out_vld (conn_out_vld[i])
                );
            end else begin : next_nodes
                sort_node #(
                    .NUM_POINTS(NUM_POINTS),
                    .DIM_W(DIM_W),
                    .SORT_OP(0)
                ) node (
                    .clk         (clk),
                    .rst_n       (rst_n),
        
                    .conn_in     (conn_out[i-1]),
                    .conn_in_vld (conn_out_vld[i-1]),

                    .conn_out     (conn_out[i]),
                    .conn_out_vld (conn_out_vld[i])
                );
            end
        end
    endgenerate

    assign pointa_out = conn_out[NUM_CONNS-1].pointa;
    assign pointb_out = conn_out[NUM_CONNS-1].pointb;
    assign points_vld = conn_out_vld[NUM_CONNS-1];

endmodule