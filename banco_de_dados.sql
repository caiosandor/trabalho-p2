create database if not exists TechMarica;
use TechMarica;
drop database T;

create table Funcionarios (
id_funcionario int auto_increment primary key,
nome varchar(100) not null,
funçao varchar(50) not null, -- Ex: Montagem, Teste, Engenharia
situacao enum('ATIVO', 'INATIVO') default 'ATIVO' not null
);

create table  Maquinas (
id_maquina int auto_increment primary key,
codigo_patrimonio varchar(20) unique not null,
modelo varchar(50) not null,
fabricante varchar(50)
);

create table Produtos (
id_produto int auto_increment primary key,
codigo_interno varchar(20) unique not null,
nome_comercial varchar(100) not null,
responsavel_tecnico varchar(100) not null,
custo_producao decimal(10, 2) not null,
data_cadastro date not null default (current_date) 
);

insert into Funcionarios (nome, funçao, situacao) values
('Carlos Silva', 'Engenharia', 'ATIVO'),
('Ana Souza', 'Montagem', 'ATIVO'),
('Roberto Mendes', 'Qualidade', 'INATIVO'), 
('Fernanda Lima', 'Supervisão', 'ATIVO'),
('João Pedro', 'Logística', 'ATIVO');


insert into Maquinas (codigo_patrimonio, modelo, fabricante) values
('MAQ-001', 'Soldadora SMD V2', 'Siemens'),
('MAQ-002', 'Impressora 3D Ind.', 'Stratasys'),
('MAQ-003', 'Braço Robótico A1', 'Kuka');


insert into Produtos (codigo_interno, nome_comercial, responsavel_tecnico, custo_producao, data_cadastro) values
('SEN-010', 'Sensor de Umidade Maricá V1', 'Carlos Silva', 45.50, '2020-01-15'),
('MOD-WIFI', 'Módulo Wi-Fi IoT', 'Fernanda Lima', 80.00, '2021-06-20'),
('PL-CIRC', 'Placa Base 4Camadas', 'Carlos Silva', 120.00, '2019-11-05'),
('CTRL-SOL', 'Controlador Solar Tech', 'Mariana Ximenes', 250.00, '2022-03-10'),
('SEN-TEMP', 'Sensor Térmico Precision', 'Fernanda Lima', 30.00, '2023-01-01');


-- 4. Tabela de Ordens de Produção
create table ordensproducao (
id_ordem int auto_increment primary key,
id_produto int not null,
id_maquina int not null,
id_funcionario_autorizou int not null,
data_inicio datetime default current_timestamp,
data_conclusao datetime null,
status_ordem varchar(20) default 'aguardando', 

constraint fk_ordem_produto foreign key (id_produto) references produtos(id_produto),
constraint fk_ordem_maquina foreign key (id_maquina) references maquinas(id_maquina),
constraint fk_ordem_func foreign key (id_funcionario_autorizou) references funcionarios(id_funcionario)
);


-- Inserindo Ordens de Produção (Histórico)
insert into OrdensProducao (id_produto, id_maquina, id_funcionario_autorizou, data_inicio, data_conclusao, status_ordem) values
(1, 1, 4, '2023-10-01 08:00:00', '2023-10-01 12:00:00', 'FINALIZADA'),
(2, 2, 1, '2023-10-02 09:30:00', null, 'EM PRODUÇÃO'),
(3, 1, 4, '2023-10-03 14:00:00', '2023-10-03 18:00:00', 'FINALIZADA'),
(1, 3, 2, '2023-10-04 10:00:00', null, 'AGUARDANDO'),
(5, 2, 1, '2023-10-05 08:00:00', null, 'EM PRODUÇÃO');


-- 1. listagem completa das ordens de produção com seus detalhes (produto, máquina, funcionário e datas)
select op.id_ordem, p.nome_comercial as produto, m.modelo as maquina_utilizada, f.nome as autorizado_por, 
DATE_FORMAT(op.data_inicio, '%d/%m/%Y %H:%i') as inicio_formatado,op.status_ordem
from OrdensProducao op
inner join Produtos p on op.id_produto = p.id_produto
inner join  Maquinas m on op.id_maquina = m.id_maquina
inner join Funcionarios f on op.id_funcionario_autorizou = f.id_funcionario;

-- 2. filtragem de funcionários inativos
select * from Funcionarios where situacao = 'INATIVO';

-- 3. contagem total de produtos por responsável técnico
select responsavel_tecnico, COUNT(*) as total_produtos_criados, avg(custo_producao) as media_custo from Produtos group by responsavel_tecnico;

-- 4. Seleção de produtos cujo nome começa com 's'
select codigo_interno, nome_comercial  from Produtos where nome_comercial like 'S%';

-- 5. cálculo automático da "idade" do produto (em anos) desde sua criação no catálogo
select nome_comercial, data_cadastro, timestampdiff(year, data_cadastro, curdate()) as anos_existencia from produtos;

-- 6. desempenho por maquina
select
m.modelo as maquina, count(op.id_ordem) as total_ordens_finalizadas, avg(timestampdiff(hour, op.data_inicio, op.data_conclusao)) as tempo_medio_producao_horas
from ordensproducao op inner join maquinas m on op.id_maquina = m.id_maquina where op.status_ordem = 'FINALIZADA' group by m.modelo order by total_ordens_finalizadas desc;

-- 7. produtos sem produção recente

select
p.codigo_interno,
p.nome_comercial,
p.responsavel_tecnico
from produtos p
left join ordensproducao op on p.id_produto = op.id_produto
where op.id_ordem is null;


-- view
create or replace view view_relatorioproducao as
select 
op.id_ordem,
p.nome_comercial,
p.custo_producao,
m.codigo_patrimonio as cod_maquina,
f.nome as supervisor,
op.status_ordem,

if(op.data_conclusao is not null, 
concat(timestampdiff(hour, op.data_inicio, op.data_conclusao), ' horas'), 
'em andamento') as duracao_processo
from ordensproducao op
join produtos p on op.id_produto = p.id_produto
join maquinas m on op.id_maquina = m.id_maquina
join funcionarios f on op.id_funcionario_autorizou = f.id_funcionario;


-- Testando a View
select * from View_RelatorioProducao;

-- Procedimento para registrar uma nova ordem automaticamente(procedure)

delimiter $$

create procedure registrarordemproducao (
in p_id_produto int,
in p_id_funcionario int,
in p_id_maquina int
)
begin

insert into ordensproducao (id_produto, id_maquina, id_funcionario_autorizou, data_inicio, status_ordem)
values (p_id_produto, p_id_maquina, p_id_funcionario, now(), 'em produção');


select concat('ordem de produção criada com sucesso para o produto id: ', p_id_produto) as mensagem;
end $$


delimiter ;

-- testando a procedure (produto 4, funcionario 1, maquina 3)
call registrarordemproducao(4, 1, 3);


-- criando o trigger
delimiter $$

create trigger trg_finalizarordem
before update on ordensproducao
for each row
begin

if old.data_conclusao is null and new.data_conclusao is not null then
set new.status_ordem = 'FINALIZADA';
end if;
end $$


DELIMITER ;

-- ultima validação
select id_ordem, status_ordem, data_conclusao from ordensproducao where id_ordem = 2;

update ordensproducao 
set data_conclusao = now() 
where id_ordem = 2;

select id_ordem, status_ordem, data_conclusao from ordensproducao where id_ordem = 2;
