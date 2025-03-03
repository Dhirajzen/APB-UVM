// APB Driver
class apb_driver extends uvm_driver #(apb_transaction);
  // UVM registration
  `uvm_component_utils(apb_driver)
  
  // Virtual interface
  virtual apb_if vif;
  
  // Config
  bit checks_enable = 1;
  bit coverage_enable = 1;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // Build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
  endfunction
  
  // Run phase
  virtual task run_phase(uvm_phase phase);
    // Reset handling
    reset_signals();
    
    forever begin
      apb_transaction req;
      
      // Get next transaction from sequencer
      seq_item_port.get_next_item(req);
      
      `uvm_info(get_type_name(), $sformatf("Driver processing transaction: \n%s", req.convert2string()), UVM_HIGH)
      
      // Drive transaction
      drive_transfer(req);
      
      // Notify sequencer of completion
      seq_item_port.item_done();
    end
  endtask
  
  // Reset APB signals
  virtual task reset_signals();
    @(posedge vif.PCLK);
    vif.PADDR <= 32'h0;
    vif.PWDATA <= 32'h0;
    vif.PWRITE <= 1'b0;
    vif.PSEL <= 1'b0;
    vif.PENABLE <= 1'b0;
  endtask
  
  // Drive a single APB transfer
  virtual task drive_transfer(apb_transaction req);
    // Setup phase
    @(posedge vif.PCLK);
    vif.PADDR <= req.addr;
    vif.PWDATA <= req.data;
    vif.PWRITE <= req.write;
    vif.PSEL <= 1'b1;
    vif.PENABLE <= 1'b0;
    
    // Access phase
    @(posedge vif.PCLK);
    vif.PENABLE <= 1'b1;
    
    // Wait for slave to be ready
    do begin
      @(posedge vif.PCLK);
    end while (!vif.PREADY);
    
    // Update transaction with response
    if (!req.write) begin
      req.read_data = vif.PRDATA;
    end
    req.error = vif.PSLVERR;
    
    // End of transfer
    vif.PSEL <= 1'b0;
    vif.PENABLE <= 1'b0;
    
    @(posedge vif.PCLK);
  endtask
endclass