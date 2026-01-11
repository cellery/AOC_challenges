
module sort_node #(
    parameter NUM_POINTS = 1000,
    parameter DIM_W      = 17,
    parameter SORT_OP    = 0 //0 - min sort, 1 - max sort
) (
    input  logic                            clk,
    input  logic                            rst_n,
    
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

    generate
        if(SORT_OP == 0) begin
            assign replace_node = !conn_cur_vld || (conn_in.distance < conn_cur.distance);
        end else if(SORT_OP == 1) begin
            assign replace_node = !conn_cur_vld || (conn_in.distance > conn_cur.distance);
        end else begin
            $fatal(1, "FATAL Error: Parameter SORT_OP (%0d) must be 0 or 1!", SORT_OP);
        end
    endgenerate

    //Replace node with new info
    always_ff @(posedge clk) begin
        conn_cur.distance <= replace_node  ? conn_in.distance  : conn_cur.distance;
        conn_cur.pointa   <= replace_node  ? conn_in.pointa    : conn_cur.pointa;
        conn_cur.pointb   <= replace_node  ? conn_in.pointb    : conn_cur.pointb;
        conn_cur_vld      <= !conn_cur_vld ? replace_node      : conn_cur_vld;

        if (!rst_n) begin
            conn_cur     <= '0;
            conn_cur_vld <= 1'b0;
        end
    end

    //Forward node downstream if required
    //assign shift_node = !replace_node && conn_in_vld && conn_in.distance > conn_cur.distance;
    always_ff @(posedge clk) begin
        conn_out.distance <= replace_node  ? conn_cur.distance : conn_in.distance;
        conn_out.pointa   <= replace_node  ? conn_cur.pointa   : conn_in.pointa;
        conn_out.pointb   <= replace_node  ? conn_cur.pointb   : conn_in.pointb;
        conn_out_vld      <= (conn_in_vld || replace_node) && conn_cur_vld;

        if (!rst_n) begin
            conn_out     <= '0;
            conn_out_vld <= 1'b0;
        end
    end

endmodule