`timescale 1ns / 1ps
`include "interfaces.vh"

// HTG ZRF HH top module for messing around with the RFDC.
module htg_zrf_hh_top(
        // analog input for SysMon
        input VP,               // doesn't need a pin loc
        input VN,               // doesn't need a pin loc
        // RFDC inputs
        input ADC0_CLK_P,       // AF5 (300 MHz)
        input ADC0_CLK_N,       // AF4 (300 MHz)
        input ADC0_VIN_P,       // AP2
        input ADC0_VIN_N,       // AP1
        input SYSREF_P,         // AL16 (1.5 MHz)
        input SYSREF_N,         // AL15 (1.5 MHz)
        // PL clock to capture SYSREF in PL (24 MHz)
        input FPGA_REFCLK_IN_P, //  AT6
        input FPGA_REFCLK_IN_N, //  AT7
        // PL sysref input (1.5 MHz)
        input SYSREF_FPGA_P,    // AL16
        input SYSREF_FPGA_N,    // AL15
        output [1:0] PL_USER_LED        
    );
    
    (* KEEP = "TRUE"  *)
    wire ps_clk;
    wire ps_reset;
    
    // ADC AXI4-Stream clock.
    wire aclk;
    wire aresetn = 1'b1;
    // ADC AXI4-Stream
    `DEFINE_AXI4S_IF( adc0_ , 128 );
    // SYSREF capture register
    (* IOB = "TRUE" *)
    reg sysref_reg_slowclk = 0;
    reg sysref_reg = 0;
    // output clock (187.5 MHz, unused)
    wire adc_clk;
    
    // something's wrong with the various sample clocks so let's try to test
    reg [31:0] adc_clk_counter = {32{1'b0}};
    (* CUSTOM_CC_SRC = "ACLK" *)
    reg [31:0] adc_clk_freq = {32{1'b0}};
    (* CUSTOM_CC_DST = "PSCLK" *)
    reg [31:0] adc_clk_freq_ps = {32{1'b0}};
        
    reg [31:0] ref_clk_counter = {32{1'b0}};
    (* CUSTOM_CC_SRC = "REFCLK" *)
    reg [31:0] ref_clk_freq = {32{1'b0}};
    (* CUSTOM_CC_DST = "PSCLK" *)
    reg [31:0] ref_clk_freq_ps = {32{1'b0}};
    
    reg [31:0] pps_counter = {32{1'b0}};
    reg pps_flag = 0;
    wire pps_flag_adcclk;
    wire pps_flag_refclk;
    wire adcclk_freq_done;
    wire refclk_freq_done;
    
                
    // slower PL capture clk b/c 375 is too fast I guess? (75 MHz)
    wire ref_clk;
    // reset/locked, maybe pop these through EMIO
    wire refclkwiz_reset = 1'b0;
    wire refclkwiz_locked;

    flag_sync u_adcsync(.in_clkA(pps_flag),.clkA(ps_clk),.out_clkB(pps_flag_adcclk),.clkB(adc_clk));
    flag_sync u_adcdone(.in_clkA(pps_flag_adcclk),.clkA(adc_clk),.out_clkB(adcclk_freq_done),.clkB(ps_clk));
    flag_sync u_refsync(.in_clkA(pps_flag),.clkA(ps_clk),.out_clkB(pps_flag_refclk),.clkB(ref_clk));
    flag_sync u_refdone(.in_clkA(pps_flag_refclk),.clkA(ref_clk),.out_clkB(refclk_freq_done),.clkB(ps_clk));

    always @(posedge ps_clk) begin
        if (adcclk_freq_done) adc_clk_freq_ps <= adc_clk_freq;
        if (refclk_freq_done) ref_clk_freq_ps <= ref_clk_freq;
    end
    
    always @(posedge adc_clk) begin
        if (pps_flag_adcclk) adc_clk_freq <= adc_clk_counter;
        if (pps_flag_adcclk) adc_clk_counter <= {32{1'b0}};
        else adc_clk_counter <= adc_clk_counter + 1;
    end        
    
    always @(posedge ref_clk) begin
        if (pps_flag_refclk) ref_clk_freq <= ref_clk_counter;
        if (pps_flag_refclk) ref_clk_counter <= {32{1'b0}};
        else ref_clk_counter <= ref_clk_counter + 1;
    end        
    
    always @(posedge ps_clk) begin
        if (pps_counter == 100000000 - 1) pps_counter <= {32{1'b0}};
        else pps_counter <= pps_counter + 1;
        
        pps_flag <= (pps_counter == {32{1'b0}});
    end        

    clk_count_vio u_vio(.clk(ps_clk),.probe_in0(adc_clk_freq_ps),.probe_in1(ref_clk_freq_ps));
    
    // generate clocks
    slow_refclk_wiz u_rcwiz(.reset(refclkwiz_reset),
                            .clk_in1_p(FPGA_REFCLK_IN_P),
                            .clk_in1_n(FPGA_REFCLK_IN_N),
                            .clk_out1(ref_clk),
                            .clk_out2(aclk),
                            .locked(refclkwiz_locked));
    
    // input sysref
    wire sys_ref;
    IBUFDS u_srbuf(.I(SYSREF_FPGA_P),.IB(SYSREF_FPGA_N),.O(sys_ref));    
    
    always @(posedge ref_clk) sysref_reg_slowclk <= sys_ref;
    always @(posedge aclk) sysref_reg <= sysref_reg_slowclk;
    
    htg_zrf8_ps_wrapper 
        u_ps( // analogs
              .Vp_Vn_v_n(VN),
              .Vp_Vn_v_p(VP),
              // clk out
              .clk_adc0_0(adc_clk),
              .adc0_clk_0_clk_p( ADC0_CLK_P ),
              .adc0_clk_0_clk_n( ADC0_CLK_N ),
              .vin0_01_0_v_p( ADC0_VIN_P ),
              .vin0_01_0_v_n( ADC0_VIN_N ),
              .sysref_in_0_diff_p( SYSREF_P ),
              .sysref_in_0_diff_n( SYSREF_N ),
              // PS calls this pl_clk, we call it ps_clk
              .pl_clk0( ps_clk ),
              .pl_resetn0( ps_reset ),
              .led_pl_tri_o( PL_USER_LED ),
              // RFDC inputs/outputs
              .m0_axis_aclk_0(aclk),
              .m0_axis_aresetn_0(aresetn),
              `CONNECT_AXI4S_MIN_IF( m00_axis_0_ , adc0_ ),
              .user_sysref_adc_0(sysref_reg));

    wire ila_trigger;
    wire ila_trigger_ack;
    wire [11:0] ila_adc;
    wire        ila_adc_valid;
    adc_ila_transfer u_adctr( .adc_in( adc0_tdata ),
                              .adc_clk( aclk),
                              .trigger_in(ila_trigger),
                              .trigger_ack(ila_trigger_ack),
                              .adc_out(ila_adc),
                              .adc_valid(ila_adc_valid));
    adc_ila u_ila(.clk(aclk),
                  .trig_out(ila_trigger),
                  .trig_out_ack(ila_trigger_ack),
                  .probe0(ila_adc),
                  .probe1(ila_adc_valid));                  
endmodule
