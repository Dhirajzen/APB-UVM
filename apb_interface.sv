// APB Interface Definition
interface apb_if (input logic PCLK, input logic PRESETn);
  // APB Signals
  logic [31:0] PADDR;    // Address bus
  logic        PSEL;     // Select signal
  logic        PENABLE;  // Enable signal
  logic        PWRITE;   // Write control signal
  logic [31:0] PWDATA;   // Write data bus
  logic [31:0] PRDATA;   // Read data bus
  logic        PREADY;   // Ready signal from slave
  logic        PSLVERR;  // Error response

  // Modport for Master
  modport master (
    output PADDR, PSEL, PENABLE, PWRITE, PWDATA,
    input  PRDATA, PREADY, PSLVERR
  );

  // Modport for Slave
  modport slave (
    input  PADDR, PSEL, PENABLE, PWRITE, PWDATA,
    output PRDATA, PREADY, PSLVERR
  );

  // Modport for Monitor
  modport monitor (
    input PADDR, PSEL, PENABLE, PWRITE, PWDATA, PRDATA, PREADY, PSLVERR
  );

  // Helper tasks for verification
  task automatic wait_for_transfer_complete();
    wait(PSEL && PENABLE && PREADY);
    @(posedge PCLK);
  endtask

  // Helper functions
  function automatic bit is_active();
    return (PSEL == 1'b1);
  endfunction

  function automatic bit is_transfer_phase();
    return (PSEL == 1'b1 && PENABLE == 1'b1);
  endfunction
endinterface