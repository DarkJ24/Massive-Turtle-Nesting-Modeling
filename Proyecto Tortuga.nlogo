extensions [csv]

;;*************************
;; DEFINICIÓN DE VARIABLES:
;;*************************

globals ;; Para definir las variables globales.
[
  altura-de-marea
  fase-de-marea
  terreno
  sectores
  cuadrantes
  transectos-berma
  longitud-costa
  distancia-playa
  berma
  puntos-marea
  posicion-marea
  pendiente-marea
  altura-marea-meta
  posicion-final
  mediciones-cuadrantes
  mediciones-transectos-berma
  mediciones-transecto-marea
  tortugas-generadas
  tortugas-anidadas
  tortugas-no-anidadas
  tortugas-terminadas
]

turtles-own ;; Para definir los atributos de las tortugas.
[
  velocidad-subida ;; dada en metros/minuto
  velocidad-bajada ;; dada en metros/minuto
  fase ;; 0:subir, 1:cama, 2:cavar, 3:poner, 4:rellenar, 5:camuflar, 6:bajar
  tiempo-de-fase ;; tiempo de duracion en minutos de cuando empieza la siguiente fase
  distancia-meta ;; distancia en la cual la tortuga se detiene y continua con la siguiente fase
]

patches-own ;; Para definir los atributos de las parcelas.
[
  altura ;; la altura del terreno
  vegetacion;;      0:no, 1:si
  cuadrante;;       0:no, 1:si
  transecto-berma;; 0:no, 1:si
  transecto-marea;; 0:no, 1:si
]

;;**************************************
;; INICIALIZACIÓN DE VARIABLES GLOBALES:
;;**************************************

to init-globals ;; Para darle valor inicial a las variables globales.

  set altura-de-marea 0
  set fase-de-marea 0  ;; 0: Subiendo, 1: Bajando
  set terreno []
  set cuadrantes []
  set longitud-costa 0
  set distancia-playa 0
  set berma []
  set posicion-marea 0
  set tortugas-generadas 0
  set tortugas-anidadas 0
  set tortugas-no-anidadas 0
  set tortugas-terminadas 0
  set mediciones-cuadrantes []
  set mediciones-transectos-berma []
  set mediciones-transecto-marea []
end

;;**********************
;; FUNCIONES PRINCIPALES
;;**********************

to setup ;; Para inicialzar la simulación con el esquem de ostional

  ca

  reset-ticks

  init-globals

  init-marea

  set-terreno

  set-cuadrantes

  set-transectos-berma

  ask patches
  [
    init-patch
  ]


end

to go ;; Para ejecutar la simulación.

  ifelse posicion-final = posicion-marea
  [
    stop
    resultados-finales
  ]
  [
    actualizar-marea
    ask patches with [vegetacion = 0] [p-comportamiento-patch]
    generar-tortugas
    ask turtles [t-comportamiento-turtle]

    if ticks != 0 and (ticks mod (tiempo-medicion-cuadrantes)) = 0
    [
      set mediciones-cuadrantes lput contar-tortugas-cuadrantes mediciones-cuadrantes
    ]

    if ticks != 0 and (ticks mod (tiempo-medicion-transectos-berma)) = 0
    [
      set mediciones-transectos-berma lput contar-tortugas-transectos-berma mediciones-transectos-berma
    ]

    if ticks != 0 and (ticks mod (tiempo-medicion-transecto-marea)) = 0
    [
      set mediciones-transecto-marea lput contar-tortugas-transecto-marea mediciones-transecto-marea
    ]
    tick
  ]

end


;;*******************************
;; Otras funciones globales:
;;*******************************

to set-terreno

  set terreno csv:from-file "terreno.csv"
  set sectores length terreno

  set longitud-costa sectores * longitud-sector

  let distancia-costa-berma 0
  let distancia-berma-vegetacion 0

  foreach terreno
  [
    terr ->
    if item 0 terr > distancia-costa-berma
    [
      set distancia-costa-berma item 0 terr
    ]
    if item 2 terr > distancia-berma-vegetacion
    [
      set distancia-berma-vegetacion item 2 terr
    ]
  ]

  set distancia-playa distancia-costa-berma + distancia-berma-vegetacion

  resize-world 0 (longitud-costa - 1) 0 (distancia-playa - 1)

