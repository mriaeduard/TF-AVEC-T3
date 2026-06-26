module coletor_dados (
    input  logic clk,         // Clock principal de 100MHz do Coletor
    input  logic rst,         // Reset ativo em nível baixo (0)

    // Interface SPI
    input  logic miso,        
    output logic mosi,        
    output logic sclk,        
    output logic [3:0] se,    

    // Interface RAM
    output logic ram_we,      
    output logic [7:0] ram_addr, 
    output logic [7:0] ram_data, 

    // Interface de Comando TB
    output logic ready,       // Avisa o TB (1 = livre)
    input  logic start,       // Pulso do TB para iniciar a leitura
    input  logic [1:0] reg_id // Indica qual sensor ler (00, 01, 10 ou 11)
);

    typedef enum logic [3:0] {
        WAIT_CMD,       // Aguarda ordem do Testbench
        SELECT_SENSOR,  
        SPI_CLOCK_HIGH, 
        SPI_CLOCK_LOW,  
        WRITE_RAM_HIGH, 
        WRITE_RAM_LOW,  
        FINISH_READ     // Prepara para a próxima ordem
    } state_t;

    state_t EA; 

    logic [15:0] shift_reg;   
    logic [4:0]  bit_counter; 
    logic [1:0]  target_sensor; // Guarda o sensor solicitado pelo TB
    
    always_ff @(posedge clk or negedge rst) begin
        if (rst == 0) begin
            EA <= WAIT_CMD;
            sclk <= 1'b0;
            se <= 4'b0000;
            ram_we <= 1'b0;
            ram_addr <= 8'h00; // Escrita incremental 
            ram_data <= 8'h00;
            mosi <= 1'b0;
            bit_counter <= 16;
            target_sensor <= 2'b00;
            shift_reg <= 16'h0000;
            ready <= 1'b0;
        end else begin
            case (EA)
                WAIT_CMD: begin
                    ram_we <= 1'b0;
                    se <= 4'b0000;
                    sclk <= 1'b0;
                    bit_counter <= 16;
                    ready <= 1'b1; // Sinaliza que está pronto 
                    
                    if (start == 1'b1) begin
                        ready <= 1'b0; // Fica ocupado
                        target_sensor <= reg_id; // Guarda o sensor pedido 
                        EA <= SELECT_SENSOR; 
                    end
                end

                SELECT_SENSOR: begin
                    se <= (4'b0001 << target_sensor);
                    sclk <= 1'b0;
                    EA <= SPI_CLOCK_LOW;
                end

                SPI_CLOCK_LOW: begin
                    sclk <= 1'b0; 
                    EA <= SPI_CLOCK_HIGH;
                end

                SPI_CLOCK_HIGH: begin
                    sclk <= 1'b1; 
                    shift_reg <= {shift_reg[14:0], miso}; // Recebe bit a bit
                    
                    if (bit_counter > 1) begin
                        bit_counter <= bit_counter - 1;
                        EA <= SPI_CLOCK_LOW; 
                    end else begin
                        EA <= WRITE_RAM_HIGH; 
                    end
                end

                WRITE_RAM_HIGH: begin
                    sclk <= 1'b0;
                    se <= 4'b0000;
                    ram_data <= shift_reg[15:8];
                    ram_we <= 1'b1; 
                    EA <= WRITE_RAM_LOW;
                end

                WRITE_RAM_LOW: begin
                    ram_addr <= ram_addr + 1; // Incrementa endereço da RAM 
                    ram_data <= shift_reg[7:0];
                    ram_we <= 1'b1;
                    EA <= FINISH_READ;
                end

                FINISH_READ: begin
                    ram_we <= 1'b0; 
                    ram_addr <= ram_addr + 1; 
                    EA <= WAIT_CMD; // Retorna para esperar a próxima ordem
                end

                default: EA <= WAIT_CMD;
            endcase
        end
    end
endmodule