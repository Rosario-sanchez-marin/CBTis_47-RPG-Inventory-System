

| Campo | Tipo de dato | Descripción | Restricciones |
|-------|--------------|-------------|---------------|
| nombre | Texto | Nombre del ítem | Máx. 50 caracteres |
| tipo | Texto | Categoría del ítem (espada, poción, mapa) | Valores permitidos: espada/poción/mapa |
| daño | Número | Daño que causa la espada | Solo aplica si tipo = espada |
| durabilidad | Número | Cuánto aguanta la espada | Rango 0–100 |
| efecto | Texto | Qué hace la poción | Solo aplica si tipo = poción |
| duración | Número | Tiempo que dura el efecto | En segundos |
| coordenadas | Array de números | Posición en el mapa | Solo aplica si tipo = mapa |