end

to set-cuadrantes

  set cuadrantes csv:from-file "cuadrantes.csv"

  foreach cuadrantes
  [
    cuadr ->

    let xs list (item 0 cuadr) (item 2 cuadr)
    let ys list (item 1 cuadr) (item 3 cuadr)

    let x1 min xs
    let y1 min ys

    let x2 max xs
    let y2 max ys

    ask patches with [pxcor >= x1 and pxcor <= x2 and pycor >= y1 and pycor <= y2]
    [
      set cuadrante 1
    ]
  ]
end

to set-transectos-berma

  set transectos-berma csv:from-file "transectos-berma.csv"

  foreach transectos-berma
  [
    transecto ->

    let x item 0 transecto
    let ys list (item 1 transecto) (item 2 transecto)

    let y1 min ys
    let y2 max ys

    ask patches with [pxcor >= x and pxcor <= x + 1 and pycor >= y1 and pycor <= y2]
    [
      set transecto-berma 1
    ]
  ]
end

to set-transecto-marea

  ask patches
  [
    set transecto-marea 0
  ]

  let x-cor 0
  let y-cor 0

  repeat longitud-costa
  [
    set y-cor [pycor] of (min-one-of (patches with [altura > altura-de-marea and pxcor = x-cor]) [pycor])

    ask patches with [pxcor = x-cor and pycor >= y-cor and pycor < (y-cor + 15)]
    [
      set transecto-marea 1
    ]

    set x-cor x-cor + 1
  ]

end

to init-marea

  set puntos-marea csv:from-file "marea.csv"

  let a1 item posicion-marea ( item 0 puntos-marea)

  let a2 item (posicion-marea + 1) ( item 0 puntos-marea)

  let t1 item posicion-marea ( item 1 puntos-marea)

  let t2 item (posicion-marea + 1) ( item 1 puntos-marea)

  set altura-de-marea a1

  set altura-marea-meta a2

  ifelse altura-de-marea < altura-marea-meta
  [ set fase-de-marea 0 ]
  [ set fase-de-marea 1 ]

  set pendiente-marea (a2 - a1) / (t2 - t1)

  repeat t1
  [
    tick
  ]

  set posicion-final (length (item 0 puntos-marea)) - 1

end

to actualizar-marea

  set altura-de-marea altura-de-marea + pendiente-marea

  let fase-de-marea-vieja fase-de-marea

  ifelse fase-de-marea = 0
  [
    if altura-de-marea >= altura-marea-meta
    [ set fase-de-marea 1 ]
  ]
  [
    if altura-de-marea < altura-marea-meta
    [ set fase-de-marea 0 ]
  ]

  if not (fase-de-marea = fase-de-marea-vieja)
  [
    set posicion-marea posicion-marea + 1

    if not (posicion-marea = posicion-final)
    [
      let a2 item (posicion-marea + 1) ( item 0 puntos-marea)

      let t2 item (posicion-marea + 1) ( item 1 puntos-marea)

      set altura-marea-meta a2

      set pendiente-marea (a2 - altura-de-marea) / (t2 - ticks)
    ]
  ]

end

to-report contar-tortugas-cuadrantes

  let medicion-temporal-cuadrantes 0

  ask patches with [cuadrante = 1]
  [
    set medicion-temporal-cuadrantes medicion-temporal-cuadrantes + count turtles-here with [fase < 4]
  ]

  report medicion-temporal-cuadrantes

end

to-report calcular-cuadrantes

  let Ti sum mediciones-cuadrantes
  let Ai count patches with [cuadrante = 1]
  let Aci count patches with [vegetacion = 0]
  let Hi item posicion-final ( item 1 puntos-marea) - item 0 (item 1 puntos-marea)
  let Ci length mediciones-cuadrantes

  if Ci = 0
  [
    set Ci -1
  ]

  report (Ti * 1.25 * (Ai / Aci)) * (Hi / (1.08 * Ci) )

end

