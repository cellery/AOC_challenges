//Multi dual port RAM, parameterized number of read and write ports.
//TODO - Make flexible for any number of R+W combinations, for now just support 2R+2W

module mdpram #(
    parameter DEPTH = 1000,
    parameter WIDTH = 17,
    parameter RD_LAT = 1,
    //parameter WR_MODE = 0, //TODO - Support write before read mode, for now only support read first
    parameter NUM_RD = 2,
    parameter NUM_WR = 2
) (
    input  logic                           clk,
    input  logic                           rst_n,

    input  logic [$clog2(DEPTH)-1:0]       raddr [NUM_RD],
    input  logic                           ren   [NUM_RD],
    output logic [WIDTH-1:0]               rdata [NUM_RD],

    input  logic [$clog2(DEPTH)-1:0]       waddr [NUM_WR],
    input  logic                           wen   [NUM_WR],
    input  logic [WIDTH-1:0]               wdata [NUM_WR]
);

    if (RD_LAT < 1) begin
        $fatal(1, "FATAL Error: Parameter RD_LAT (%0d) must be greater than or equal to 1 for %m", RD_LAT);
    end else if (NUM_RD != 2) begin
        $fatal(1, "FATAL Error: Parameter NUM_RD (%0d) must be equal to 2 for %m", NUM_RD);
    end else if (NUM_WR != 2) begin
        $fatal(1, "FATAL Error: Parameter NUM_WR (%0d) must be equal to 2 for %m", NUM_WR);
    end

    //To support N number of read and write ports we need to multiply the two together
    //Great article about this topic here: https://tomverbeure.github.io/2019/08/03/Multiport-Memories.html
    logic [DEPTH-1:0][WIDTH-1:0]           mem [NUM_RD*NUM_WR];
    logic [DEPTH-1:0][$clog2(NUM_WR)-1:0]  mru;  //Most recently used table to mux correct read data

    //Rdata/mru pipeline signals
    logic [RD_LAT-1:0][WIDTH-1:0]          rdata_r [NUM_RD];
    logic [RD_LAT-1:0][$clog2(NUM_WR)-1:0] mru_r   [NUM_RD];
    

    //Write logic - we need to write to N memories simultaneously to handle N number of read ports
    always_ff @(posedge clk) begin
        for (int i=0; i<NUM_WR; i++) begin : mdpram_wr
            if(wen[i]) begin
                for (int j=0; j<NUM_RD; j++) begin
                    mem[i+j*NUM_RD][waddr[i]] <= wdata;
                    mru[waddr[i]] <= i[$clog2(NUM_WR)-1:0];
                end
            end
        end
    end

    //Read logic - we read out mru and pipeline it to match read data and use that to mux the final output for each read port
    generate
        for (genvar i=0; i<NUM_RD; i++) begin
            assign rdata[i] = rdata_r[mru_r[i][RD_LAT-1]][RD_LAT-1];
        end
    endgenerate

    always_ff @(posedge clk) begin
        for(int i=0;i<NUM_RD;i++) begin
            if (!rst_n) begin
                rdata_r[i] <= '0;
                mru_r[i] <= '0;
            end else if(ren[i]) begin
                for(int j=0;j<RD_LAT;j++) begin
                    rdata_r[i][j] <= (j==0) ? mem[i][raddr[i]] : rdata_r[i][j-1];
                    mru_r[i][j]   <= (j==0) ? mru[raddr[i]] : mru_r[i][j-1];
                end
            end
        end
    end
    
endmodule