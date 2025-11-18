// Code your testbench here
// or browse Examples
//====================================================
// Interface
//====================================================
interface wishbone_if #(parameter ADDR_WIDTH = 5, DATA_WIDTH = 32, SEL_WIDTH = DATA_WIDTH/8)(input logic clk);
  logic rst;
  logic [ADDR_WIDTH-1:0] addr_o;
  logic [DATA_WIDTH-1:0] data_o;
  logic we_o;
  logic stb_o;
  logic cyc_o;
  logic [SEL_WIDTH-1:0] sel_o;
  logic [2:0] cti_input;
  logic tag_add;

  logic ack_i;
  logic err_i;
  logic [DATA_WIDTH-1:0] data_i;
  logic [1:0] state_out;
  logic [ADDR_WIDTH-1:0] counter_dbg; 
endinterface

//====================================================
// Transaction Class
//====================================================
class transaction;
  rand bit [4:0]  addr_o;     
  rand bit [31:0] data_o;     
  rand bit [3:0]  sel_o;      
  rand bit        we_o;       
  bit [31:0]      data_i;     
  bit             ack_i;
  bit             err_i;      
  rand bit        tag_add;
  rand bit [2:0]       cti_input;  
  bit             stb_o;     
  bit             cyc_o;   
  function void formatted_display(string tag);
    $display("# -------------------------");
    $display("# - [ %s ] ", tag);
    $display("# -------------------------");
    $display("# - addr = %0h, data_out = %0h, we = %0b, sel = %0h, tag_add = %0b, cti = %0h", 
              addr_o, data_o, we_o, sel_o, tag_add, cti_input);
    $display("# - data_in = %0h, ack = %0b, err = %0b", data_i, ack_i, err_i);
    $display("# -------------------------\n");
  endfunction
endclass

