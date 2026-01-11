//Placeholder for Xilinx SDPRAM macro

module sdpram #(
    parameter DEPTH = 1000,
    parameter WIDTH = 17,
    parameter RD_LAT = 1,
    parameter WR_MODE = 0 //Write mode for when raddr == waddr. 1 write before read : 0 read before write
) (
    input  logic                           clk,
    input  logic                           rst_n,

    input  logic [$clog2(DEPTH)-1:0]       raddr,
    input  logic                           ren,
    output logic [WIDTH-1:0]               rdata,

    input  logic [$clog2(DEPTH)-1:0]       waddr,
    input  logic                           wen,
    input  logic [WIDTH-1:0]               wdata
);

    logic write_before_read;

    assign write_before_read = WR_MODE==1 ? wen && (waddr == raddr) : 1'b0;

    if (RD_LAT < 1) begin
        $fatal(1, "FATAL Error: Parameter RD_LAT (%0d) must be greater than or equal to 1 for %m", RD_LAT);
    end

    logic [WIDTH-1:0] mem [DEPTH];

    logic [WIDTH-1:0] rdata_r [RD_LAT];

    always_ff @(posedge clk) begin
        if(wen) begin
            mem[waddr] <= wdata;
        end
    end

    assign rdata = rdata_r[RD_LAT-1];
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rdata_r[RD_LAT-1:0] <= '{default: '0};
        end else if(ren) begin
            for(int i=0;i<RD_LAT;i++) begin
                rdata_r[i] <= (i==0) ? ((write_before_read) ? wdata : mem[raddr]) : rdata_r[i-1];
            end
        end
    end
    
endmodule