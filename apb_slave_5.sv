// APB Slave Implementation (Memory-mapped Registers)
module apb_slave (
  // Clock and Reset
  input  logic        PCLK,
  input  logic        PRESETn,
  
  // APB Interface
  input  logic [31:0] PADDR,
  input  logic        PSEL,
  input  logic        PENABLE,
  input  logic        PWRITE,
  input  logic [31:0] PWDATA,
  output logic [31:0] PRDATA,
  output logic        PREADY,
  output logic        PSLVERR
);

  // Memory array for registers (16 registers)
  logic [31:0] mem [0:15];
  
  // State machine definition
  logic [1:0] ps, ns;
  localparam IDLE = 2'b00;
  localparam SETUP = 2'b01;
  localparam ACCESS = 2'b10;
  
  // Extract register index from address
  logic [3:0] addr_index;
  assign addr_index = PADDR[5:2];
  
  // Address validity check
  logic addr_valid;
  assign addr_valid = (PADDR[31:6] == 0);
  
  // State register update
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      // Reset state
      ps <= IDLE;
      
      // Initialize memory
      for (int i = 0; i < 16; i++) begin
        mem[i] <= 32'h0;
      end
    end
    else begin
      ps <= ns;
      
      // Handle write operation in the ACCESS state
      if (ps == ACCESS && PSEL && PENABLE && PWRITE && addr_valid) begin
        mem[addr_index] <= PWDATA;
      end
    end
  end
  
  // Combinational logic for next state and outputs
  always_comb begin
    // Default values
    ns = ps;
    PREADY = 1'b1;
    PSLVERR = 1'b0;
    PRDATA = 32'h0;
    
    case(ps)
      IDLE: begin
        if (PSEL && !PENABLE)
          ns = SETUP;
      end
      
      SETUP: begin
        if (PSEL && PENABLE)
          ns = ACCESS;
      end
      
      ACCESS: begin
        if (!PSEL || !PENABLE)
          ns = IDLE;
        else
          ns = ACCESS; // Stay in ACCESS if PSEL and PENABLE remain high
          
        // Error for invalid address
        if (!addr_valid)
          PSLVERR = 1'b1;
        
        // Drive read data during read ACCESS phase
        if (!PWRITE) begin
          if (addr_valid)
            PRDATA = mem[addr_index];
          else
            PRDATA = 32'h0;
        end
      end
      
      default: begin
        ns = IDLE;
      end
    endcase
  end
  
endmodule