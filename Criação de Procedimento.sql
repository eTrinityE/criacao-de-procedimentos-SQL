-- 1) Insira na base de dados
-- 2 Clientes, 2 contas, 8 registros de depósitos e 6 registros de saques
-- distribuídos pelas diversas contas.

use MePoupe;

INSERT INTO Cliente (cod_cliente, nome, CPF, sexo, dt_nasc, Telefone, email) VALUES
  (5, 'João Silva', '12345678910', 'M', '1990-01-01', '(11) 99999-9999', 'joao.silva@email.com'),
  (6, 'Maria Souza', '98765432110', 'F', '1985-05-15', '(11) 88888-8888', 'maria.souza@email.com');
  
INSERT INTO Conta_corrente (cod_conta, dt_hora_abertura, saldo, status, cod_cliente) VALUES
  (7, '2023-04-17', 1000.00, 'Ativa', 1),
  (8, '2023-04-17', 500.00, 'Ativa', 2);
  
INSERT INTO Registro_Deposito (cod_deposito, cod_conta, dt_deposito, valor_deposito) VALUES
  (8, 1, '2023-04-17', 200.00),
  (9, 1, '2023-04-17', 300.00),
  (10, 2, '2023-04-17', 150.00),
  (11, 1, '2023-04-17', 50.00),
  (12, 2, '2023-04-17', 100.00),
  (13, 1, '2023-04-17', 30.00),
  (14, 2, '2023-04-17', 70.00),
  (15, 1, '2023-04-17', 40.00);
  
select * from registro_saque;
  
INSERT INTO Registro_Saque (cod_saque, cod_conta, dt_saque, valor_saque) VALUES
  (8, 1, '2023-04-17', 50.00),
  (9, 2, '2023-04-17', 100.00),
  (10, 1, '2023-04-17', 20.00),
  (11, 2, '2023-04-17', 50.00),
  (12, 2, '2023-04-17 ', 30.00),
  (13, 1, '2023-04-17', 70.00);
  
-- Crie o procedimento sp_insere_cli que irá receber como dados de entrada o nome,
-- CPF, sexo, endereço, telefone e email de um cliente e fará a inserção na tabela cliente.
-- Validar o preenchimento de campos obrigatórios.
DELIMITER $
CREATE PROCEDURE sp_insere_cli(p_nome VARCHAR(50), p_cpf VARCHAR (11), p_sexo CHAR(1),
p_dt_nasc date, p_telefone VARCHAR(15), p_email VARCHAR(100))
begin
if (p_nome is null OR p_cpf is null OR p_sexo is null) then
	select 'Campos obrigatórios não preenchidos' as Mensagem;
else
	insert into Cliente (nome, CPF, sexo, dt_nasc, telefone,  email)
    values (p_nome, p_cpf, p_sexo, p_dt_nasc, p_telefone, p_email);
end if;
end$
DELIMITER ;

-- 3) Faça um procedimento para registrar uma transferência de uma conta para outra:
-- Observações:
-- – Parâmetros de entrada: codigo da conta de origem, codigo da conta de
-- destino,valor da transferência.
-- – Validar se a conta de origem tem saldo suficiente.
-- – Criar a tabela registro de transferência
-- • Campos: codigo da transferência, codigo da conta de origem, codigo da
-- conta de destino, valor da transferência, data e hora.
-- – Atualizar o saldo da conta de origem e da conta de destino.

create table registro_transferencia(
cod_transferencia int auto_increment primary key,
cod_conta_origem int not null, 
cod_conta_destino int not null, 
valor_transf decimal(10,2),
foreign key (cod_conta_origem) references conta_corrente(cod_conta),
foreign key (cod_conta_destino) references conta_corrente(cod_conta)
);

-- 3) Faça um procedimento para registrar uma transferência de uma conta para outra:
-- Observações:
-- – Parâmetros de entrada: codigo da conta de origem, codigo da conta de destino,valor da transferência.
-- – Validar se a conta de origem tem saldo suficiente. Criar a tabela registro de transferência
-- • Campos: codigo da transferência, codigo da conta de origem, codigo da
-- conta de destino, valor da transferência, data e hora.
-- – Atualizar o saldo da conta de origem e da conta de destino.

DELIMITER $
create procedure sp_insere_trans (var_conta_origem int, var_conta_destino int, var_valor DECIMAL(10,2)) 
begin
    Declare saldo_origem DECIMAL(10,2);
    set saldo_origem = (select saldo from conta_corrente where cod_conta = var_conta_origem);
    if (saldo_origem < var_valor) then
        select "Saldo insuficiente" as msg;
    else
        update conta_corrente set saldo = saldo+var_valor where cod_conta = var_conta_destino; 
        update conta_corrente set saldo = saldo-var_valor where cod_conta = var_conta_origem;
        insert into registro_transferencia (cod_conta_origem, cod_conta_destino, valor_transferencia, data_hora) 
        values (var_conta_origem, var_conta_destino, var_valor, current_timestamp());
    end if;
end $
DELIMITER ;

-- 4) Crie um procedimento que terá como entrada uma data de inicial e uma data final e
-- irá gerar um relatório contendo o nome do cliente, número da conta e o valor total de
-- depósitos realizados para a conta no período informado. Ordenar pelo valor total dos
-- depósitos.

DELIMITER $
create procedure sp_relatorio_dep (data_inicial date, data_final date)
begin
    select nome, r.cod_conta, sum(valor_deposito) from registro_deposito r
        join conta_corrente c on c.cod_conta = r.cod_conta
        join cliente cl on cl.cod_cliente = c.cod_cliente
        where dt_deposito between data_inicial and data_final
        group by 1 order by 3;
end $
DELIMITER ;

-- 4)Crie um procedimento para fazer o relatório anual das contas, informando como
-- entrada o ano e código do relatório desejado (1: total de Saques ou 2: total de
-- depósitos). O relatório deverá conter o número da conta, mês , total de saques (se
-- código do relatório for 1) ou total de depósitos (se código do relatório for 2).

DELIMITER $
create procedure sp_relatorio_ano (ano year, cod int)
begin
    if (cod=1) then 
        select c.cod_conta, month(dt_saque) as mes, sum(valor_saque) as total 
        from registro_saque r
        right join conta_corrente c on c.cod_conta = r.cod_conta
        and year(dt_saque) = ano
        group by 1,2 order by 3;
    elseif (cod=2) then
        select c.cod_conta, month(dt_deposito) as mes, sum(valor_deposito) as total from registro_deposito r
        right join conta_corrente c on c.cod_conta = r.cod_conta
        and year(dt_deposito) = ano
        group by 1,2 order by 3;
    else
        select "codigo invalido" as msg;
    end if;

end$
DELIMITER ;






  

