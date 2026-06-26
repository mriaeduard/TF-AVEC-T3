module top (
    input  logic rst,
    input  logic clk_15mhz,
    input  logic clk_25mhz,
    input  logic clk_40mhz,
    input  logic clk_50mhz,
    input  logic clk_100mhz,
    
    //Pinos de ligação ao Testbench
    output logic ready_tb,
    input  logic start_tb,
    input  logic [1:0] reg_id_tb
);

    logic       sclk;
    logic       mosi;  
    logic [3:0] se;    
    logic miso_s1, miso_s2, miso_s3, miso_s4;
    logic miso_mux_out;

    logic [7:0] ram_data_in, ram_data_out;
    logic       ram_we;
    logic [7:0] ram_addr;

    always_comb begin
        case (se)
            4'b0001: miso_mux_out = miso_s1;
            4'b0010: miso_mux_out = miso_s2;
            4'b0100: miso_mux_out = miso_s3;
            4'b1000: miso_mux_out = miso_s4;
            default: miso_mux_out = 1'b0;
        endcase
    end

    coletor_dados master (
        .clk     (clk_100mhz),
        .rst     (rst),
        .miso    (miso_mux_out), 
        .mosi    (mosi),
        .sclk    (sclk),
        .se      (se),           
        .ram_we  (ram_we),
        .ram_addr(ram_addr),
        .ram_data(ram_data_in),
        // Ligações do TB
        .ready   (ready_tb),
        .start   (start_tb),
        .reg_id  (reg_id_tb)
    );

    ram inst_ram (
        .clk     (clk_100mhz),
        .we      (ram_we),
        .addr    (ram_addr),
        .data_i  (ram_data_in),
        .data_o  (ram_data_out)
    );

    sensor #(.SENSOR_ID(1), .REG_COUNT(4), .REG_WIDTH(16)) slave_1 (
        .clock (clk_15mhz), .reset (rst), .se (se[0]), .miso (miso_s1), .mosi (mosi), .sclk (sclk)
    );
    sensor #(.SENSOR_ID(2), .REG_COUNT(4), .REG_WIDTH(16)) slave_2 (
        .clock (clk_40mhz), .reset (rst), .se (se[1]), .miso (miso_s2), .mosi (mosi), .sclk (sclk)
    );
    sensor #(.SENSOR_ID(3), .REG_COUNT(4), .REG_WIDTH(16)) slave_3 (
        .clock (clk_50mhz), .reset (rst), .se (se[2]), .miso (miso_s3), .mosi (mosi), .sclk (sclk)
    );
    sensor #(.SENSOR_ID(4), .REG_COUNT(4), .REG_WIDTH(16)) slave_4 (
        .clock (clk_25mhz), .reset (rst), .se (se[3]), .miso (miso_s4), .mosi (mosi), .sclk (sclk)
    );

endmodule