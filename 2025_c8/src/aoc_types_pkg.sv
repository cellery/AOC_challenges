package aoc_types_pkg;

    parameter DIM_W = `DIM_W;
    parameter NUM_POINTS = `NUM_POINTS;

    typedef struct packed {
        logic [((DIM_W+1)*2+2)-1:0]    distance;
        logic [$clog2(NUM_POINTS)-1:0] pointa;
        logic [$clog2(NUM_POINTS)-1:0] pointb;
    } conn_t;
endpackage