to-report contar-tortugas-transectos-berma

  let medicion-temporal-transecto-berma 0

  ask patches with [transecto-berma = 1]
  [
    set medicion-temporal-transecto-berma medicion-temporal-transecto-berma + count turtles-here with [fase < 4]
  ]

  report medicion-temporal-transecto-berma

end

to-report calcular-transectos-berma

  let A count patches with [vegetacion = 0]

  let H-mayus item posicion-final ( item 1 puntos-marea) - item 0 (item 1 puntos-marea)

  let w 1

  let l (count patches with [transecto-berma = 1]) / (2 * w)

  let n sum mediciones-transectos-berma

  let h-minus (((distancia-playa / 2) / velocidad-tortuga-subida) + duracion-cama + duracion-cavar + duracion-poner)

  let t length mediciones-transectos-berma

  ifelse t > 0
  [report ((A * H-mayus) / (2 * w * t * l)) * (n / h-minus)]
  [report 0]


end

to-report contar-tortugas-transecto-marea

  set-transecto-marea

  let medicion-temporal-transecto-marea 0

  ask patches with [transecto-marea = 1]
  [
    set medicion-temporal-transecto-marea medicion-temporal-transecto-marea + count turtles-here with [fase < 4]
  ]

  report medicion-temporal-transecto-marea

end

to-report calcular-transecto-marea

  let n sum mediciones-transecto-marea

  let H tiempo-medicion-transecto-marea

  let t length mediciones-transecto-marea

  ifelse t > 0
  [report (n * H) / (4.2 * t)]
  [report 0]

end

to resultados-finales

  output-print word "Estimacion cuadrantes: " calcular-cuadrantes
  output-print word "Estimacion transectos berma: " calcular-transectos-berma
  output-print word "Estimacion transectos marea: " calcular-transecto-marea
  output-print word "Tortugas generadas: " tortugas-generadas
  output-print word "Tortugas anidadas: " tortugas-anidadas

end

;;**********************
;; Funciones de patches:
;;**********************

to init-patch

  let sector floor (pxcor / (longitud-costa / sectores))

  let distancia-berma item 0 (item sector terreno)
  let altura-berma item 1 (item sector terreno)
  let distancia-vegetacion item 2 (item sector terreno)
  let altura-vegetacion item 3 (item sector terreno)

  ;let suavizado (p-suavizar-transicion sector distancia-berma altura-berma distancia-vegetacion altura-vegetacion)
  ;set distancia-berma item 0 suavizado
  ;set altura-berma item 1 suavizado
  ;set distancia-vegetacion item 2 suavizado
  ;set altura-vegetacion item 3 suavizado

  ifelse pycor > distancia-berma + distancia-vegetacion
  [
    set vegetacion 10 + random 10
  ]
  [
    set vegetacion 0
  ]

  ifelse pycor >= 0 and pycor < distancia-berma
  [
    set altura altura-berma / distancia-berma * pycor
  ]
  [
    set altura altura-berma + altura-vegetacion / distancia-vegetacion * pycor
  ]

  if pycor = floor distancia-berma
  [
    set berma lput self berma
  ]

  p-comportamiento-patch

end

