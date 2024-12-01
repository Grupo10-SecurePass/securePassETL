install.packages("RMySQL")
install.packages("ggplot2")
install.packages("dplyr")
install.packages("rmarkdown")
install.packages("httr")
install.packages("here")
tinytex::install_tinytex()

library(RMySQL)
library(ggplot2)
library(dplyr)
library(rmarkdown)
library(httr)
library(here)
library(tinytex)

db <- dbConnect(MySQL(),
                user = 'root', 
                password = 'Ga986745#',
                dbname = 'securepass',
                host = 'localhost')

query_upload <- "
SELECT DATE(dataRegistro) AS dia, AVG(registro) AS media_upload
FROM captura
JOIN componente ON captura.fkComponente = componente.idComponente 
JOIN dispositivo ON captura.fkDispositivo = 1
WHERE componente.nome = 'RedeEnviada' AND captura.dataRegistro BETWEEN '2024-11-19' AND '2024-12-02'
GROUP BY DATE(captura.dataRegistro);
"

query_download <- "
SELECT DATE(dataRegistro) AS dia, AVG(registro) AS media_download
FROM captura
JOIN componente ON captura.fkComponente = componente.idComponente 
JOIN dispositivo ON captura.fkDispositivo = 1
WHERE componente.nome = 'RedeRecebida' AND captura.dataRegistro BETWEEN '2024-11-19' AND '2024-12-02'
GROUP BY DATE(captura.dataRegistro);
"

query_cpu <- "
SELECT DATE(dataRegistro) AS dia, AVG(registro) AS media_cpu
FROM captura
JOIN componente ON captura.fkComponente = componente.idComponente 
JOIN dispositivo ON captura.fkDispositivo = 1
WHERE componente.nome = 'PercCPU' AND captura.dataRegistro BETWEEN '2024-11-19' AND '2024-12-02'
GROUP BY DATE(captura.dataRegistro);
"

query_risco <- "
SELECT DATE(captura.dataRegistro) AS dia, COUNT(DISTINCT dispositivo.idDispositivo) AS maquinas_em_risco
FROM captura
JOIN dispositivo ON captura.fkDispositivo = 1
JOIN limite ON captura.fkComponente = limite.fkComponente AND captura.fkDispositivo = limite.fkDispositivo
WHERE 
    (limite.tipo = 'acima' AND captura.registro > limite.valor)
    OR 
    (limite.tipo = 'abaixo' AND captura.registro < limite.valor)
    AND dataRegistro BETWEEN '2024-11-19' AND '2024-12-02'
GROUP BY DATE(captura.dataRegistro);
"

dados_upload <- dbGetQuery(db, query_upload)
dados_download <- dbGetQuery(db, query_download)
dados_cpu <- dbGetQuery(db, query_cpu)
dados_risco <- dbGetQuery(db, query_risco)

dbDisconnect(db)

dados_risco <- dados_risco %>%
  mutate(dia = as.Date(dia))
todos_os_dias <- seq.Date(as.Date("2024-11-19"), as.Date("2024-12-02"), by = "day")
dados_risco_completos <- dados_risco %>%
  right_join(data.frame(dia = todos_os_dias), by = "dia") %>%
  mutate(maquinas_em_risco = ifelse(is.na(maquinas_em_risco), 0, maquinas_em_risco))

grafico_upload <- ggplot(dados_upload, aes(x = dia, y = media_upload)) +
  geom_col(fill = "blue") +
  labs(title = "Média de Upload", x = "Dia", y = "Média (%)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

grafico_download <- ggplot(dados_download, aes(x = dia, y = media_download)) +
  geom_col(fill = "green") +
  labs(title = "Média de Download", x = "Dia", y = "Média (%)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

grafico_cpu <- ggplot(dados_cpu, aes(x = dia, y = media_cpu)) +
  geom_col(fill = "orange") +
  labs(title = "Média de Uso de CPU", x = "Dia", y = "Média (%)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

grafico_risco <- ggplot(dados_risco_completos, aes(x = dia, y = maquinas_em_risco)) +
  geom_bar(stat = "identity", fill = "red") +
  labs(title = "Máquinas em Risco por Dia", x = "Dia", y = "Quantidade de Máquinas") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("C:/Users/Gabri/Downloads/securePassETL/relatorioGerente/grafico_upload.png", grafico_upload, width = 8, height = 5)
ggsave("C:/Users/Gabri/Downloads/securePassETL/relatorioGerente/grafico_download.png", grafico_download, width = 8, height = 5)
ggsave("C:/Users/Gabri/Downloads/securePassETL/relatorioGerente/grafico_cpu.png", grafico_cpu, width = 8, height = 5)
ggsave("C:/Users/Gabri/Downloads/securePassETL/relatorioGerente/grafico_risco.png", grafico_risco, width = 8, height = 5)

rmarkdown::render(input = "C:/Users/Gabri/Downloads/securePassETL/relatorioGerente/relatorio.Rmd", 
                  output_format = "pdf_document", 
                  output_file = "relatorio_final.pdf", 
                  output_dir = "C:/Users/Gabri/Downloads/securePassETL/relatorioGerente")
