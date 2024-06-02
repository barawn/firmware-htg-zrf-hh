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
        input ADC1_VIN_P,       // AM2
        input ADC1_VIN_N,       // AM1
        
        input ADC2_CLK_P,       // AD5
        input ADC2_CLK_N,       // AD4
        input ADC2_VIN_P,       // AK2
        input ADC2_VIN_N,       // AK1
        input ADC3_VIN_P,       // AH2
        input ADC3_VIN_N,       // AH1
        
        input ADC4_CLK_P,       // AB5
        input ADC4_CLK_N,       // AB4
        input ADC4_VIN_P,       // AF2
        input ADC4_VIN_N,       // AF1
        input ADC5_VIN_P,       // AD2
        input ADC5_VIN_N,       // AD1
        
        input ADC6_CLK_P,       // Y5
        input ADC6_CLK_N,       // Y4
        input ADC6_VIN_P,       // AB2
        input ADC6_VIN_N,       // AB1
        input ADC7_VIN_P,       // Y2
        input ADC7_VIN_N,       // Y1        

        // god damnit
        input DAC0_CLK_P,       // R5
        input DAC0_CLK_N,       // R4
        output DAC0_VOUT_P,     // U2
        output DAC0_VOUT_N,     // U1

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
    
    parameter THIS_DESIGN = "BASIC";
    
    (* KEEP = "TRUE"  *)
    wire ps_clk;
    wire ps_resetn;
    
    // ADC AXI4-Stream clock.
    wire aclk;
    // divided by 2
    wire aclk_div2;
    wire aresetn = 1'b1;
    // ADC AXI4-Streams
    `DEFINE_AXI4S_MIN_IF( adc0_ , 128 );
    `DEFINE_AXI4S_MIN_IF( adc1_ , 128 );
    `DEFINE_AXI4S_MIN_IF( adc2_ , 128 );
    `DEFINE_AXI4S_MIN_IF( adc3_ , 128 );
    `DEFINE_AXI4S_MIN_IF( adc4_ , 128 );
    `DEFINE_AXI4S_MIN_IF( adc5_ , 128 );
    `DEFINE_AXI4S_MIN_IF( adc6_ , 128 );
    `DEFINE_AXI4S_MIN_IF( adc7_ , 128 );
    // Buffer input streams
    `DEFINE_AXI4S_MIN_IF( buf0_ , 128 );
    `DEFINE_AXI4S_MIN_IF( buf1_ , 128 );
    `DEFINE_AXI4S_MIN_IF( buf2_ , 128 );
    `DEFINE_AXI4S_MIN_IF( buf3_ , 128 );
    // UART from PS
    wire uart_from_ps;
    wire uart_to_ps;
    // capture output
    wire capture;

    
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
                            .clk_out3(aclk_div2),
                            .locked(refclkwiz_locked));
    
    // input sysref
    wire sys_ref;
    IBUFDS u_srbuf(.I(SYSREF_FPGA_P),.IB(SYSREF_FPGA_N),.O(sys_ref));    
    
    always @(posedge ref_clk) sysref_reg_slowclk <= sys_ref;
    always @(posedge aclk) sysref_reg <= sysref_reg_slowclk;
    
    // ila for dbg
    sysref_ila u_sysref_ila(.clk(aclk),.probe0(sysref_reg));

    // Local wishbone bus
    `DEFINE_WB_IF( bm_ , 22, 32 );
    boardman_wrapper #(.CLOCK_RATE(100000000),
                       .BAUD_RATE(1000000),
                       .USE_ADDRESS("FALSE"))
                       u_bm(.wb_clk_i(ps_clk),
                            .wb_rst_i(1'b0),
                            `CONNECT_WBM_IFM( wb_ , bm_ ),
                            .burst_size_i(2'b00),
                            .address_i(8'h00),
                            .RX(uart_from_ps),
                            .TX(uart_to_ps));    
    // block design
    htg_zrf_hh_mts_wrapper u_ps( .Vp_Vn_0_v_p( VP ),
                                 .Vp_Vn_0_v_n( VN ),
                                 // sysref
                                 .sysref_in_0_diff_p( SYSREF_P ),
                                 .sysref_in_0_diff_n( SYSREF_N ),
                                 // clocks
                                 .adc0_clk_0_clk_p( ADC0_CLK_P ),
                                 .adc0_clk_0_clk_n( ADC0_CLK_N ),
                                 .adc1_clk_0_clk_p( ADC2_CLK_P ),
                                 .adc1_clk_0_clk_n( ADC2_CLK_N ),
                                 .adc2_clk_0_clk_p( ADC4_CLK_P ),
                                 .adc2_clk_0_clk_n( ADC4_CLK_N ),
                                 .adc3_clk_0_clk_p( ADC6_CLK_P ),
                                 .adc3_clk_0_clk_n( ADC6_CLK_N ),
                                 // vins
                                 .vin0_01_0_v_p( ADC0_VIN_P ),
                                 .vin0_01_0_v_n( ADC0_VIN_N ),
                                 .vin0_23_0_v_p( ADC1_VIN_P ),
                                 .vin0_23_0_v_n( ADC1_VIN_N ),
                                 .vin1_01_0_v_p( ADC2_VIN_P ),
                                 .vin1_01_0_v_n( ADC2_VIN_N ),
                                 .vin1_23_0_v_p( ADC3_VIN_P ),
                                 .vin1_23_0_v_n( ADC3_VIN_N ),
                                 .vin2_01_0_v_p( ADC4_VIN_P ),
                                 .vin2_01_0_v_n( ADC4_VIN_N ),
                                 .vin2_23_0_v_p( ADC5_VIN_P ),
                                 .vin2_23_0_v_n( ADC5_VIN_N ),
                                 .vin3_01_0_v_p( ADC6_VIN_P ),
                                 .vin3_01_0_v_n( ADC6_VIN_N ),
                                 .vin3_23_0_v_p( ADC7_VIN_P ),
                                 .vin3_23_0_v_n( ADC7_VIN_N ),
                                 // vouts
                                 .vout00_0_v_p( DAC0_VOUT_P ),
                                 .vout00_0_v_n( DAC0_VOUT_N ),
                                 .dac0_clk_0_clk_p( DAC0_CLK_P ),
                                 .dac0_clk_0_clk_n( DAC0_CLK_N ),
                                 // AXI stream *outputs*
                                 `CONNECT_AXI4S_MIN_IF( m00_axis_0_ , adc0_ ),
                                 `CONNECT_AXI4S_MIN_IF( m02_axis_0_ , adc1_ ),
                                 `CONNECT_AXI4S_MIN_IF( m10_axis_0_ , adc2_ ),
                                 `CONNECT_AXI4S_MIN_IF( m12_axis_0_ , adc3_ ),
                                 `CONNECT_AXI4S_MIN_IF( m20_axis_0_ , adc4_ ),
                                 `CONNECT_AXI4S_MIN_IF( m22_axis_0_ , adc5_ ),
                                 `CONNECT_AXI4S_MIN_IF( m30_axis_0_ , adc6_ ),
                                 `CONNECT_AXI4S_MIN_IF( m32_axis_0_ , adc7_ ),
                                 // my crap
                                 .s_axi_aclk_0( aclk_div2 ),
                                 .s_axi_aresetn_0( 1'b1 ),
                                 .s_axis_aclk_0( aclk ),
                                 .s_axis_aresetn_0( 1'b1 ),
                                 // feed back to inputs
                                 `CONNECT_AXI4S_MIN_IF( S_AXIS_0_ , buf0_ ),
                                 `CONNECT_AXI4S_MIN_IF( S_AXIS_1_ , buf1_ ),
                                 `CONNECT_AXI4S_MIN_IF( S_AXIS_2_ , buf2_ ),
                                 `CONNECT_AXI4S_MIN_IF( S_AXIS_3_ , buf3_ ),

                                 .pl_clk0( ps_clk ),
                                 .pl_resetn0( ps_resetn ),
                                 .clk_adc0_0(adc_clk),
                                 .UART_txd(uart_from_ps),
                                 .UART_rxd(uart_to_ps),
                                 .capture_o(capture),
                                 .user_sysref_adc_0(sysref_reg));

    generate
        if (THIS_DESIGN == "BASIC") begin : BSC
            basic_design u_design( .wb_clk_i(ps_clk),
                                   .wb_rst_i(1'b0),
                                    `CONNECT_WBS_IFS( wb_ , bm_ ),
                                    .aclk(aclk),
                                    .aresetn(1'b1),
                                    `CONNECT_AXI4S_MIN_IF( adc0_ , adc0_ ),
                                    `CONNECT_AXI4S_MIN_IF( adc1_ , adc1_ ),
                                    `CONNECT_AXI4S_MIN_IF( adc2_ , adc2_ ),
                                    `CONNECT_AXI4S_MIN_IF( adc3_ , adc3_ ),
                                    `CONNECT_AXI4S_MIN_IF( adc4_ , adc4_ ),
                                    `CONNECT_AXI4S_MIN_IF( adc5_ , adc5_ ),
                                    `CONNECT_AXI4S_MIN_IF( adc6_ , adc6_ ),
                                    `CONNECT_AXI4S_MIN_IF( adc7_ , adc7_ ),
                                    // buffers
                                    `CONNECT_AXI4S_MIN_IF( buf0_ , buf0_ ),
                                    `CONNECT_AXI4S_MIN_IF( buf1_ , buf1_ ),
                                    `CONNECT_AXI4S_MIN_IF( buf2_ , buf2_ ),
                                    `CONNECT_AXI4S_MIN_IF( buf3_ , buf3_ ));            
        end                     
    endgenerate        
endmodule
