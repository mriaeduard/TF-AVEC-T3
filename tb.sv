`timescale 1ns / 1ps

module tb;

    logic rst;
    logic clk_15mhz, clk_25mhz, clk_40mhz, clk_50mhz, clk_100mhz;
    
    // Fios de controlo
    logic ready_tb;
    logic start_tb;
    logic [1:0] reg_id_tb;

    top dut (
        .rst(rst),
        .clk_15mhz(clk_15mhz), .clk_25mhz(clk_25mhz), .clk_40mhz(clk_40mhz), .clk_50mhz(clk_50mhz), .clk_100mhz(clk_100mhz),
        .ready_tb(ready_tb),
        .start_tb(start_tb),
        .reg_id_tb(reg_id_tb)
    );

    // Geração de Clocks
    always #5    clk_100mhz = ~clk_100mhz;
    always #10   clk_50mhz  = ~clk_50mhz;
    always #12.5 clk_40mhz  = ~clk_40mhz;
    always #20   clk_25mhz  = ~clk_25mhz;
    always #33.3 clk_15mhz  = ~clk_15mhz;

    // envio de comandos
    task ler_sensor(input logic [1:0] id_sensor);
        begin
            wait(ready_tb == 1'b1);     // Aguarda o Coletor ficar livre
            @(posedge clk_100mhz);
            reg_id_tb = id_sensor;      // Seleciona o sensor
            start_tb = 1'b1;            //  ordem de start
            @(posedge clk_100mhz);
            start_tb = 1'b0;            // Baixa o pulso de start
            wait(ready_tb == 1'b1);     // Aguarda terminar a leitura e gravação
        end
    endtask

    initial begin
        clk_100mhz = 0; clk_50mhz = 0; clk_40mhz = 0; clk_25mhz = 0; clk_15mhz = 0;
        start_tb = 0;
        reg_id_tb = 0;
        rst = 0;
        #100;
        rst = 1;

        // Sequência de testes que o sor pediu
        $display("Iniciando bateria de leituras...");
        
        ler_sensor(2'b00); // Lê o Emulador 1
        #100;
        ler_sensor(2'b01); // Lê o Emulador 2
        #100;
        ler_sensor(2'b10); // Lê o Emulador 3
        #100;
        ler_sensor(2'b11); // Lê o Emulador 4
        
        #500;
        $display("Fim da simulação.");
        $stop;
    end

endmodule