#Introducir una letra, tal que si es A, realizaremos el área de una circunferencia y si es L, realizaremos la longitud de 
#la circunferencia. Sea cualquiera de las opciones elegidas, visualizar el resultado indicando si se trata del área o de la longitud.
import math
letra = input("Introduce A para el area de una circurferencia y L para la longitud de la circunfernecia ").lower()
radio=float (input("Dame el radio de la circunferencia "))
if letra == "a":
    area = math.pi * radio**2
    print (f"El area de la circurfenrencia es {area:.2f}")
elif letra == "l":
    longitud = 2 * math.pi * radio 
    print (f"La longitud de la circurferencia es {longitud:.2f}")
else: 
    print ("Opcion inconrrecta")