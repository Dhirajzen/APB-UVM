// APB Transaction Class
class apb_transaction extends uvm_sequence_item;
  // Transaction fields
  rand bit [31:0] addr;
  rand bit [31:0] data;
  rand bit        write;  // 1=Write, 0=Read
  bit [31:0]      read_data;
  bit             error;
  
  // Registration macro
  `uvm_object_utils_begin(apb_transaction)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(write, UVM_ALL_ON)
    `uvm_field_int(read_data, UVM_ALL_ON)
    `uvm_field_int(error, UVM_ALL_ON)
  `uvm_object_utils_end
  
  // Constructor
  function new(string name = "apb_transaction");
    super.new(name);
  endfunction
  
  // Constraints
  constraint addr_c {
    // Constrain to valid register addresses (16 registers)
    addr[31:6] == 0;
    addr[1:0] == 0;  // Word aligned
  }
  
  // Helper functions
  function string convert2string();
    string s;
    s = super.convert2string();
    $sformat(s, "%s\n addr = 0x%0h\n %s data = 0x%0h\n read_data = 0x%0h\n error = %0d",
             s, addr, write ? "write" : "read", data, read_data, error);
    return s;
  endfunction
  
  // Custom clone method
  function void do_copy(uvm_object rhs);
    apb_transaction rhs_;
    if (!$cast(rhs_, rhs)) begin
      `uvm_fatal("do_copy", "cast failed")
    end
    super.do_copy(rhs);
    addr = rhs_.addr;
    data = rhs_.data;
    write = rhs_.write;
    read_data = rhs_.read_data;
    error = rhs_.error;
  endfunction
  
  // Custom compare method
  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    apb_transaction rhs_;
    bit status = 1;
    
    if (!$cast(rhs_, rhs)) begin
      `uvm_fatal("do_compare", "cast failed")
      return 0;
    end
    
    status &= super.do_compare(rhs, comparer);
    status &= (addr == rhs_.addr);
    
    if (write) begin
      status &= (data == rhs_.data);
    end else begin
      status &= (read_data == rhs_.read_data);
    end
    
    status &= (error == rhs_.error);
    
    return status;
  endfunction
endclass