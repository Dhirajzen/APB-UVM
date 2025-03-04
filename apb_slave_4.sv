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
  logic [15:0] [31:0] registers;
  
  // Internal signals
  logic [3:0] addr_index;
  logic       addr_valid;
  
  // Extract the valid address range
  assign addr_index = PADDR[5:2];
  assign addr_valid = (PADDR[31:6] == 0);
  
  // APB state machine states
  typedef enum logic [1:0] {
    IDLE    = 2'b00,
    SETUP   = 2'b01,
    ACCESS  = 2'b10
  } apb_state_t;
  
  apb_state_t apb_st;
  
  // State machine and data handling
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      // Reset all signals and registers
      apb_st <= IDLE;
      PRDATA <= 32'h0;
      PREADY <= 1'b1;  // Always ready in this simple implementation
      PSLVERR <= 1'b0;
      
      // Reset all registers to 0
      for (int i = 0; i < 16; i++) begin
        registers[i] <= 32'h0;
      end
    end
    else begin
      // Default values
      PREADY <= 1'b1;  // Always ready for now
      PSLVERR <= 1'b0;
      
      case (apb_st)
        IDLE: begin
          // Transition to SETUP when selected
          if (PSEL && !PENABLE) begin
            apb_st <= SETUP;
          end
        end
        
        SETUP: begin
          // In SETUP phase, prepare for read operations
          if (PSEL && !PENABLE) begin
            if (!PWRITE && addr_valid) begin
              // Prepare read data
              PRDATA <= registers[addr_index];
            end
            
            if (!addr_valid) begin
              // Signal error for invalid address
              PSLVERR <= 1'b1;
            end
          end
          
          // Move to ACCESS phase when PENABLE is asserted
          if (PSEL && PENABLE) begin
            apb_st <= ACCESS;
          end
        end
        
        ACCESS: begin
          if (PSEL && PENABLE) begin
            if (!addr_valid) begin
              // Invalid address access
              PSLVERR <= 1'b1;
            end
            else if (PWRITE) begin
              // Write operation to valid address
              registers[addr_index] <= PWDATA;
            end
            // For read, data was already set up in SETUP state
          end
          
          // Return to IDLE after this cycle
          apb_st <= IDLE;
        end
        
        default: begin
          apb_st <= IDLE;
        end
      endcase
    end
  end
  
  // Debug functionality - uncomment for debug
  /*
  always_ff @(posedge PCLK) begin
    if (PSEL && PENABLE) begin
      if (PWRITE)
        $display("Time %0t: Write to reg[%0d] = 0x%8h", $time, addr_index, PWDATA);
      else
        $display("Time %0t: Read from reg[%0d] = 0x%8h", $time, addr_index, registers[addr_index]);
    end
  end
  */
  
endmodule