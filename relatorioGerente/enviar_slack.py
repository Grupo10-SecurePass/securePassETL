import os
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

slack_token = ""
channel_id = ""
file_path = "C:/Users/Gabri/Downloads/securePassETL/relatorioGerente/relatorio_final.pdf"

client = WebClient(token=slack_token)

def enviar_pdf_slack(file_path, channel_id):
    if not os.path.exists(file_path):
        print(f"Erro: O arquivo {file_path} não foi encontrado.")
        return

    try:
        response = client.files_upload_v2(
            channels=[channel_id],
            file=file_path,
            initial_comment="Segue o relatório atualizado.",
            title="Relatório Final"
        )
        print("Relatório enviado com sucesso para o Slack!")
    except SlackApiError as e:
        print(f"Erro ao enviar relatório: {e.response['error']}")

enviar_pdf_slack(file_path, channel_id)