to-report p-suavizar-transicion [sector distancia-berma altura-berma distancia-vegetacion altura-vegetacion]

  let sector-offset sector * longitud-sector

  if pxcor >= sector-offset and pxcor < sector-offset + (1 / 4 * longitud-sector)
  [

    let distancia-berma-previa distancia-berma
    let altura-berma-previa altura-berma
    let distancia-vegetacion-previa distancia-vegetacion
    let altura-vegetacion-previa altura-vegetacion

    if sector > 0
    [
      set distancia-berma-previa item 0 (item (sector - 1) terreno)
      set altura-berma-previa item 1 (item (sector - 1) terreno)
      set distancia-vegetacion-previa item 2 (item (sector - 1) terreno)
      set altura-vegetacion-previa item 3 (item (sector - 1) terreno)
    ]

    let variacion-distancia-berma-previa distancia-berma - ( distancia-berma + distancia-berma-previa ) / 2
    let variacion-altura-berma-previa altura-berma - ( altura-berma + altura-berma-previa ) / 2
    let variacion-distancia-vegetacion-previa distancia-vegetacion - ( distancia-vegetacion + distancia-vegetacion-previa ) / 2
    let variacion-altura-vegetacion-previa altura-vegetacion - ( altura-vegetacion + altura-vegetacion-previa ) / 2

    let cambio-longitud 1 - ( pxcor - sector-offset ) / (1 / 4 * longitud-sector)

    set distancia-berma distancia-berma - (variacion-distancia-berma-previa * cambio-longitud)
    set altura-berma altura-berma - (variacion-altura-berma-previa * cambio-longitud)
    set distancia-vegetacion distancia-vegetacion - (variacion-distancia-vegetacion-previa * cambio-longitud)
    set altura-vegetacion altura-vegetacion - (variacion-altura-vegetacion-previa * cambio-longitud)

  ]
  if pxcor >= sector-offset + (3 / 4 * longitud-sector) and pxcor < sector-offset +  longitud-sector
  [

    let distancia-berma-siguiente distancia-berma
    let altura-berma-siguiente altura-berma
    let distancia-vegetacion-siguiente distancia-vegetacion
    let altura-vegetacion-siguiente altura-vegetacion

    if sector < sectores - 1
    [
      set distancia-berma-siguiente item 0 (item (sector + 1) terreno)
      set altura-berma-siguiente item 1 (item (sector + 1) terreno)
      set distancia-vegetacion-siguiente item 2 (item (sector + 1) terreno)
      set altura-vegetacion-siguiente item 3 (item (sector + 1) terreno)
    ]

    let variacion-distancia-berma-siguiente distancia-berma - ( distancia-berma + distancia-berma-siguiente ) / 2
    let variacion-altura-berma-siguiente altura-berma - ( altura-berma + altura-berma-siguiente ) / 2
    let variacion-distancia-vegetacion-siguiente distancia-vegetacion - ( distancia-vegetacion + distancia-vegetacion-siguiente ) / 2
    let variacion-altura-vegetacion-siguiente altura-vegetacion - ( altura-vegetacion + altura-vegetacion-siguiente ) / 2

    let cambio-longitud (pxcor - (sector-offset + (3 / 4 * longitud-sector))) / (1 / 4 * longitud-sector)

    set distancia-berma distancia-berma - (variacion-distancia-berma-siguiente * cambio-longitud)
    set altura-berma altura-berma - (variacion-altura-berma-siguiente * cambio-longitud)
    set distancia-vegetacion distancia-vegetacion - (variacion-distancia-vegetacion-siguiente * cambio-longitud)
    set altura-vegetacion altura-vegetacion - (variacion-altura-vegetacion-siguiente * cambio-longitud)
  ]

  report (list distancia-berma altura-berma distancia-vegetacion altura-vegetacion)

end

to p-comportamiento-patch ;; Cambiar por nombre significativo de comportamiento de patch

  ifelse altura <= altura-de-marea
  [
    set pcolor scale-color blue altura -25 20
  ]
  [
    ifelse vegetacion = 0
    [
      set pcolor scale-color yellow altura -15 30
    ]
    [
      set pcolor scale-color green vegetacion 0 30
    ]
  ]

  if member? self berma
  [set pcolor brown]

  if cuadrante = 1
  [set pcolor 111]

  if transecto-berma = 1
  [set pcolor 115]

  if transecto-marea = 1
  [set pcolor 119]

end



;;**********************
;; Funciones de turtles:
;;**********************

to generar-tortugas
  let tortugas random-poisson tortugas-por-minuto
  crt tortugas
  [
    init-turtle
  ]
  set tortugas-generadas tortugas-generadas + tortugas
end

