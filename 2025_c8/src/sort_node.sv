
module sort_node #(
    parameter NUM_POINTS = 1000,
    parameter DIM_W      = 17,
    parameter SORT_OP    = 0 //0 - min sort, 1 - max sort
) (
    input  logic                            clk,
    input  logic                            rst_n,
    input  logic                            read,
    
    //New distance that needs to be sorted
    input  conn_t                           conn_in,
    input  logic                            conn_in_vld,

    //New distance to be sorted sent downstream
    output conn_t                           conn_out,
    output logic                            conn_out_vld
);

    conn_t                           conn_cur;
    logic                            conn_cur_vld;

    logic                            replace_node;
    logic                            shift_node;
    logic                            forward_mode;

    always_comb begin
        if(SORT_OP == 0) begin
            replace_node = (!conn_cur_vld || conn_in.distance < conn_cur.distance) && conn_in_vld && !read && !forward_mode;
        end else if(SORT_OP == 1) begin
            replace_node = (!conn_cur_vld || conn_in.distance > conn_cur.distance) && conn_in_vld && !read && !forward_mode;
        end else begin
            $fatal(1, "FATAL Error: Parameter SORT_OP (%0d) must be 0 or 1!", SORT_OP);
        end
    end

    //Replace node with new info
    always_ff @(posedge clk) begin
        conn_cur.distance <= replace_node  ? conn_in.distance  : conn_cur.distance;
        conn_cur.pointa   <= replace_node  ? conn_in.pointa    : conn_cur.pointa;
        conn_cur.pointb   <= replace_node  ? conn_in.pointb    : conn_cur.pointb;
        conn_cur_vld      <= !conn_cur_vld ? replace_node      : conn_cur_vld;

        if (!rst_n) begin
            conn_cur.distance <= (SORT_OP == 0) ? '1 : '0;
            conn_cur.pointa   <= '0;
            conn_cur.pointb   <= '0;
            conn_cur_vld      <= 1'b0;
        end
    end

    //Connection out will be the incoming connection if we're in forwarding more or we're not reading/replacing current node
    //Otherwise if we are reading or replacing current node then forward the current node out
    always_ff @(posedge clk) begin
        conn_out.distance <= (replace_node || read) && !forward_mode  ? conn_cur.distance : conn_in.distance;
        conn_out.pointa   <= (replace_node || read) && !forward_mode  ? conn_cur.pointa   : conn_in.pointa;
        conn_out.pointb   <= (replace_node || read) && !forward_mode  ? conn_cur.pointb   : conn_in.pointb;
        conn_out_vld      <= forward_mode ? conn_in_vld : ((replace_node || read) ? conn_cur_vld : conn_in_vld);

        //Switch to forwarding mode once we get the read signal
        forward_mode <= read ? 1'b1 : forward_mode;

        if (!rst_n) begin
            conn_out     <= '0;
            conn_out_vld <= 1'b0;
            forward_mode <= 1'b0;
        end
    end

endmodule