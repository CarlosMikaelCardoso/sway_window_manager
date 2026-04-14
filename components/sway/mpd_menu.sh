#!/bin/bash

# Menu MPD com playlists e biblioteca local

set -euo pipefail

notify() {
    notify-send "MPD" "$1" >/dev/null 2>&1 || true
}

refresh_waybar() {
    pkill -RTMIN+10 waybar >/dev/null 2>&1 || true
}

ensure_tools() {
    if ! command -v mpc >/dev/null 2>&1; then
        notify "mpc nao encontrado"
        exit 1
    fi
    if ! command -v zenity >/dev/null 2>&1; then
        notify "zenity nao encontrado"
        exit 1
    fi
    systemctl --user start mpd >/dev/null 2>&1 || true
}

pick_song() {
    local songs choice
    songs="$(mpc listall 2>/dev/null || true)"
    if [ -z "${songs:-}" ]; then
        mpc update >/dev/null 2>&1 || true
        notify "Biblioteca vazia. Coloque musicas em ~/Musicas"
        return 0
    fi

    choice="$(printf '%s\n' "$songs" | zenity --list --title='Escolher musica' --text='Selecione uma faixa para tocar' --column='Faixa' --height=520 --width=900 2>/dev/null || true)"
    [ -z "${choice:-}" ] && return 0

    mpc clear >/dev/null 2>&1 || true
    mpc add "$choice" >/dev/null 2>&1 || true
    mpc play >/dev/null 2>&1 || true
    refresh_waybar
}

save_playlist() {
    local name
    name="$(zenity --entry --title='Salvar playlist' --text='Nome da playlist:' 2>/dev/null || true)"
    [ -z "${name:-}" ] && return 0

    if mpc save "$name" >/dev/null 2>&1; then
        notify "Playlist '$name' salva"
    else
        # Se ja existir, substitui
        mpc rm "$name" >/dev/null 2>&1 || true
        mpc save "$name" >/dev/null 2>&1 || true
        notify "Playlist '$name' atualizada"
    fi
}

load_playlist() {
    local pls pick
    pls="$(mpc lsplaylists 2>/dev/null || true)"
    if [ -z "${pls:-}" ]; then
        notify "Nenhuma playlist salva"
        return 0
    fi

    pick="$(printf '%s\n' "$pls" | zenity --list --title='Carregar playlist' --text='Escolha uma playlist' --column='Playlist' --height=420 --width=520 2>/dev/null || true)"
    [ -z "${pick:-}" ] && return 0

    mpc clear >/dev/null 2>&1 || true
    mpc load "$pick" >/dev/null 2>&1 || true
    mpc play >/dev/null 2>&1 || true
    refresh_waybar
    notify "Playlist '$pick' carregada"
}

ensure_tools

action="$(zenity --list \
    --title='MPD - Biblioteca Local' \
    --text='Escolha uma acao' \
    --column='Acao' \
    'Escolher musica' \
    'Atualizar biblioteca' \
    'Salvar playlist atual' \
    'Carregar playlist' \
    'Pausar/Retomar' \
    'Proxima musica' \
    'Musica anterior' \
    'Parar' \
    'Limpar fila' \
    --height=460 --width=420 2>/dev/null || true)"

case "$action" in
    'Escolher musica')
        pick_song
        ;;
    'Atualizar biblioteca')
        mpc update >/dev/null 2>&1 || true
        notify 'Biblioteca atualizada'
        ;;
    'Salvar playlist atual')
        save_playlist
        ;;
    'Carregar playlist')
        load_playlist
        ;;
    'Pausar/Retomar')
        mpc toggle >/dev/null 2>&1 || true
        refresh_waybar
        ;;
    'Proxima musica')
        mpc next >/dev/null 2>&1 || true
        refresh_waybar
        ;;
    'Musica anterior')
        mpc prev >/dev/null 2>&1 || true
        refresh_waybar
        ;;
    'Parar')
        mpc stop >/dev/null 2>&1 || true
        refresh_waybar
        ;;
    'Limpar fila')
        mpc clear >/dev/null 2>&1 || true
        refresh_waybar
        notify 'Fila limpa'
        ;;
esac