//====================================================
// Generator 
//====================================================
class generator;
 mailbox #(transaction) gen2drv;
  int repeat_count;
  event ended; 
  function new(mailbox #(transaction) gen2drv);
    this.gen2drv = gen2drv;
  endfunction
  task run();
    transaction tr;

    // -----------------------------
    // PHASE 1: WRITE transactions
    // -----------------------------
    $display("\n# -----------------------------");
    $display("# [GENERATOR] PHASE 1: WRITE Transactions (we=1)");
    $display("# -----------------------------\n");
    repeat(32) begin
      tr = new(); // create new object again for read phase
      assert(tr.randomize() with {
        cti_input == 3'b000;
        sel_o == 4'b1111;
        we_o == 1'b1;  
        tag_add == 1'b0; // write phase
      });
      tr.formatted_display("Generator - WRITE");
      gen2drv.put(tr);
      repeat_count++;   
    end

    // -----------------------------
    // PHASE 2: READ transactions
    // -----------------------------
    $display("\n# -----------------------------");
    $display("# [GENERATOR] PHASE 2: READ Transactions (we=0)");
    $display("# -----------------------------\n");
    repeat(32) begin
      tr = new(); // create new object again for read phase
      assert(tr.randomize() with {
        data_o == 32'b0;
        cti_input == 3'b000;
        sel_o == 4'b1111;
        tag_add == 1'b0;
        we_o == 1'b0;             // read phase
      });
      tr.formatted_display("Generator - READ");
      gen2drv.put(tr);
      repeat_count++;
    end
    
    
     // -----------------------------
    // PHASE 3: TAG READ transactions
    // -----------------------------
    $display("\n# -----------------------------");
    $display("# [GENERATOR] PHASE 3: TAG ADD Transactions (we=0 & tag_add=1)");
    $display("# -----------------------------\n");
    tr = new();
    assert (tr.randomize() with {
      addr_o == 32'b0;
      data_o == 32'b0;
      cti_input == 3'b000;
      sel_o == 4'b1111;
      we_o == 1'b0;
      tag_add == 1'b1;
    }) else $error("Randomization failed for TAG READ transaction");
    tr.formatted_display("Generator - TAG ADD READ");
    gen2drv.put(tr);
    repeat_count++;
    
    // -----------------------------
    // PHASE 4: BLOCK WRITE transactions
    // ----------------------------------
    $display("\n# -----------------------------");
    $display("# [GENERATOR] PHASE 4: BLOCK WRITE (we=1 & cti = 001)");
    $display("# -----------------------------\n");
    for (int i = 0; i < 2; i++) begin
      tr = new();
      assert (tr.randomize() with {
        addr_o   == i;           
        cti_input == 3'b001;
        sel_o     == 4'b1111;
        we_o      == 1'b1;
        tag_add   == 1'b0;
      }) else $error("Randomization failed for BLOCK WRITE transaction");
      tr.formatted_display($sformatf("Generator - BLOCK WRITE (addr=%0d)", i));
      gen2drv.put(tr);
      repeat_count++;
    end

    // ----------------------------------
    // PHASE 5: BLOCK READ transactions
    // ----------------------------------
    $display("\n# -----------------------------");
    $display("# [GENERATOR] PHASE 4: BLOCK READ (we=0 & cti = 001)");
    $display("# -----------------------------\n");
    for (int i = 0; i < 2; i++) begin
      tr = new();
      assert (tr.randomize() with {
        addr_o   == i;     
        data_o == 32'b0;
        cti_input == 3'b001;
        sel_o     == 4'b1111;
        we_o      == 1'b0;
        tag_add   == 1'b0;
      }) else $error("Randomization failed for BLOCK READ transaction");
      tr.formatted_display($sformatf("Generator - BLOCK READ (addr=%0d)", i));
      gen2drv.put(tr);
      repeat_count++;
    end      
      
     // -----------------------------
    // PHASE 6: TAG READ transactions
    // -----------------------------
    $display("\n# -----------------------------");
    $display("# [GENERATOR] PHASE 6: TAG ADD Transactions (we=0 & tag_add=1)");
    $display("# -----------------------------\n");
    tr = new();
    assert (tr.randomize() with {
      addr_o == 32'b0;
      data_o == 32'b0;
      cti_input == 3'b001;
      sel_o == 4'b1111;
      we_o == 1'b0;
      tag_add == 1'b1;
    }) else $error("Randomization failed for TAG READ transaction");
    tr.formatted_display("Generator - TAG ADD READ");
    gen2drv.put(tr);
    repeat_count++;    
    
    // ----------------------------------
    // PHASE 7: BLOCK END transactions
    // ----------------------------------
    $display("\n# -----------------------------");
    $display("# [GENERATOR] PHASE 7: BLOCK END (we=1 & cti = 111)");
    $display("# -----------------------------\n");
    tr = new();
    assert (tr.randomize() with {
      cti_input == 3'b111;
      sel_o == 4'b1111;
      we_o == 1'b1;
      tag_add == 1'b0;
    }) else $error("Randomization failed for BLOCK WRITE END transaction");
      tr.formatted_display("Generator - BLOCK WRITE END");
    gen2drv.put(tr);
    repeat_count++;  
    
    // -----------------------------
    // PHASE 8: BLOCK WRITE transactions CTI = 010
    // ----------------------------------
    $display("\n# -----------------------------");
    $display("# [GENERATOR] PHASE 7: BLOCK WRITE (we=1 & cti = 010)");
    $display("# -----------------------------\n");
    for (int i = 0; i < 2; i++) begin
      tr = new();
      assert (tr.randomize() with {
        addr_o   == 5'b00000;           
        cti_input == 3'b010;
        sel_o     == 4'b1111;
        we_o      == 1'b1;
        tag_add   == 1'b0;
      }) else $error("Randomization failed for BLOCK WRITE CTI = 010  transaction");
      tr.formatted_display($sformatf("Generator - BLOCK WRITE FOR THE CTI = 010 (addr=%0d)", i));
    gen2drv.put(tr);
    repeat_count++; 
    end
    
    // ----------------------------------
    // PHASE 9: BLOCK END transactions
    // ----------------------------------
    $display("\n# -----------------------------");
    $display("# [GENERATOR] PHASE 7: BLOCK END (we=1 & cti = 111)");
    $display("# -----------------------------\n");
    tr = new();
    assert (tr.randomize() with {
      cti_input == 3'b111;
      sel_o == 4'b1111;
      we_o == 1'b1;
      tag_add == 1'b0;
    }) else $error("Randomization failed for BLOCK WRITE END transaction");
      tr.formatted_display("Generator - BLOCK WRITE END");
    gen2drv.put(tr);
    repeat_count++;     
   
     // -----------------------------
    // PHASE 10: BLOCK READ transactions CTI = 010
    // ----------------------------------
    $display("\n# -----------------------------");
    $display("# [GENERATOR] PHASE 10: BLOCK WRITE (we=1 & cti = 010)");
    $display("# -----------------------------\n");
    for (int i = 0; i < 2; i++) begin
      tr = new();
      assert (tr.randomize() with {
        addr_o   == 5'b00000;           
        cti_input == 3'b010;
        sel_o     == 4'b1111;
        we_o      == 1'b0;
        tag_add   == 1'b0;
      }) else $error("Randomization failed for BLOCK WRITE CTI = 010  transaction");
      tr.formatted_display($sformatf("Generator - BLOCK WRITE FOR THE CTI = 010 (addr=%0d)", i));
    gen2drv.put(tr);
    repeat_count++; 
    end
    
     // -----------------------------
    // PHASE 12: TAG READ transactions
    // -----------------------------
    $display("\n# -----------------------------");
    $display("# [GENERATOR] PHASE 11: TAG ADD Transactions (we=0 & tag_add=1)");
    $display("# -----------------------------\n");
    tr = new();
    assert (tr.randomize() with {
      addr_o == 32'b0;
      data_o == 32'b0;
      cti_input == 3'b010;
      sel_o == 4'b1111;
      we_o == 1'b0;
      tag_add == 1'b1;
    }) else $error("Randomization failed for TAG READ transaction");
    tr.formatted_display("Generator - TAG ADD READ");
    gen2drv.put(tr);
    repeat_count++;     
 
    // ----------------------------------
    // PHASE 13: BLOCK END transactions
    // ----------------------------------
    $display("\n# -----------------------------");
    $display("# [GENERATOR] PHASE 12: BLOCK END (we=1 & cti = 111)");
    $display("# -----------------------------\n");
    tr = new();
    assert (tr.randomize() with {
      cti_input == 3'b111;
      sel_o == 4'b1111;
      we_o == 1'b0;
      tag_add == 1'b0;
    }) else $error("Randomization failed for BLOCK WRITE END transaction");
      tr.formatted_display("Generator - BLOCK WRITE END");
    gen2drv.put(tr);
    repeat_count++; 
      ->ended;  
  $display("# [GENERATOR] Finished sending %0d transactions", repeat_count);
  endtask
endclass

//====================================================
// Driver
//====================================================
class driver;
  // Virtual interface
  virtual wishbone_if vif;
  // Mailbox to get transactions from generator
  mailbox #(transaction) gen2drv;
  int no_transactions;
   // Constructor
  function new(virtual wishbone_if vif, mailbox #(transaction) gen2drv);
    this.vif = vif;
    this.gen2drv = gen2drv;
  endfunction
  //====================================================
  // Reset task: set all signals to 0
  //====================================================
  task reset();
    vif.addr_o    <= 0;
    vif.data_o    <= 0;
    vif.sel_o     <= 0;
    vif.we_o      <= 0;
    vif.stb_o     <= 0;
    vif.cyc_o     <= 0;
    vif.tag_add   <= 0;
    vif.cti_input <= 0;
    wait(!vif.rst);
    $display("# Driver: All DUT signals reset to 0\n");
  endtask
  //====================================================
  // Main driver task
  //====================================================
  task run();
    transaction tr;
    forever begin
      //  Wait for a new transaction from the generator
      gen2drv.get(tr);
      vif.addr_o    <= tr.addr_o;
      vif.data_o    <= tr.data_o;
      vif.sel_o     <= tr.sel_o;
      vif.we_o      <= tr.we_o;
      vif.stb_o     <= 1'b1;
      vif.cyc_o     <= 1'b1;
      vif.tag_add   <= tr.tag_add;
      vif.cti_input <= tr.cti_input;
      if (tr.cti_input == 3'b000) begin
  		@(posedge vif.clk);
  		vif.stb_o <= 0;
        do @(posedge vif.clk); while (vif.ack_i !== 1'b1 && vif.err_i !== 1'b1);
  		vif.cyc_o <= 0;
  		@(posedge vif.clk);
  		tr.formatted_display("Driver");
  		no_transactions++;        
	  end
	  else if (tr.cti_input inside {3'b001, 3'b010}) begin
  		@(posedge vif.clk);
  		vif.stb_o <= 0;
  		do @(posedge vif.clk); while (vif.ack_i !== 1'b1 && vif.err_i !== 1'b1);
  		@(posedge vif.clk);
  		tr.formatted_display("Driver");
  		no_transactions++;  
        
      end
	  else if (tr.cti_input == 3'b111) begin
  		@(posedge vif.clk);
  		@(posedge vif.clk);
  		@(posedge vif.clk);
  		vif.stb_o <= 0;
  		vif.cyc_o <= 0;
  		@(posedge vif.clk);
        @(posedge vif.clk);
  		tr.formatted_display("Driver");
  		no_transactions++;   
	  end
    end
  endtask
endclass

//====================================================
// Monitor
//====================================================
class monitor;
  virtual wishbone_if vif;
  mailbox #(transaction) mon2sb;
  function new(virtual wishbone_if vif, mailbox #(transaction) mon2sb);
    this.vif = vif;
    this.mon2sb = mon2sb;
  endfunction
  //====================================================
  // Main monitor task
  //====================================================
  task run();
    transaction tr;
  bit exit_logged = 0;  // <== new flag
    forever begin
      @(posedge vif.clk);
      // -----------------------------
      // CASE 1: CTI = 000, 001, 010
      //------------------------------
	if (vif.cti_input inside {3'b000, 3'b001, 3'b010}) begin
      exit_logged = 0;
  		if (vif.ack_i || vif.err_i) begin
    	tr = new();
    	// If CTI = 010 → use incremented address (addr + counter_dbg)
    	if (vif.cti_input == 3'b010)
      	tr.addr_o = vif.addr_o + vif.counter_dbg - 1; 
    	else
      	tr.addr_o = vif.addr_o;
    	tr.data_o    = vif.data_o;
              tr.sel_o     = vif.sel_o;
    	tr.we_o      = vif.we_o;
    	tr.data_i    = vif.data_i;
    	tr.ack_i     = vif.ack_i;
    	tr.err_i     = vif.err_i;
    	tr.tag_add   = vif.tag_add;
    	tr.cti_input = vif.cti_input;

    	tr.formatted_display("Monitor - CTI=000/001/010");
    	mon2sb.put(tr);
  	    end
	end
      // ---------------------------------
      // CASE 2: CTI = 111 (End of burst)
      // ---------------------------------
      else if (vif.cti_input == 3'b111 & !exit_logged) begin
        if (vif.stb_o == 0 && vif.cyc_o == 0) begin
          tr = new();
          tr.addr_o    = vif.addr_o;
          tr.data_o    = vif.data_o;
          tr.sel_o     = vif.sel_o;
          tr.we_o      = vif.we_o;
          tr.data_i    = vif.data_i;
          tr.ack_i     = vif.ack_i;
          tr.err_i     = vif.err_i;
          tr.tag_add   = vif.tag_add;
          tr.cti_input = vif.cti_input;
          tr.cyc_o     = vif.cyc_o;
          tr.stb_o     = vif.stb_o;

          tr.formatted_display("Monitor - CTI - 111");
          mon2sb.put(tr);
        exit_logged = 1;  
        end
      end
    end
  endtask
endclass

//====================================================
// Scoreboard 
//====================================================
class scoreboard;
  mailbox #(transaction) mon2sb;
  int no_transactions;
  bit [31:0] exp_mem [0:15];
  function new(mailbox #(transaction) mon2sb);
    this.mon2sb = mon2sb;
    // Initialize memory contents
    foreach (exp_mem[i])
      exp_mem[i] = '0;
  endfunction
  task run();
    transaction tr;
    forever begin
      mon2sb.get(tr);
      // -------------------------------------------------
      // BLOCK WRITE OR READ EXIT MODE VERIFY
      // -------------------------------------------------
      if ( tr.cti_input == 3'b111 ) begin
        if ( tr.cyc_o == 1'b0 && tr.stb_o == 1'b0 )
          $display("# BLOCK EXIT DONE ");
        else 
          $display("# BLOCK EXIT NOT PERFORMED DONE ");
      end
      // -------------------------------------------------
      // WRITE operation 
      // -------------------------------------------------
      else if (tr.we_o == 1'b1 && tr.tag_add == 1'b0) begin
        if (tr.addr_o < 5'd16) begin
          if (tr.ack_i && !tr.err_i) begin
            exp_mem[tr.addr_o] = tr.data_o;   
            $display("# [WRITE][PASS] Addr=%0d Data=0x%0h stored ", tr.addr_o, tr.data_o);
          end else begin
            $display("# [WRITE][FAIL] Addr=%0d Expected ACK=1 ERR=0 but got ACK=%0b ERR=%0b ",
                     tr.addr_o, tr.ack_i, tr.err_i);
          end
        end else begin
          if (tr.err_i && !tr.ack_i)
            $display("# [WRITE][PASS] Addr=%0d Invalid access handled (ERR=1,ACK=0) ", tr.addr_o);
          else
            $display("# [WRITE][FAIL] Addr=%0d Invalid access not handled correctly ", tr.addr_o);
        end
      end
      // -------------------------------
      // TAG ADD READ
      // -------------------------------
      else if (tr.we_o == 1'b0 && tr.tag_add == 1'b1) begin
        bit [31:0] exp_tag_sum = exp_mem[0] + exp_mem[1];
        if (tr.data_i !== exp_tag_sum)
          $error(" TAG ADD MISMATCH -> exp=%h got=%h",
                 exp_tag_sum, tr.data_i);
        else
          $display(" TAG ADD OK -> SUM(%h + %h) = %h",
                   exp_mem[0], exp_mem[1], tr.data_i);
      end
      // -------------------------------------------------
      // READ operation (compare data)
      // -------------------------------------------------
      else begin
        if (tr.addr_o < 5'd16) begin
          if (tr.ack_i && !tr.err_i) begin
            if (tr.data_i === exp_mem[tr.addr_o])
              $display("# [READ][PASS] Addr=%0d Data match  (Expected=0x%0h, Got=0x%0h)",
                       tr.addr_o, exp_mem[tr.addr_o], tr.data_i);
            else
              $display("# [READ][FAIL] Addr=%0d Data mismatch  (Expected=0x%0h, Got=0x%0h)",
                       tr.addr_o, exp_mem[tr.addr_o], tr.data_i);
          end else begin
            $display("# [READ][FAIL] Addr=%0d Expected ACK=1 ERR=0 but got ACK=%0b ERR=%0b ",
                     tr.addr_o, tr.ack_i, tr.err_i);
          end
        end else begin
          if (tr.err_i && !tr.ack_i)
            $display("# [READ][PASS] Addr=%0d Invalid access handled (ERR=1,ACK=0) ", tr.addr_o);
          else
            $display("# [READ][FAIL] Addr=%0d Invalid access not handled correctly ", tr.addr_o);
        end
      end
      no_transactions++;
      if (tr.cti_input != 3'b111)
      tr.formatted_display("Scoreboard");
    end
  endtask
endclass
  
//====================================================
// TEST CLASS (Top-level Verification Orchestrator)
//====================================================
class environment;
  generator gen;
  driver driv;
  monitor mon;
  scoreboard scb;
mailbox #(transaction) gen2drv;
  mailbox #(transaction) mon2scb;
  virtual wishbone_if vif;
  function new(virtual wishbone_if vif);
    this.vif = vif;
    gen2drv = new();
    mon2scb = new();
    gen = new(gen2drv);
    driv = new(vif, gen2drv);
    mon = new(vif, mon2scb);
    scb = new(mon2scb);
  endfunction
  task pre_test();
    driv.reset();
  endtask
  task test();
    fork
      gen.run();
      driv.run();
      mon.run();
      scb.run();
    join_any
  endtask
  task post_test();
    wait(gen.ended.triggered);
    wait(gen.repeat_count == driv.no_transactions);
    wait(gen.repeat_count == scb.no_transactions);
    $display("\n# ================================================");
      $display("# TEST COMPLETE : All transactions processed!");
    $display("# Generator: %0d | Driver: %0d | Scoreboard: %0d",
              gen.repeat_count, driv.no_transactions, scb.no_transactions);
    $display("# ================================================\n");
  endtask
  task run();
    pre_test();
    test();
    post_test();
    $finish;
  endtask
endclass

program test(wishbone_if i_intf);
  environment env;
  initial begin
    env = new(i_intf);
    env.run();
  end
endprogram  
  

//====================================================
// Top Testbench Module
//====================================================
module testbench;
  parameter ADDR_WIDTH = 5;
  parameter DATA_WIDTH = 32;
  parameter SEL_WIDTH  = DATA_WIDTH/8;
  logic clk = 0;
  logic rst = 0;
  always #2 clk = ~clk;
  wishbone_if #(ADDR_WIDTH, DATA_WIDTH, SEL_WIDTH) i_intf(clk);
  test tb_inst (.i_intf(i_intf));
  wishbone_top #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .SEL_WIDTH(SEL_WIDTH)
  ) dut (
    .clk_i(clk),
    .rst_i(i_intf.rst),
    .addr_o(i_intf.addr_o),
    .data_o(i_intf.data_o),
    .we_o(i_intf.we_o),
    .stb_o(i_intf.stb_o),
    .cyc_o(i_intf.cyc_o),
    .sel_o(i_intf.sel_o),
    .cti_input(i_intf.cti_input),
    .tag_add(i_intf.tag_add),
    .ack_i(i_intf.ack_i),
    .err_i(i_intf.err_i),
    .data_i(i_intf.data_i),
    .state_out(i_intf.state_out),
    .dbg_w_addr(),
    .dbg_w_data_m2s(),
    .counter(i_intf.counter_dbg), 
    .dbg_w_we(),
    .dbg_tag_add(),
    .dbg_w_sel(),
    .dbg_w_stb(),
    .dbg_w_cyc(),
    .dbg_w_ack(),
    .dbg_w_err(),
    .dbg_cti() );
  initial begin
    $dumpfile("wishbone_wave.vcd");
    $dumpvars(0, testbench);
    i_intf.rst = 1;
    repeat(5) @(posedge clk);
    i_intf.rst = 0;
  end
endmodule
