#Introducir una nota entera y visualizar si está aprobada o suspensa.
n = int (input("Dame un numero entero: "))
if n == 0:
    print ("El numero es nulo")
elif n < 0:
    print ("El numero es negativo")
else:
    print ("El numero es positivo")