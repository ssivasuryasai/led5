\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
   
   
   // ########################################################
   // #                                                      #
   // #  Empty template for Tiny Tapeout Makerchip Projects  #
   // #                                                      #
   // ########################################################
   
   // ========
   // Settings
   // ========
   
   //-------------------------------------------------------
   // Build Target Configuration
   //
   var(my_design, tt_um_example)   /// The name of your top-level TT module, to match your info.yml.
   var(target, ASIC)   /// Note, the FPGA CI flow will set this to FPGA.
   //-------------------------------------------------------
   
   var(in_fpga, 1)   /// 1 to include the demo board. (Note: Logic will be under /fpga_pins/fpga.)
   var(debounce_inputs, 1)         /// 1: Provide synchronization and debouncing on all input signals.
                                   /// 0: Don't provide synchronization and debouncing.
                                   /// m5_if_defined_as(MAKERCHIP, 1, 0, 1): Debounce unless in Makerchip.
   
   // ======================
   // Computed From Settings
   // ======================
   
   // If debouncing, a user's module is within a wrapper, so it has a different name.
   var(user_module_name, m5_if(m5_debounce_inputs, my_design, m5_my_design))
   var(debounce_cnt, m5_if_defined_as(MAKERCHIP, 1, 8'h03, 8'hff))

\SV
   // Include Tiny Tapeout Lab.
   m4_include_lib(['https:/']['/raw.githubusercontent.com/os-fpga/Virtual-FPGA-Lab/5744600215af09224b7235479be84c30c6e50cb7/tlv_lib/tiny_tapeout_lib.tlv'])


