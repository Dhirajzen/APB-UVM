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

  // Slave memory (16 registers x 32 bits)
  logic [31:0] registers[16];
  
  // Internal signals
  logic [3:0] addr_index;
  logic       addr_valid;
  logic [31:0] prdata_reg; // Internal register for read data
  
  // Extract the valid address range
  assign addr_index = PADDR[5:2];
  assign addr_valid = (PADDR[31:6] == 0);
  
  // APB slave state machine
  typedef enum logic [1:0] {
    IDLE,
    SETUP,
    ACCESS
  } apb_state_t;
  
  apb_state_t current_state, next_state;
  
  // State machine sequential block
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end
  end
  
  // Next state logic
  always_comb begin
    case (current_state)
      IDLE: begin
        if (PSEL && !PENABLE)
          next_state = SETUP;
        else
          next_state = IDLE;
      end
      
      SETUP: begin
        if (PSEL && PENABLE)
          next_state = ACCESS;
        else
          next_state = IDLE;
      end
      
      ACCESS: begin
        if (PSEL && !PENABLE)
          next_state = SETUP;
        else
          next_state = IDLE;
      end
      
      default:
        next_state = IDLE;
    endcase
  end
  
  // Pre-load read data during SETUP phase
  // This ensures data is ready during ACCESS phase
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      prdata_reg <= 32'h0;
    end
    else if (current_state == SETUP && !PWRITE && addr_valid) begin
      // Pre-load read data during SETUP phase
      prdata_reg <= registers[addr_index];
    end
  end
  
  // Register access and output control
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      // Reset all registers
      for (int i = 0; i < 16; i++)
        registers[i] <= 32'h0;
      
      PRDATA <= 32'h0;
      PREADY <= 1'b1;  // Default to ready
      PSLVERR <= 1'b0; // Default to no error
    end
    else begin
      // Default values
      PREADY <= 1'b1;
      PSLVERR <= 1'b0;
      
      // Handle SETUP phase for read operations
      if (current_state == SETUP && PSEL && !PENABLE && !PWRITE) begin
        // No action needed here - handled in separate always_ff block
      end
      
      // Handle ACCESS phase
      if (current_state == ACCESS && PSEL && PENABLE) begin
        if (!addr_valid) begin
          // Invalid address access
          PSLVERR <= 1'b1;
        end
        else if (PWRITE) begin
          // Write operation
          registers[addr_index] <= PWDATA;
        end
        else begin
          // Read operation - use pre-loaded data
          PRDATA <= prdata_reg;
        end
      end
    end
  end
  
  // Debug functionality - uncomment for debug
  /*
  always_ff @(posedge PCLK) begin
    if (current_state == ACCESS && PSEL && PENABLE) begin
      if (PWRITE)
        $display("Time %0t: Write to reg[%0d] = 0x%8h", $time, addr_index, PWDATA);
      else
        $display("Time %0t: Read from reg[%0d] = 0x%8h", $time, addr_index, prdata_reg);
    end
  end
  */
  
endmodule