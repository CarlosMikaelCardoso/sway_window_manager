#!/bin/bash

# Garante janela de ajuda mesmo em instalações onde zenity ainda não existe
if ! command -v zenity >/dev/null 2>&1; then
	sudo apt update && sudo apt install -y zenity
fi

show_page() {
	local titulo="$1"
	local texto="$2"

	zenity --info \
		--title="$titulo" \
		--text="$texto" \
		--width=520 \
		--height=420 \
		--ok-label="Voltar"
}

while true; do
	opcao=$(zenity --list \
		--title="Sway WM - Guia de Atalhos" \
		--text="Escolha uma seção para visualizar:" \
		--column="Seções" \
		"Aplicativos e Sistema" \
		"Navegação de Janelas" \
		"Workspaces" \
		"Barra e Ajuda" \
		"Captura de Tela" \
		"Configurações Aplicadas" \
		"Dicas Rápidas" \
		"Fechar" \
		--height=360 \
		--width=420)

	if [ $? -ne 0 ] || [ "$opcao" = "Fechar" ]; then
		exit 0
	fi

	case "$opcao" in
	"Aplicativos e Sistema")
		show_page "Atalhos - Aplicativos e Sistema" "
<b>APLICATIVOS E SISTEMA</b>

• <b>Super + Enter</b>       → Abrir terminal (foot)
• <b>Super + D</b>           → Abrir menu de apps (wofi)
• <b>Super + Q</b>           → Fechar janela atual
• <b>Super + Shift + C</b>   → Recarregar configuração do Sway
• <b>Super + Shift + E</b>   → Abrir menu de saída
"
		;;
	"Navegação de Janelas")
		show_page "Atalhos - Navegação de Janelas" "
<b>NAVEGAÇÃO DE JANELAS (WORKSPACE ATUAL)</b>

• <b>Alt + Tab</b>           → Abre seletor visual de janelas (estilo Windows)
• <b>Alt + Shift + Tab</b>   → Mesmo seletor visual

<i>Dica:</i> No seletor, digite para filtrar e pressione Enter para focar.
<i>Se Alt+Shift+Tab não responder, use Alt+ISO_Left_Tab.</i>
<i>Janelas escondidas aparecem como [escondida] e podem ser restauradas pelo Alt+Tab.</i>

• <b>Super + Seta Esquerda</b> → Focar janela à esquerda
• <b>Super + Seta Direita</b>  → Focar janela à direita
• <b>Super + Seta Cima</b>     → Focar janela acima
• <b>Super + Seta Baixo</b>    → Focar janela abaixo

• <b>Super + Shift + Setas</b> → Mover janela na direção escolhida

<b>AÇÕES DE JANELA</b>

• <b>Super + A</b>             → Menu de ações da janela atual
• <b>Super + Shift + Espaço</b> → Alternar modo flutuante (sobreposição)
• <b>Super + F</b>             → Maximizar/Restaurar (tela cheia)
• <b>Super + -</b>             → Esconder janela (scratchpad)
• <b>Super + =</b>             → Mostrar janela escondida
"
		;;
	"Workspaces")
		show_page "Atalhos - Workspaces" "
<b>WORKSPACES</b>

• <b>Super + 1..5</b>         → Ir para o workspace 1 ao 5
• <b>Super + Shift + 1..5</b> → Mover janela para workspace 1 ao 5

<i>Use esses atalhos para organizar apps por contexto (ex.: web, código, terminal).</i>
"
		;;
	"Barra e Ajuda")
		show_page "Atalhos - Barra e Ajuda" "
<b>BARRA E AJUDA</b>

• <b>Super + Ctrl + B</b>    → Mostrar/Ocultar Waybar
• <b>Super + H</b>           → Abrir este guia de atalhos

<b>CARDS DE JANELA NA WAYBAR</b>

• <b>—</b>                    → Esconder janela atual (scratchpad) | <b>Teclado:</b> Super + -
• <b>▢</b>                    → Maximizar/Restaurar janela atual | <b>Teclado:</b> Super + F
• <b>✕</b>                    → Fechar janela atual | <b>Teclado:</b> Super + Q

<i>Os cards aparecem somente quando existir janela no workspace atual.</i>
"
		;;
	"Captura de Tela")
		show_page "Atalhos - Captura de Tela" "
<b>CAPTURA DE TELA</b>

• <b>Print</b>               → Captura tela inteira
• <b>Shift + Print</b>       → Captura área selecionada
• <b>Ctrl + Print</b>        → Captura tela inteira com atraso (3s)

<i>As imagens são salvas em ~/Imagens/prints</i>
"
		;;
	"Configurações Aplicadas")
		show_page "Sway - Configurações Aplicadas" "
<b>CONFIGURAÇÕES APLICADAS</b>

• Teclado: layout <b>br</b>
• Mouse: aceleração <b>flat</b>, sensibilidade <b>-0.2</b>, tap <b>on</b>
• Aparência: tema Ubuntu com gaps e Waybar em cards flutuantes
"
		;;
	"Dicas Rápidas")
		show_page "Sway - Dicas Rápidas" "
<b>DICAS RÁPIDAS</b>

• Reaplicar tema/configuração: rode <i>./customiza.sh</i>
• Instalação base do ambiente: rode <i>./install.sh</i>
• Arquivo principal do Sway: <i>~/.config/sway/config</i>
"
		;;
	esac
done
