module sensor #(
    parameter SENSOR_ID = 0,
    parameter REG_COUNT = 2, // 2 registradores de 8 bits = 16 bits totais
    parameter REG_WIDTH = 8
)(
    input  logic clock, // Clock interno sensor
    input  logic reset, // Ativo em nível baixo 

    input  logic se,    
    output logic miso, 
    input  logic mosi,  
    input  logic sclk   
);

    
    // Lista de registradores (Memória interna)
    logic [REG_WIDTH-1:0] regs [REG_COUNT-1:0];

    // Registrador temporário para deslocamento
    logic [(REG_WIDTH * REG_COUNT)-1:0] temp_reg;
    
    // Contador para gerenciar o envio dos bits
    logic [4:0] bit_counter; 

    
    logic [31:0] clk_div;

    // Máquina de estados - SPI
    typedef enum logic [2:0] {IDLE, SETUP, RECEIVE, SEND, CLEANUP} state_t;
    state_t EA, PE;

    
    // Atualização dos Dados Clock Interno
    always_ff @(posedge clock or negedge reset) begin   
        if (reset == 0) begin
            clk_div <= 0;
            for (int i = 0; i < REG_COUNT; i++) begin
                regs[i] <= SENSOR_ID + i; // Valor base inicial de reset
            end
        end else begin
            clk_div <= clk_div + 1;
            // Atualiza os dados artificialmente a cada X ciclos
            if (clk_div == 32'd100_000) begin
                clk_div <= 0;
                // Simula uma nova leitura alterando o registrador 0
                regs[0] <= regs[0] + 1'b1; 
                regs[1] <= SENSOR_ID;
            end
        end
    end


    // FSM do SPI - Atualização de Estado
    always_ff @(posedge sclk or negedge reset) begin
        if (reset == 0) begin
            EA <= IDLE;
        end else begin 
            EA <= PE;
        end   
    end   

    
    // FSM do SPI - Lógica de Próximo Estado
    always_comb begin
        PE = EA; // mantém o estado atual
        case (EA)
            IDLE: begin
                if (se == 1'b1) PE = SETUP; // Acorda quando selecionado
            end
            
            SETUP: begin
                PE = SEND; // Após carregar os dados, vai para envio
            end
            
            SEND: begin
                // Fica em SEND até que todos os bits sejam enviados
                if (bit_counter == 0) PE = CLEANUP; 
            end
            
            CLEANUP: begin
                if (se == 1'b0) PE = IDLE; 
            end
            
            default: PE = IDLE;
        endcase 
    end   


    always_ff @(negedge sclk or negedge reset) begin
        if (reset == 0) begin
            temp_reg    <= 0;
            bit_counter <= (REG_WIDTH * REG_COUNT) - 1; // 15 para 16 bits
            miso        <= 1'b0;
        end else begin
            case (EA)
                IDLE: begin
                    miso <= 1'b0;
                    // Reinicia o contador de bits
                    bit_counter <= (REG_WIDTH * REG_COUNT) - 1; 
                end
                
                SETUP: begin
                    
                    // Concatena os registradores no temp_reg
                    temp_reg <= {regs[1], regs[0]}; 
                end
                
                SEND: begin
                    // Joga o Bit Mais Significativo no pino MISO
                    miso <= temp_reg[(REG_WIDTH * REG_COUNT) - 1];
                    
                    // Desloca os bits restantes para a esquerda
                    temp_reg <= {temp_reg[(REG_WIDTH * REG_COUNT) - 2 : 0], 1'b0};
                    
                    if (bit_counter > 0) begin
                        bit_counter <= bit_counter - 1;
                    end
                end
                
                CLEANUP: begin
                    miso <= 1'b0; // Limpa o barramento
                end
            endcase
        end
    end

endmodule