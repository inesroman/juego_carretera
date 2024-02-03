# Juego de Carretera
Este juego en ARM ha sido desarrolado en el entorno Keil uVision5

## Normas del juego
Conducir un coche por una carretera como la de la figura anterior. Los límites de la carretera se 
marcan con caracteres  ‘#’ (ASCII 35). Inicialmente la carretera es recta (columnas 8 y 16 de toda la 
pantalla) y se desplaza de arriba a abajo. Ritmo inicial de movimiento, 1 fila cada 0,08 segundos según el 
reloj de simulación. El coche (carácter ‘H’, ASCII 72) está inicialmente en el centro de la última fila de la 
pantalla y lo mueve el usuario por toda la pantalla con las teclas:
- ‘J’ (ASCII 74 ó 106) izquierda
-  ‘L’ (ASCII 76 ó 108) derecha
- ‘I’ (ASCII 73 ó 105)  arriba 
- ‘K’ (ASCII 75 ó 107) abajo

Si el coche rebasa los límites de la carretera, la partida termina. Una vez iniciada la partida, el juego decidirá de manera aleatoria los cambios de dirección (izquierda, derecha o continuar recto) de la carretera.

## Opciones
- ‘Q’ (ASCII 81 ó 113) para finalizar el programa
- ‘+’ (ASCII 43) para duplicar la velocidad de movimiento (máximo 1 movimiento cada 0,01 segundos)
- ‘‐‘ (ASCII 45) para dividir por dos la velocidad de movimiento (mínimo 1 movimiento cada 1,28 segundos). 