to init-turtle ;; Para inicializar una tortuga a la vez.

  set xcor random longitud-costa
  set ycor [pycor] of (min-one-of (patches with [altura > altura-de-marea and pxcor = [xcor] of myself]) [pycor])
  set velocidad-subida random-normal velocidad-tortuga-subida desviacion-velocidad-tortugas-subida
  set velocidad-bajada random-normal velocidad-tortuga-bajada desviacion-velocidad-tortugas-bajada
  let promedio-zona random (porcentaje-zona-intermarial-baja + porcentaje-zona-intermarial-alta + porcentaje-sobre-berma + porcentaje-cerca-vegetacion)
  let promedio-parada random 100
  let max-distancia [pycor] of (max-one-of (patches with [altura > altura-de-marea and pxcor = [xcor] of myself and vegetacion = 0]) [pycor])
  let distancia-berma [pycor] of (min-one-of ((patch-set berma) with [pxcor = [xcor] of myself]) [pycor])
  let altura-zona-intermarial ((distancia-berma - ycor) / 2) + ycor
  let altura-interzona-berma-vegetacion ((max-distancia - distancia-berma) / 2) + distancia-berma
  ifelse promedio-zona <= porcentaje-zona-intermarial-baja
  [
    set distancia-meta ((altura-zona-intermarial - ycor) * promedio-parada / 100) + ycor
  ]
  [
    ifelse promedio-zona <= porcentaje-zona-intermarial-baja + porcentaje-zona-intermarial-alta
    [
      set distancia-meta ((distancia-berma - altura-zona-intermarial) * promedio-parada / 100) + altura-zona-intermarial
    ]
    [
      ifelse promedio-zona <= porcentaje-zona-intermarial-baja + porcentaje-zona-intermarial-alta + porcentaje-sobre-berma
      [
        set distancia-meta ((altura-interzona-berma-vegetacion - distancia-berma) * promedio-parada / 100) + distancia-berma
      ]
      [
        set distancia-meta ((max-distancia - altura-interzona-berma-vegetacion) * promedio-parada / 100) + altura-interzona-berma-vegetacion
      ]
    ]
  ]
  set fase 0
  set heading 0
  set color scale-color green random 10 -10 20
  set shape "turtle"
end

