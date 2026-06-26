# 1. Cria a biblioteca de trabalho virtual (ignora se já existir)
vlib work

# 2. Compila os arquivos que você possui no momento
# (Quando criar o top.sv e a ram, adicione-os nesta linha separando por espaço)
vlog sensor.sv coletor_dados.sv ram.sv top.sv tb.sv

# 3. Inicia a simulação apontando para o testbench
# O argumento -voptargs=+acc garante que nenhum sinal interno seja ocultado
vsim -voptargs=+acc work.tb

# 4. Configura a janela de ondas
# Adiciona todos os sinais da simulação recursivamente
add wave -r /*

# 5. Roda a simulação até encontrar o $stop no testbench
run -all

# 6. Ajusta o zoom da janela de ondas para caber tudo na tela
wave zoom full