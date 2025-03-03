// APB Monitor
class apb_monitor extends uvm_monitor;
  // UVM registration
  `uvm_component_utils(apb_monitor)
  
  // Virtual interface
  virtual apb_if vif;
  
  // Analysis port
  uvm_analysis_port #(apb_transaction) item_collected_port;
  
  // Collected transaction
  apb_transaction trans_collected;
  
  // Config
  bit checks_enable = 1;
  bit coverage_enable = 1;
  
  // Coverage
  covergroup apb_transfer_cg;
    option.per_instance = 1;
    
    TRANSFER_TYPE: coverpoint trans_collected.write {
      bins read  = {0};
      bins write = {1};
    }
    
    TRANSFER_ADDR: coverpoint trans_collected.addr[5:2] {
      bins registers[16] = {[0:15]};
    }
    
    TRANSFER_ERROR: coverpoint trans_collected.error {
      bins no_error = {0};
      bins error = {1};
    }
    
    ADDR_X_ERROR: cross TRANSFER_ADDR, TRANSFER_ERROR;
    TYPE_X_ERROR: cross TRANSFER_TYPE, TRANSFER_ERROR;
  endgroup
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
    trans_collected = new();
    apb_transfer_cg = new();
  endfunction
  
  // Build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
  endfunction
  
  // Run phase
  virtual task run_phase(uvm_phase phase);
    forever begin
      collect_transfer();
      
      // Check and coverage
      if (checks_enable) begin
        perform_transfer_checks();
      end
      
      if (coverage_enable) begin
        perform_transfer_coverage();
      end
      
      // Send transaction to analysis port
      item_collected_port.write(trans_collected);
    end
  endtask
  
  // Collect one APB transfer
  virtual task collect_transfer();
    // Create new transaction object
    trans_collected = apb_transaction::type_id::create("trans_collected");
    
    // Wait for start of transfer (PSEL asserted, PENABLE deasserted)
    @(posedge vif.PCLK);
    while(!(vif.PSEL === 1'b1 && vif.PENABLE === 1'b0)) @(posedge vif.PCLK);
    
    // Collect data from setup phase
    trans_collected.addr = vif.PADDR;
    trans_collected.write = vif.PWRITE;
    if (vif.PWRITE)
      trans_collected.data = vif.PWDATA;
    
    // Wait for enable phase
    @(posedge vif.PCLK);
    
    // Wait for end of transfer (PREADY asserted)
    while(!(vif.PREADY === 1'b1)) @(posedge vif.PCLK);
    
    // Collect response
    if (!vif.PWRITE)
      trans_collected.read_data = vif.PRDATA;
    
    trans_collected.error = vif.PSLVERR;
    
    `uvm_info(get_type_name(), $sformatf("Transfer collected: \n%s", trans_collected.convert2string()), UVM_HIGH)
  endtask
  
  // Perform checks on collected transfer
  virtual function void perform_transfer_checks();
    // Check valid address range
    if (trans_collected.addr[31:6] != 0) begin
      `uvm_error(get_type_name(), $sformatf("Invalid address detected: 0x%0h", trans_collected.addr))
    end
    
    // Check for error response
    if (trans_collected.error) begin
      `uvm_warning(get_type_name(), $sformatf("Error response detected for address: 0x%0h", trans_collected.addr))
    end
  endfunction
  
  // Perform coverage on collected transfer
  virtual function void perform_transfer_coverage();
    apb_transfer_cg.sample();
  endfunction
endclass