\TLV my_design()
   $reset = *ui_in[0] ;
   
   
   
   $count_speed4[18:0] = (>>1$reset || >>1$count_speed4 == 19'd500000 ) ? 19'b0 : >>1$count_speed4 +1 ;
   $clk_pulse4 = >>1$reset ? 1'b0: $count_speed4 == 19'd5 ? ~>>1$clk_pulse4 : >>1$clk_pulse4 ;
   
   $count_speed3[19:0] = (>>1$reset || >>1$count_speed3 == 20'd1000000 ) ? 20'b0 : >>1$count_speed3 +1 ;
   $clk_pulse3 = >>1$reset ? 1'b0: $count_speed3 == 20'd10 ? ~>>1$clk_pulse3 : >>1$clk_pulse3 ;
   
   $count_speed2[22:0] = (>>1$reset || >>1$count_speed2 == 23'd5000000 ) ? 23'b0 : >>1$count_speed2 +1 ;
   $clk_pulse2 = >>1$reset ? 1'b0: $count_speed2 == 23'd5000000 ? ~>>1$clk_pulse2 : >>1$clk_pulse2 ;
   
   $count_speed1[23:0] = (>>1$reset || >>1$count_speed1 == 24'd10000000 ) ? 24'b0 : >>1$count_speed1 +1 ;
   $clk_pulse1 = >>1$reset ? 1'b0: $count_speed1 == 24'd10000000 ? ~>>1$clk_pulse1 : >>1$clk_pulse1 ;
   
   
             
   $speed_level[1:0] = >>1$reset ? 2'b0 :
               ($right_edge && >>1$led_output == 8'd01) ? >>1$speed_level :  // Rightmost LED, ignore left button
               ($left_edge && >>1$led_output == 8'd80) ? >>1$speed_level :  // Leftmost LED, ignore right button
               ($right_edge || $left_edge) && (>>1$led_output == 8'd40 || >>1$led_output == 8'd02) ? 2'd2 :
               ($right_edge || $left_edge) && (>>1$led_output == 8'd20 || >>1$led_output == 8'd04) ? 2'd1 :
               ($right_edge || $left_edge) && (>>1$led_output == 8'd10 || >>1$led_output == 8'd08) ? 2'd0 :
               >>1$speed_level;


   
   
   $clk_pulse = ($speed_level == 2'b11) ? $clk_pulse4 :
                ($speed_level == 2'b10) ? $clk_pulse3 :
                ($speed_level == 2'b01) ? $clk_pulse2 :
                $clk_pulse1; // Default to slowest speed
   
   
   $led_output[7:0] = >>1$reset ? 8'b1 :
                (!>>1$clk_pulse && $clk_pulse) ?
                    >>1$forward ? >>1$led_output[7:0] << 1 : >>1$led_output[7:0] >> 1 :
                    >>1$led_output;
   
   
   $forward = $reset ? 1'b1 :  // forward is right to left when == 1'b1
               ($right_edge  && $led_output <= 8'd8)
                  ? 1'b1
               :  ($left_edge  && $led_output > 8'd8)
                  ? 1'b0
                  //default
                  : >>1$forward;
   
   
                  
   $left_btn = *ui_in[3];
   $left_edge = (!>>1$left_btn && $left_btn) ;
   $right_btn = *ui_in[1];
   $right_edge = (!>>1$right_btn && $right_btn) ;
   
   
   
   
   *uo_out = $led_output ;
   // Connect Tiny Tapeout outputs. Note that uio_ outputs are not available in the Tiny-Tapeout-3-based FPGA boards.
   //*uo_out = 8'b0;
   m5_if_neq(m5_target, FPGA, ['*uio_out = 8'b0;'])
   m5_if_neq(m5_target, FPGA, ['*uio_oe = 8'b0;'])

// Set up the Tiny Tapeout lab environment.
\TLV tt_lab()
   // Connect Tiny Tapeout I/Os to Virtual FPGA Lab.
   m5+tt_connections()
   // Instantiate the Virtual FPGA Lab.
   m5+board(/top, /fpga, 7, $, , my_design)
   // Label the switch inputs [0..7] (1..8 on the physical switch panel) (top-to-bottom).
   m5+tt_input_labels_viz(['"UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED"'])

\SV

// ================================================
// A simple Makerchip Verilog test bench driving random stimulus.
// Modify the module contents to your needs.
// ================================================

module top(input logic clk, input logic reset, input logic [31:0] cyc_cnt, output logic passed, output logic failed);
   // Tiny tapeout I/O signals.
   logic [7:0] ui_in, uo_out;
   m5_if_neq(m5_target, FPGA, ['logic [7:0] uio_in, uio_out, uio_oe;'])
   logic [31:0] r;  // a random value
   always @(posedge clk) r <= m5_if_defined_as(MAKERCHIP, 1, ['$urandom()'], ['0']);
   assign ui_in = r[7:0];
   m5_if_neq(m5_target, FPGA, ['assign uio_in = 8'b0;'])
   logic ena = 1'b0;
   logic rst_n = ! reset;
   
   /*
   // Or, to provide specific inputs at specific times (as for lab C-TB) ...
   // BE SURE TO COMMENT THE ASSIGNMENT OF INPUTS ABOVE.
   // BE SURE TO DRIVE THESE ON THE B-PHASE OF THE CLOCK (ODD STEPS).
   // Driving on the rising clock edge creates a race with the clock that has unpredictable simulation behavior.
   initial begin
      #1  // Drive inputs on the B-phase.
         ui_in = 8'h0;
      #10 // Step 5 cycles, past reset.
         ui_in = 8'hFF; 
      // ...etc.
   end
   */

   // Instantiate the Tiny Tapeout module.
   m5_user_module_name tt(.*);
   
   assign passed = top.cyc_cnt > 80;
   assign failed = 1'b0;
endmodule


// Provide a wrapper module to debounce input signals if requested.
m5_if(m5_debounce_inputs, ['m5_tt_top(m5_my_design)'])
\SV



// =======================
// The Tiny Tapeout module
// =======================

module m5_user_module_name (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    m5_if_eq(m5_target, FPGA, ['/']['*'])   // The FPGA is based on TinyTapeout 3 which has no bidirectional I/Os (vs. TT6 for the ASIC).
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    m5_if_eq(m5_target, FPGA, ['*']['/'])
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
   wire reset = ! rst_n;

   // List all potentially-unused inputs to prevent warnings
   wire _unused = &{ena, clk, rst_n, 1'b0};

\TLV
   /* verilator lint_off UNOPTFLAT */
   m5_if(m5_in_fpga, ['m5+tt_lab()'], ['m5+my_design()'])

\SV_plus
   
   // ==========================================
   // If you are using Verilog for your design,
   // your Verilog logic goes here.
   // Note, output assignments are in my_design.
   // ==========================================

\SV
endmodule
