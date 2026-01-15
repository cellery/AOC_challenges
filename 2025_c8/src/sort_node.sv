
module sort_node #(
    parameter NUM_POINTS = 1000,
    parameter DIM_W      = 17,
    parameter SORT_OP    = 0, //0 - min sort, 1 - max sort
    parameter LAST_NODE  = 0
) (
    input  logic                            clk,
    input  logic                            rst_n,
    input  logic                            read,
    input  logic                            forward_rdy,
    
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
    logic                            first_read;
    logic                            freeze;
    logic                            freeze_r;
    logic                            frozen;
    logic                            unfreeze;
    logic                            pending_data;

    conn_t                           pending_conn;
    logic                            pending_conn_vld;

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
        if(LAST_NODE == 1) begin //The last node does not freeze its data
            conn_cur.distance <= replace_node  ? conn_in.distance  : conn_cur.distance;
            conn_cur.pointa   <= replace_node  ? conn_in.pointa    : conn_cur.pointa;
            conn_cur.pointb   <= replace_node  ? conn_in.pointb    : conn_cur.pointb;
            conn_cur_vld      <= !conn_cur_vld ? replace_node : conn_cur_vld;
        end else begin
            conn_cur.distance <= (replace_node || freeze)  ? conn_in.distance  : conn_cur.distance;
            conn_cur.pointa   <= (replace_node || freeze)  ? conn_in.pointa    : conn_cur.pointa;
            conn_cur.pointb   <= (replace_node || freeze)  ? conn_in.pointb    : conn_cur.pointb;
            if(forward_mode) begin
                conn_cur_vld <= (freeze && !frozen) ? conn_in_vld : (unfreeze ? 1'b0 : conn_cur_vld);
            end else begin
                conn_cur_vld <= !conn_cur_vld ? replace_node : conn_cur_vld;
            end
        end

        if (!rst_n) begin
            conn_cur.distance <= (SORT_OP == 0) ? '1 : '0;
            conn_cur.pointa   <= '0;
            conn_cur.pointb   <= '0;
            conn_cur_vld      <= 1'b0;
        end
    end

    //Connection out will be the incoming connection if we're in forwarding more or we're not reading/replacing current node
    //Otherwise if we are reading or replacing current node then forward the current node out
    assign freeze = forward_mode && !forward_rdy;
    assign unfreeze = !freeze && freeze_r;
    assign first_read = read && !forward_mode;
    always_ff @(posedge clk) begin
        if(LAST_NODE == 1) begin //The last node does not freeze its data
            if (replace_node || first_read) begin
                conn_out.distance <= conn_cur.distance;
                conn_out.pointa   <= conn_cur.pointa;
                conn_out.pointb   <= conn_cur.pointb;
                conn_out_vld      <= conn_cur_vld;
            end else begin
                conn_out.distance <= conn_in.distance;
                conn_out.pointa   <= conn_in.pointa;
                conn_out.pointb   <= conn_in.pointb;
                conn_out_vld      <= conn_in_vld;
            end
        end else begin
            if ((forward_mode && unfreeze) || replace_node || first_read) begin
                conn_out.distance <= conn_cur.distance;
                conn_out.pointa   <= conn_cur.pointa;
                conn_out.pointb   <= conn_cur.pointb;
                conn_out_vld      <= conn_cur_vld;
            end else if(freeze || frozen) begin
                conn_out.distance <= conn_out.distance;
                conn_out.pointa   <= conn_out.pointa;
                conn_out.pointb   <= conn_out.pointb;
                conn_out_vld      <= 1'b0;
            end else begin
                conn_out.distance <= conn_in.distance;
                conn_out.pointa   <= conn_in.pointa;
                conn_out.pointb   <= conn_in.pointb;
                conn_out_vld      <= conn_in_vld && !freeze;
            end
        end

        //Switch to forwarding mode once we get the read signal
        forward_mode <= read ? 1'b1 : forward_mode;

        //Freeze logic
        freeze_r     <= freeze;
        frozen       <= !frozen ? freeze : !unfreeze;

        if (!rst_n) begin
            conn_out     <= '0;
            conn_out_vld <= 1'b0;
            forward_mode <= 1'b0;
            freeze_r <= 1'b0;
            frozen <= 1'b0;
            pending_data <= 1'b0;
        end
    end

endmodule