to t-comportamiento-turtle ;; Se debería cambiar el nombre para que represente algo signficativo en la simulación.
  ifelse fase = 0
  [
    forward velocidad-subida
    if ycor >= distancia-meta
    [
      set ycor floor distancia-meta
      ifelse random 100 > probabilidad-fallo-subida
      [
        set fase 1
        set tiempo-de-fase ticks + (random-normal duracion-cama desviacion-duracion-cama)
        set color scale-color blue random 10 -10 20
      ][
        set fase 6
        set color scale-color green random 10 -10 20
        set heading 180
        set tortugas-no-anidadas tortugas-no-anidadas + 1
      ]
    ]
  ][
    ifelse fase = 1
    [
      if ticks >= tiempo-de-fase
      [
        ifelse random 100 > probabilidad-fallo-cama
        [
          set fase 2
          set tiempo-de-fase tiempo-de-fase + (random-normal duracion-cavar desviacion-duracion-cavar)
          set color scale-color orange random 10 -10 20
        ][
          set fase 6
          set color scale-color green random 10 -10 20
          set heading 180
          set tortugas-no-anidadas tortugas-no-anidadas + 1
        ]
      ]
    ][
      ifelse fase = 2
      [
        if ticks >= tiempo-de-fase
        [
          ifelse random 100 > probabilidad-fallo-cavar
          [
            set fase 3
            set tiempo-de-fase tiempo-de-fase + (random-normal duracion-poner desviacion-duracion-poner)
            set color scale-color violet random 10 -10 20
          ][
            set fase 6
            set color scale-color green random 10 -10 20
            set heading 180
            set tortugas-no-anidadas tortugas-no-anidadas + 1
          ]
        ]
      ][
        ifelse fase = 3
        [
          if ticks >= tiempo-de-fase
          [
            ifelse random 100 > probabilidad-fallo-poner
            [
              set fase 4
              set tiempo-de-fase tiempo-de-fase + (random-normal duracion-rellenar desviacion-duracion-rellenar)
              set color scale-color pink random 10 -10 20
            ][
              set fase 6
              set color scale-color green random 10 -10 20
              set heading 180
              set tortugas-no-anidadas tortugas-no-anidadas + 1
            ]
          ]
        ][
          ifelse fase = 4
          [
            if ticks >= tiempo-de-fase
            [
              ifelse random 100 > probabilidad-fallo-rellenar
              [
                set fase 5
                set tiempo-de-fase tiempo-de-fase + (random-normal duracion-camuflar desviacion-duracion-camuflar)
                set color scale-color turquoise random 10 -10 20
              ][
                set fase 6
                set color scale-color green random 10 -10 20
                set heading 180
                set tortugas-no-anidadas tortugas-no-anidadas + 1
              ]
            ]
          ][
            ifelse fase = 5
            [
              if ticks >= tiempo-de-fase
              [
                ifelse random 100 > probabilidad-fallo-camuflar
                [
                  set fase 6
                  set color scale-color green random 10 -10 20
                  set heading 180
                  set tortugas-anidadas tortugas-anidadas + 1
                ][
                  set fase 6
                  set color scale-color green random 10 -10 20
                  set heading 180
                  set tortugas-no-anidadas tortugas-no-anidadas + 1
                ]

              ]
            ][;; fase = 6
              forward velocidad-bajada
              if [altura] of patch-here < altura-de-marea
              [
                set tortugas-terminadas tortugas-terminadas + 1
                die
              ]
            ]
          ]
        ]
      ]
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
231
71
4086
536
-1
-1
4.81
1
10
1
1
1
0
1
1
1
0
799
0
94
1
1
1
ticks
30.0

BUTTON
13
10
119
58
Preparar
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
121
10
230
58
Correr
go\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
13
318
230
351
tortugas-por-minuto
tortugas-por-minuto
0
10
7.0
0.5
1
NIL
HORIZONTAL

SLIDER
13
414
230
447
velocidad-tortuga-bajada
velocidad-tortuga-bajada
0
20
15.1
0.1
1
NIL
HORIZONTAL

SLIDER
13
447
230
480
desviacion-velocidad-tortugas-bajada
desviacion-velocidad-tortugas-bajada
0
20
2.0
0.1
1
NIL
HORIZONTAL

TEXTBOX
14
60
164
78
Terreno
11
0.0
1

TEXTBOX
15
305
165
323
Tortugas
11
0.0
1

SLIDER
13
107
230
140
longitud-sector
longitud-sector
1
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
13
350
230
383
velocidad-tortuga-subida
velocidad-tortuga-subida
0
20
7.3
0.1
1
NIL
HORIZONTAL

SLIDER
13
382
230
415
desviacion-velocidad-tortugas-subida
desviacion-velocidad-tortugas-subida
0
20
1.0
0.1
1
NIL
HORIZONTAL

TEXTBOX
14
182
164
200
Mediciones
11
0.0
1

SLIDER
13
197
230
230
tiempo-medicion-cuadrantes
tiempo-medicion-cuadrantes
0
1440
120.0
1
1
NIL
HORIZONTAL

SLIDER
13
481
230
514
duracion-cama
duracion-cama
0
5
3.2
0.1
1
NIL
HORIZONTAL

SLIDER
13
515
230
548
desviacion-duracion-cama
desviacion-duracion-cama
0
5
2.1
0.1
1
NIL
HORIZONTAL

SLIDER
13
547
230
580
duracion-cavar
duracion-cavar
0
20
16.3
0.1
1
NIL
HORIZONTAL

SLIDER
13
579
230
612
desviacion-duracion-cavar
desviacion-duracion-cavar
0
5
0.7
0.1
1
NIL
HORIZONTAL

SLIDER
13
612
230
645
duracion-poner
duracion-poner
0
20
13.1
0.1
1
NIL
HORIZONTAL

SLIDER
13
645
230
678
desviacion-duracion-poner
desviacion-duracion-poner
0
5
2.3
0.1
1
NIL
HORIZONTAL

SLIDER
13
678
230
711
duracion-rellenar
duracion-rellenar
0
10
7.5
0.1
1
NIL
HORIZONTAL

SLIDER
13
711
230
744
desviacion-duracion-rellenar
desviacion-duracion-rellenar
0
5
1.3
0.1
1
NIL
HORIZONTAL

SLIDER
13
744
230
777
duracion-camuflar
duracion-camuflar
0
15
7.8
0.
1
NIL
HORIZONTAL

SLIDER
13
776
230
809
desviacion-duracion-camuflar
desviacion-duracion-camuflar
0
5
2.2
0.1
1
NIL
HORIZONTAL

MONITOR
232
10
381
59
Tortugas Generadas
tortugas-generadas
1
1
12

MONITOR
382
10
532
59
Tortugas Anidadas
tortugas-anidadas
1
1
12

MONITOR
533
10
683
59
Tortugas No Anidadas
tortugas-no-anidadas
1
1
12

MONITOR
684
10
834
59
Tortugas Terminadas
tortugas-terminadas
1
1
12

SLIDER
230
569
434
602
probabilidad-fallo-cama
probabilidad-fallo-cama
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
230
537
434
570
probabilidad-fallo-subida
probabilidad-fallo-subida
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
229
602
434
635
probabilidad-fallo-cavar
probabilidad-fallo-cavar
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
230
635
434
668
probabilidad-fallo-poner
probabilidad-fallo-poner
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
230
668
434
701
probabilidad-fallo-rellenar
probabilidad-fallo-rellenar
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
230
701
434
734
probabilidad-fallo-camuflar
probabilidad-fallo-camuflar
0
100
0.0
1
1
NIL
HORIZONTAL

MONITOR
986
10
1138
59
Altura de Marea
altura-de-marea
4
1
12

MONITOR
835
10
985
59
Tortugas en la Playa
count turtles
2
1
12

SLIDER
433
537
652
570
porcentaje-zona-intermarial-baja
porcentaje-zona-intermarial-baja
0
100
2.0
1
1
NIL
HORIZONTAL

SLIDER
434
570
652
603
porcentaje-zona-intermarial-alta
porcentaje-zona-intermarial-alta
0
100
43.0
1
1
NIL
HORIZONTAL

SLIDER
434
603
652
636
porcentaje-sobre-berma
porcentaje-sobre-berma
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
434
636
652
669
porcentaje-cerca-vegetacion
porcentaje-cerca-vegetacion
0
100
5.0
1
1
NIL
HORIZONTAL

SLIDER
13
230
230
263
tiempo-medicion-transectos-berma
tiempo-medicion-transectos-berma
0
1440
120.0
1
1
NIL
HORIZONTAL

SLIDER
13
263
230
296
tiempo-medicion-transecto-marea
tiempo-medicion-transecto-marea
0
1440
20.0
1
1
NIL
HORIZONTAL

OUTPUT
1140
10
1380
64
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="32" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>calcular-cuadrantes</metric>
    <metric>calcular-transectos-berma</metric>
    <metric>calcular-transecto-marea</metric>
    <metric>mediciones-cuadrantes</metric>
    <metric>mediciones-transectos-berma</metric>
    <metric>mediciones-transecto-marea</metric>
    <metric>tortugas-generadas</metric>
    <metric>tortugas-anidadas</metric>
    <metric>tortugas-no-anidadas</metric>
    <metric>tortugas-terminadas</metric>
    <enumeratedValueSet variable="desviacion-velocidad-tortugas-bajada">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duracion-cavar">
      <value value="16.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tiempo-medicion-transectos-berma">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="porcentaje-cerca-vegetacion">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probabilidad-fallo-poner">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desviacion-duracion-cavar">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desviacion-duracion-rellenar">
      <value value="1.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probabilidad-fallo-rellenar">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duracion-rellenar">
      <value value="7.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desviacion-duracion-poner">
      <value value="2.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tiempo-medicion-transecto-marea">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="velocidad-tortuga-subida">
      <value value="7.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probabilidad-fallo-camuflar">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duracion-cama">
      <value value="3.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duracion-camuflar">
      <value value="7.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="porcentaje-sobre-berma">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desviacion-duracion-cama">
      <value value="2.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probabilidad-fallo-subida">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="velocidad-tortuga-bajada">
      <value value="15.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="longitud-sector">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desviacion-velocidad-tortugas-subida">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duracion-poner">
      <value value="13.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tortugas-por-minuto">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probabilidad-fallo-cama">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desviacion-duracion-camuflar">
      <value value="2.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="porcentaje-zona-intermarial-alta">
      <value value="43"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="porcentaje-zona-intermarial-baja">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tiempo-medicion-cuadrantes">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probabilidad-fallo-cavar">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
