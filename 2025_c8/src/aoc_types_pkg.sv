package aoc_types_pkg;

    parameter DIM_W = `DIM_W;
    parameter NUM_POINTS = `NUM_POINTS;
    parameter MAX_NTWRKS = NUM_POINTS/2;

    typedef struct packed {
        logic [((DIM_W+1)*2+2)-1:0]    distance;
        logic [$clog2(NUM_POINTS)-1:0] pointa;
        logic [$clog2(NUM_POINTS)-1:0] pointb;
    } conn_t;

    typedef enum bit[2:0] {
        NEW,    //000
        WR_A,   //001
        WR_B,   //010
        MERGE,  //011
        IGNORE, //100
        LOOKUP  //101
    } ntwrk_cmd_id_t;

    typedef struct packed {
        logic                          prev_vld;
        logic [$clog2(MAX_NTWRKS)-1:0] prev_id;
        logic                          next_vld;
        logic [$clog2(MAX_NTWRKS)-1:0] next_id;
        logic                          valid;
    } ntwrk_remap_node_t;

    typedef struct packed {
        logic [$clog2(MAX_NTWRKS)-1:0] ntwrkb;
        logic [$clog2(MAX_NTWRKS)-1:0] ntwrka;
        ntwrk_cmd_id_t                 cmd;
    } ntwrk_size_cmd_t;
endpackage