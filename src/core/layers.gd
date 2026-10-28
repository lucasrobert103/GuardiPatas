class_name Layers
## Camadas de colisão (bits). Ver docs/09-arquitetura.md → "Física e colisões".

const TERRAIN := 1      # chão, pedras, ninhos, lâmpadas, plataformas
const LINE := 2         # linhas desenhadas
const ANIMAL := 4       # bichinhos
const FLYER := 8        # insetos voadores
const WALKER := 16      # insetos que andam
const PROP := 32        # caixas e tábuas soltas

const LINE_MASK := TERRAIN | LINE | ANIMAL | FLYER | WALKER | PROP
const ANIMAL_MASK := TERRAIN | LINE | ANIMAL | FLYER | WALKER | PROP
const FLYER_MASK := TERRAIN | LINE | ANIMAL | FLYER | PROP
const WALKER_MASK := TERRAIN | LINE | ANIMAL | PROP
const PROP_MASK := TERRAIN | LINE | ANIMAL | FLYER | WALKER | PROP
## O que impede o desenho de passar.
const DRAW_BLOCK := TERRAIN | LINE | ANIMAL | PROP
