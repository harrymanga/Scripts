#!/usr/bin/env bash
# AUTHOR: gotbletu (@gmail|twitter|youtube|github|lbry)

helpmsg() {
  printf "%s\n" "desc: Convertir la imagen del disco del juego a CHD (Playstation, Dreamcast, Sega Saturn, Sega CD/Mega CD, PC Engine CD/TurboGrafx CD, Panasonic 3DO ...etc)"
  printf "%s\n" "demo: https://youtu.be/DdPjj0XGlpo"
  printf "%s\n" "depend: mame-tools"
  printf "%s\n" "        task-spooler (opcional)"
  printf "\n"
  printf "%s\n" "uso: ${0##*/} [cue|gdi]"
  printf "\n"
  printf "%s\n" "  $ ${0##*/} file.cue"
  printf "%s\n" "  $ ${0##*/} file1.cue file2.gdi file3.cue"
  printf "%s\n" "  $ ${0##*/} -t *.cue"
  printf "%s\n" "  $ ${0##*/} *.cue"
  printf "%s\n" "  $ ${0##*/} *.gdi"
  printf "\n"
  printf "%s\n" "opciónes:"
  printf "%s\n" "  -t, --tsp                  uso con cola de tareas (TS_SOCKET=/tmp/sh tsp)"
  printf "%s\n" "  -h, --help                 mostrar este mensaje de ayuda"
  printf "\n"
}
if [ $# -lt 1 ]; then
  helpmsg
  exit 1
elif [ "$1" = -h ] || [ "$1" = --help ]; then
  helpmsg
  exit 0
elif [ "$1" = -t ] || [ "$1" = --tsp ]; then
  myArray=("${@:2}")
  for arg in "${myArray[@]}"; do
    TS_SOCKET=/tmp/sh tsp chdman createcd -i "$arg" -o "${arg%.*}.chd"
  done
else
  myArray=("$@")
  for arg in "${myArray[@]}"; do
    chdman createcd -i "$arg" -o "${arg%.*}.chd"
  done
fi
