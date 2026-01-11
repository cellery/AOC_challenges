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
    input logic                            dist_done,

    //Output point tuple for network LUT
    output logic [$clog2(NUM_POINTS)-1:0]  pointa_out,
    output logic [$clog2(NUM_POINTS)-1:0]  pointb_out,
    output logic                           points_vld
);

    conn_t                          conn_out     [NUM_CONNS];
    logic                           conn_out_vld [NUM_CONNS];

    logic                           sort_done;
    logic  [$clog2(NUM_POINTS)-1:0] num_read_nodes;
    logic                           read_nodes;
    logic                           read_nodes_r;
    logic                           read_nodes_r2;

    assign read_nodes = sort_done && (num_read_nodes != NUM_CONNS);

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
                    .read        (read_nodes_r),
        
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
                    .read        (read_nodes_r),
        
                    .conn_in     (conn_out[i-1]),
                    .conn_in_vld (conn_out_vld[i-1]),

                    .conn_out     (conn_out[i]),
                    .conn_out_vld (conn_out_vld[i])
                );
            end
        end
    endgenerate

    always_ff @(posedge clk) begin
        sort_done <= !sort_done ? (dist_done && !conn_out_vld[NUM_CONNS-1]) : sort_done;
        read_nodes_r <= read_nodes;
        read_nodes_r2 <= read_nodes_r;
        num_read_nodes <= read_nodes ? num_read_nodes+1 : num_read_nodes;

        if(!rst_n) begin
            sort_done      <= 1'b0;
            read_nodes_r   <= 1'b0;
            num_read_nodes <= '0;
        end
    end

    assign pointa_out = conn_out[NUM_CONNS-1].pointa;
    assign pointb_out = conn_out[NUM_CONNS-1].pointb;
    assign points_vld = read_nodes_r2 && conn_out_vld[NUM_CONNS-1];

endmodule