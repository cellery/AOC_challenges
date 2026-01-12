// Write a synchronous fifo

module sfifo #(
  parameter DWIDTH = 64,
  parameter DEPTH = 16,
  parameter AFULL = 1
) (
  input  logic clk,
  input  logic rst_n,
  
  input  logic [DWIDTH-1:0] din,
  input  logic wr_en,
  
  output logic [DWIDTH-1:0] dout,
  input  logic rd_en,
  
  output logic full,
  output logic afull,
  output logic empty
  
);

  if (AFULL >= DEPTH) begin
        $fatal(1, "FATAL Error: Parameter AFULL (%0d) must be less than DEPTH (%0d) %m", AFULL, DEPTH);
    end
  
  logic [DWIDTH-1:0]      fifo    [DEPTH];
  logic [$clog2(DEPTH):0] wr_addr;
  logic [$clog2(DEPTH):0] wr_addr_afull;
  logic [$clog2(DEPTH):0] rd_addr;

  logic [$clog2(DEPTH):0] occ;

  assign empty = wr_addr                    == rd_addr;
  assign full  = wr_addr[$clog2(DEPTH)]     != rd_addr[$clog2(DEPTH)] &&
                 wr_addr[$clog2(DEPTH)-1:0] == rd_addr[$clog2(DEPTH)-1:0];

  assign occ = (wr_addr < rd_addr) ? (DEPTH + wr_addr) - rd_addr : wr_addr - rd_addr;
  assign afull = DEPTH - occ <= AFULL;
  
  always_ff @(posedge clk) begin
    wr_addr <= ~full || rd_en ? wr_addr + {{$clog2(DEPTH)-1{1'b0}}, wr_en} : wr_addr;
    rd_addr <= ~empty         ? rd_addr + {{$clog2(DEPTH)-1{1'b0}}, rd_en} : rd_addr;
    
    if(~rst_n) begin
      wr_addr <= '0;
      rd_addr <= '0;
    end
  end
  
  assign dout = fifo[rd_addr[$clog2(DEPTH)-1:0]];
  always @(posedge clk) begin
    if(wr_en & ~full) fifo[wr_addr[$clog2(DEPTH)-1:0]] <= din;
  end

endmodule